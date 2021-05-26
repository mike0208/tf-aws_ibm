terraform {
  required_version = "v0.15.1"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}