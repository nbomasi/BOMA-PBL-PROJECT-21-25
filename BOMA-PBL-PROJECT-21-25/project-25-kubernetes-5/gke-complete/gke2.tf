resource "google_container_cluster" "primary" {
  name     = "boma-gke-cluster"
  location = "us-central1"
  remove_default_node_pool = true
  initial_node_count       = 1
  network = google_compute_network.main.self_link
  subnetwork = google_compute_subnetwork.private-subnet.self_link
  networking_mode = "VPC_NATIVE"
  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  
  addons_config {
  http_load_balancing {
     disabled = false 
  }
  }
  # horizontal_pod_autoscaling {
  #   disabled = false
  # }
  release_channel {
    channel = "REGULAR"
  }
  workload_identity_config {
    workload_pool = "useful-song-384921.svc.id.goog"
  }
  ip_allocation_policy {
    cluster_secondary_range_name = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"

#   Jenkins use case
#   master_authorized_networks_config {
#     cidr_blocks {
#         cidr_block = "10.0.0.0/18"
#         display_name = private_sunet-jenkins
#     }
#   }

  }
# If you want additional zone
  node_locations = [
    "us-central1-b"
  ]
}


# WORKERS NODE
resource "google_service_account" "kubernetes" {
    account_id = "kubernetes"
}
resource "google_container_node_pool" "general" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  management {
    auto_repair = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "e2-standard-4"
    labels = {
      role = "general"
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.kubernetes.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "spot" {
    name = "spot"
    cluster = google_container_cluster.primary.id

    management {
    auto_repair = true
    auto_upgrade = true
  }

   autoscaling {
     min_node_count = 1
     max_node_count = 10
   }
  
  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"
    labels = {
      team = "devops"
    }

    # taint = {
    #     key = "instance_type"
    #     value = "spot"
    #     effect = "NO_SCHEDULE"
    # }
    service_account = google_service_account.kubernetes.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

}