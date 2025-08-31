# Author: Timothy Kornish
# CreatedDate: 8/30/2025
# Description: set up s3 bucket to interact with emr clusters.
               The bucket will have a folder structure as follows:
              - monthly_build
                - 2023_09
                  - input
                  - output
                  - logs
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

# set versioning for s3 bucket
resource "aws_s3_bucket_versioning" "emr_bucket_versioning" {
  bucket = aws_s3_bucket.emr_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# create an encryption key for server side encryption
resource "aws_kms_key" "emr_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

# create server side encryption for the s3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "emr_bucket_encryption" {
  bucket = aws_s3_bucket.emr_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.emr_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# create a parent folder in the s3 bucket called monthly_build
resource "aws_s3_object" "emr_bucket_folder_monthly_build" {
    bucket     = aws_s3_bucket.emr_bucket.id
    key        = "monthly_build/"
    kms_key_id = aws_kms_key.emr_bucket_key.arn
}

# create a subfolder: 2023_09
resource "aws_s3_object" "emr_bucket_folder_2023_09" {
    bucket     = aws_s3_bucket.emr_bucket.id
    key        = "monthly_build/2023-09/"
    kms_key_id = aws_kms_key.emr_bucket_key.arn
}

# create a subfolder: input
resource "aws_s3_object" "emr_bucket_folder_2023_09_input" {
    bucket     = aws_s3_bucket.emr_bucket.id
    key        = "monthly_build/2023-09/input/"
    kms_key_id = aws_kms_key.emr_bucket_key.arn
}

# create a subfolder: output
resource "aws_s3_object" "emr_bucket_folder_2023_09_output" {
    bucket     = aws_s3_bucket.emr_bucket.id
    key        = "monthly_build/2023-09/output/"
    kms_key_id = aws_kms_key.emr_bucket_key.arn
}

# create a subfolder: logs
resource "aws_s3_object" "emr_bucket_folder_2023_09_logs" {
    bucket     = aws_s3_bucket.emr_bucket.id
    key        = "monthly_build/2023-09/logs/"
    kms_key_id = aws_kms_key.emr_bucket_key.arn
}
