# Configure the GCS backend to store the Terraform state file
terraform {
  backend "gcs" {
    bucket = "asnv-terraform-state-bucket"  
    prefix = "terraform/state"              
  }
}

provider "google" {
  project = "diesel-patrol-450717-f2"
  region  = "us-central1"
}

# Step to Grant the existing service account permission to view objects in Cloud Storage
resource "google_project_iam_binding" "storage_viewer" {
  project = "diesel-patrol-450717-f2"
  role    = "roles/storage.objectViewer"

  members = [
    "serviceAccount:terraform-deployer@diesel-patrol-450717-f2.iam.gserviceaccount.com"
  ]
}

# Step to Define a firewall rule to allow SSH access from ALL IPs
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  
  target_tags = ["secure-vm"]
}

# Step to Deploy a Compute Engine virtual machine
resource "google_compute_instance" "vm_instance" {
  name         = "secure-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  # Define the boot disk with a standard persistent disk
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10  # Size in GB
      type  = "pd-standard"
    }
  }

  # Attach the existing service account
  service_account {
    email  = "terraform-deployer@diesel-patrol-450717-f2.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # Configure the network interface with a public IP
  network_interface {
    network = "default"

    access_config { }
  }

  # Enable Shielded VM security features for enhanced protection
  shielded_instance_config {
    enable_secure_boot          = true  # Prevents unauthorized boot modifications
    enable_vtpm                 = true  # Helps with cryptographic security
    enable_integrity_monitoring = true  # Monitors system integrity
  }

  # Assign tags for easy identification and firewall rules
  tags = ["secure-vm", "terraform-managed"]
}
