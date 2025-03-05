variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
  default = "value" # update from lab
}

variable "region" {
  description = "The Google Cloud region to deploy resources to"
  type        = string
  default     = "value" #update from lab
}

variable "zone" {
  description = "The Google Cloud zone to deploy resources to"
  type        = string
  default     = "value" #update from lab
}

variable "bucket_name" {
  description = "The name of the GCS bucket for Terraform state"
  type        = string
  default     = "value" # update from lab
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "value"
}

variable "google_compute_global_forwarding_rule" {
    description = "Name of the frontend forwarding rule"
    type = string
    default = "value" #update from lab
  
}

variable "google_compute_backend_service" {
    description = "Name of the backend service"
    type = string
    default = "value" # update from lab
  
}

variable "google_compute_region_instance_group_manager" {
    description = "Name of the managed instance group template"
    type = string
    default = "value" #update from lab
  
}

variable "google_compute_subnetwork" {
    description = "Name of the subnet"
    type = string
    default = "value" #update with the right region from lab
  
}