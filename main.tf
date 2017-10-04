##############################################################################
# Require terraform 0.9.3 or greater
##############################################################################
terraform {
  required_version = ">= 0.9.3"
}
##############################################################################
# IBM Cloud Provider
##############################################################################
# See the README for details on ways to supply these values
# Configure the IBM Cloud Provider
provider "ibm" {
  bluemix_api_key    = "${var.ibm_bmx_api_key}"
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}

# Create an SSH key. The SSH key surfaces in the SoftLayer console under Devices > Manage > SSH Keys.
resource "ibm_compute_ssh_key" "ssh_compute_key" {
  label      = "skey_${var.ibm_sl_username}"
  notes      = "skey ${var.ibm_sl_username}"
  public_key = "${var.ssh_public_key}"
}

# Create bare metal servers with the SSH key.
resource "ibm_compute_bare_metal" "masters" {
  hostname          = "master${count.index}"
  domain            = "domain.com"
  ssh_key_ids       = ["${ibm_compute_ssh_key.ssh_compute_key.id}"]
  os_reference_code = "UBUNTU_16_64"
  fixed_config_preset = "S1270_32GB_2X960GBSSD_NORAID"
  datacenter        = "tor01"
  hourly_billing    = true
  network_speed     = 100
  count             = 1
  user_metadata = "#!/bin/bash\n\ndeclare -i numbercomputes=1\nuseintranet=false\ndomain=domain.com\necho test > /root/metadata\n"
  private_network_only        = false
}

##############################################################################
# Variables
##############################################################################
variable ibm_bmx_api_key {
  description = "Your Bluemix API Key."
}
variable ibm_sl_username {
  description = "Your Softlayer username."
}
variable ibm_sl_api_key {
  description = "Your Softlayer API Key."
}
variable ssh_public_key {
  description = "Your public SSH key to access your cluster hosts."
}

##############################################################################
# Outputs
##############################################################################
output "cluster_master_ip" {
  value = "${element(compact(ibm_compute_bare_metal.masters.*.public_ipv4_address),0)}"
}
