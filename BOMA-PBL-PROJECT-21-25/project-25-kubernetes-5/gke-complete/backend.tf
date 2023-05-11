terraform {
  backend "gcs" {
    bucket  = "boma-gke-state-bucket"
    prefix  = "terraform/state"
    lock = "false"
  }
}
