terraform {
  backend "gcs" {
    bucket = "value" # Use your bucket name here
    # prefix = "terraform/state" # Optional: Organize states in a prefix
  }
}
