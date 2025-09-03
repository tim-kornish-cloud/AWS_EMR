# Author: Timothy Kornish
# CreatedDate: 9/2/2025
# Description: reconfigure emr files into a module format

provider "aws" {
  region = var.region
}

module "iam" {
  source = "./modules/iam"
}

module "security" {
  source              = "./modules/security"
}

module "emr" {
  source                    = "./modules/emr"
}
