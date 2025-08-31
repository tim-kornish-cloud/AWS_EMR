# Author: Timothy Kornish
# CreatedDate: 8/30/2025
# Description: set up s3 bucket to interact with emr clusters
# follows youtube tutorial: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11

# create random name generator resource to set the s3 bucket names using random_pet
resource "random_pet" "emr_bucket_name" {
  prefix = "test"
  length = 2
}

# create s3 bucket, and set name using random_pet
resource "aws_s3_bucket" "emr_bucket" {
  bucket   = random_pet.emr_bucket_name.id
  force_destroy = true # add force destroy since name is going to be using a random name generator and may be difficult to find manually
}
