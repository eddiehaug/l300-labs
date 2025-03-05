terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.24.0" # Keeping version as is for consistency, consider updating to "~> 4.60" or latest "~> 5.0" later
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  disable_on_destroy = false # Keep the API enabled when Terraform destroys resources
}

resource "google_sql_database_instance" "cepf_instance" {
  name             = var.instance_name
  region           = var.region
  database_version = "POSTGRES_14"
  root_password    = "postgres" # Consider using secrets management in production

  settings {
    tier = "db-f1-micro" # Minimum tier for testing; adjust for production
    # ip_configuration block removed - public IP enabled by default
  }
  # depends_on block related to service networking removed
}

resource "google_sql_database" "cepf_db" {
  name     = "cepf-db"
  instance = google_sql_database_instance.cepf_instance.name
}

resource "google_compute_network" "vpc_network" {
  name                    = "cepf-vpc-network"
  auto_create_subnetworks = false # We will define subnet manually
}

resource "google_compute_subnetwork" "subnetworks" {
  name          = var.google_compute_subnetwork
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_router" "nat_router" {
  name    = "cepf-nat-router"
  region  = var.region
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat_config" {
  name   = "cepf-nat-config"
  router = google_compute_router.nat_router.name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY" # Automatically allocate NAT IPs
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES" # NAT for all subnetworks in the region # Changed to ALL_SUBNETWORKS_IN_REGION
}

data "google_project" "project" {}

  resource "google_compute_instance_template" "default" {
      name_prefix  = "cepf-instance-template-"
      region       = var.region
      machine_type = "e2-medium"
      project      = data.google_project.project.project_id

      disk {
        source_image = "debian-cloud/debian-11"
      }

      network_interface {
        subnetwork = google_compute_subnetwork.subnetworks.self_link
        network_ip = null
        access_config {}
      }

      lifecycle {
        create_before_destroy = true
      }

      scheduling {
        automatic_restart   = true
        on_host_maintenance = "MIGRATE"
      }

      metadata = { # Add the metadata block
  startup-script = <<EOF
#!/bin/bash
gsutil cp -r gs://cloud-training/cepf/cepf020/flask_cloudsql_example_v1.zip .
apt-get install zip unzip wget python3-venv -y
unzip flask_cloudsql_example_v1.zip
cd flask_cloudsql_example/sqlalchemy
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy
export INSTANCE_HOST='127.0.0.1'
export DB_PORT='5432'
export DB_USER='postgres'
export DB_PASS='postgres'
export DB_NAME='cepf-db'
CONNECTION_NAME=$(gcloud sql instances describe cepf-instance --format="value(connectionName)")
nohup ./cloud_sql_proxy -instances=$${CONNECTION_NAME}=tcp:5432 &
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
sed -i 's/127.0.0.1/0.0.0.0/g' app.py
sed -i 's/8080/80/g' app.py
nohup python app.py &
EOF
      }
      service_account { # Add service_account block
        email  = "default" # Use default Compute Engine service account
        scopes = ["cloud-platform"] # Grant cloud-platform scope, which includes cloudsql.client
      }
      tags = ["http-server"] # Added tag 'http-server' to instances
    }

resource "google_compute_region_autoscaler" "default" {
  name   = "cepf-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.default.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 4
    cpu_utilization {
      predictive_method = "NONE"
      target            = 0.6 # 60% CPU utilization threshold
    }
  }
}

resource "google_compute_region_instance_group_manager" "default" {
  name                    = var.google_compute_region_instance_group_manager # Updated MIG name
  region                  = var.region # Correct region from variable (now us-central1)
  base_instance_name      = "cepf-instance"
  distribution_policy_zones = ["${var.region}-a", "${var.region}-b", "${var.region}-c"] # Zones in us-central1

  version {
    name                = "primary"
    instance_template   = google_compute_instance_template.default.self_link
  }

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_global_address" "default" {
  name = "cepf-infra-lb-ip"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "cepf-infra-lb-proxy"
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name            = "cepf-infra-lb-url-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_backend_service" "default" {
  name                  = var.google_compute_backend_service # Backend Name as instructed
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  session_affinity      = "GENERATED_COOKIE" # Backend Session Affinity as instructed
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_instance_group_manager.default.instance_group # Pointing to the correct MIG resource
  }

  health_checks = [google_compute_health_check.http_health_check.id]
}

resource "google_compute_health_check" "http_health_check" {
  name               = "cepf-infra-lb-hc"
  http_health_check {
    port               = 80
    request_path       = "/"  # Basic health check on root path
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = var.google_compute_global_forwarding_rule # Frontend forwarding rule name as instructed
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.default.address
}

resource "google_compute_firewall" "health_check_firewall" {
  name    = "allow-lb-health-checks"
  network = google_compute_network.vpc_network.name # Apply to your VPC network
  priority = 1000 # Set a priority (lower number = higher priority)
  direction = "INGRESS" # Ingress rule (inbound)
  allow {
    protocol = "tcp"
    ports    = ["80"] # Allow traffic on port 80 (health check port)
  }
  source_ranges = [
    "130.211.0.0/22", # Google Cloud health check probes IP range
    "35.191.0.0/16",  # Google Cloud health check probes IP range
  ]
  target_tags = ["http-server"] # Apply to instances with the 'http-server' tag (we'll add this tag to instance template next)
}