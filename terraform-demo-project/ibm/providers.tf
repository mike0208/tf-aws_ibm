# ------- terraform-demo-project 
# --------  IBM 
# -------- root/providers.tf

terraform {
  required_version = "v0.15.1"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

/*provider "ibm" {    
  ibmcloud_api_key = var.ibmcloud_api_key
}*/
# Error: Module module.ibm contains provider configuration. Providers cannot be configured within modules using count, for_each or depends_on.