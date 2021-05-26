# ------- terraform-demo-project 
# --------  ROOT
# -------- root/providers.tf

module "aws"{
    source = "./aws"
    
}



module "ibm"{
    source = "./ibm"
    ibmcloud_api_key = var.ibmcloud_api_key
    ssh_key_path = "${path.cwd}/ssh/vsikey.pub" 
    depends_on= [module.aws]
}