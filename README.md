This repo is following the youtube tutorial "Intro to Amazon EMR - Big Data Tutorial using Spark" at: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11

1) follow the tutorial performing a manual set up and tear down.
2) translate the steps from the tutorial into terraform infrastructure files.


# Manual steps

1) set up file system in s3 bucket
 - bucket_name = timothy-emr-tutorial
 - use random_pet to name the buckets
 - enable bucket versioning: use aws_s3_bucket_versioning
 - create encryption key to use in server side encryption
 - create a folder in the s3 bucket, specify encryption key
   - create a subfolder for each month, example: 2023_09
     - create 3 subfolders: input, output, logs 

2) create VPC

3) Configure EMR cluster
