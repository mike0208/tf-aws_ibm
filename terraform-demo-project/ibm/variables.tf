# ---------- IBM ---------
# ----------root/variables.tf ----------------

variable "ibmcloud_api_key" {}

variable "zone" {
  default = "us-south-1"
}

/*locals {
  ssh_key = file("../ssh/vsikey.pub")
}*/

variable "ssh_key_path"{}