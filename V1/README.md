This repo is following the youtube tutorial "Intro to Amazon EMR - Big Data Tutorial using Spark" at: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11

1) follow the tutorial performing a manual set up and tear down on the AWS online console.
2) translate the steps from the tutorial into terraform infrastructure files.


# Terraform configuration steps

1) set up file system in s3 bucket
 - bucket_name = timothy-emr-tutorial
 - use random_pet to name the buckets
 - enable bucket versioning: use aws_s3_bucket_versioning
 - create encryption key to use in server side encryption
 - create a folder in the s3 bucket, specify encryption key
   - create a subfolder for each month, example: 2023_09
     - create 3 subfolders: input, output, logs

2) create VPC
 - Create the following resources:
  - aws_vpc
  - aws_subnet
  - aws_internet_gateway
  - aws_route_table
  - aws_route_table_association
  - aws_vpc_endpoint

3) Configure EMR cluster

Error: waiting for EMR Cluster (j-1V09NHUGXBILT) create: unexpected state 'TERMINATED_WITH_ERRORS', wanted target 'RUNNING, WAITING'. last error: VALIDATION_ERROR: You must also specify a ServiceAccessSecurityGroup if you use custom security groups when creating a cluster in a private subnet.
│
│   with aws_emr_cluster.emr_spark_cluster["us-east-1a"],
│   on emr_cluster.tf line 63, in resource "aws_emr_cluster" "emr_spark_cluster":
│   63: resource "aws_emr_cluster" "emr_spark_cluster" {

4) Organize file structure values into:
  - data.tf
  - variables.tf
  - outputs.tf
