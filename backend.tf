terraform {
  backend "gcs" {
    bucket = "qwiklabs-gcp-03-0c5b138c6d2f-bucket-tfstate" # Use your bucket name here
    # prefix = "terraform/state" # Optional: Organize states in a prefix
  }
}