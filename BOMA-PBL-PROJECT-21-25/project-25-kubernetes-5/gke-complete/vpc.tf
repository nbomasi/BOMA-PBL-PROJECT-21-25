# resource "google_project_service" "compute" {
#   service = "compute.google.com"
# }
# resource "google_project_service" "container" {
#   service = "compute.google.com"
# }

resource "google_compute_network" "main" {
  name = "main"
  routing_mode = "REGIONAL"
  auto_create_subnetworks = false
  mtu = 1460
  delete_default_routes_on_create = false

  # depends_on = [
  #   google_project_service.compute,
  #   google_project_service.container
  # ]
}

## SUBNETWORKS
resource "google_compute_subnetwork" "private-subnet" {
  name          = "test-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.main.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.52.0.0/16"
}
}
## CLOUD ROUTER
resource "google_compute_router" "k8s-router" {
  name    = "k8s-router"
  region = "us-central1"
  network = google_compute_network.main.name
}

resource "google_compute_address" "nat-address" {
  name = "nat-address"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM" 
}

 # depends_on = [google_project_service.compute]
## CLOUD NAT
resource "google_compute_router_nat" "nat" {
  name   = "nat"
  router = google_compute_router.k8s-router.name
  region = google_compute_router.k8s-router.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat-address.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.private-subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# resource "google_compute_address" "nat-address" {
# name = "nat-address"
# address_type = "EXTERNAL"
# network_tier = "PREMIUM" 
# }

## FIREWAAL RULE, BUT NOT NECESSARY
resource "google_compute_firewall" "allow-ssh" {
    name = "allow-ssh"
    network = google_compute_network.main.name
    
    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_subnetwork" "proxy_only_subnet" {
  #provider      = "google-beta"
  name          = "boma-proxy"
  description   = "To be used for internal LB"
  network       = google_compute_network.main.self_link
  region        = "us-central1"
  ip_cidr_range = "10.10.0.0/16"
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER" # required for proxy-only subnets - see https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
  role          = "ACTIVE"                       # used when purpose = INTERNAL_HTTPS_LOAD_BALANCER - see https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
