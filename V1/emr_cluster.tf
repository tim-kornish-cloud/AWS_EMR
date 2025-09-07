# Author: Timothy Kornish
# CreatedDate: 8/31/2025
# Description: set up an Elastic Map Reduce cluster in spark
# follows youtube tutorial: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11

# set location of the cluster
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_instance_profile" "emr_ec2_instance_profile" {
  name = "EMR_EC2_Instance_Profile"
  role = aws_iam_role.emr_ec2_role.name
}

resource "aws_key_pair" "emr_cluster_key" {
  key_name   = "my-emr-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0NKfsDJiVq9NUEA2xt7N+JYRVtoOC3CNdV88tig0+dtYW5fEwbmq69SMf1tgYkB6uilkA41Gc0q7FNZ7nGOkrK+wlrkHRgmHNUK1epfCZ5GkCr7rXsdsk8at49q0JFDIK4g5Cg6vJdU5syfPKBzIV3ais3EjvK/P7/5NmBWJyrVqBelXU0dcVhnuEiKeNW0EAWImVCPY1B1uEAFmq2sdu7L5IWu7LL/NEkMzskmO5Gbmv0JDdWeVRDfCtx3UYpYFXfuzzdj6+O/i26jFY7dChyk6S3ZIHVxmb6sc9FVXkjCR0XDNUaxRgLHGq4J/XDsvfDA7/K9yAGiYZZCg1MvD5"
}

resource "aws_emr_cluster" "emr_spark_cluster" {
  name          = "my-spark-emr-cluster"
  release_label = "emr-7.10.0"
  applications  = ["Spark"]
  termination_protection = false

  master_instance_group {
   instance_count = 1
   instance_type  = "m5.xlarge"
 }

 core_instance_group {
   instance_count = 1
   instance_type  = "m5.xlarge"
 }

  # for each loop to create a subnet for each area in region
  #for_each          = toset(data.aws_availability_zones.emr_vpc_available.names)
  for_each          = toset(["us-east-1a", "us-east-1b"])

  ec2_attributes {
    instance_profile                  = aws_iam_instance_profile.emr_ec2_instance_profile.name
    emr_managed_master_security_group = aws_security_group.emr_cluster_access.id
    emr_managed_slave_security_group  = aws_security_group.emr_cluster_access.id
    subnet_id                         = aws_subnet.emr_public_subnet[each.key].id
    key_name                          = aws_key_pair.emr_cluster_key.key_name
    #service_access_security_group     = aws_security_group.emr_cluster_service_access.id
  }

  auto_termination_policy {
    idle_timeout = 3600 # Example: 1 hour (3600 seconds)
  }

  service_role = aws_iam_role.emr_service_role.arn

  log_uri = "s3://${aws_s3_bucket.emr_bucket.id}/monthly_build/2023-09/logs/" # If you have an S3 bucket for logs

  #first step to move python script to the master node
  step {
    name              = "Copy Python Script from S3"
    action_on_failure = "CONTINUE" # Or "TERMINATE_CLUSTER" based on your needs
    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = ["aws", "s3", "cp", "s3://${aws_s3_bucket.emr_bucket.id}/monthly_build/2023-09/main.py", "/home/hadoop/your_script.py"]
    }
  }
  #second step execute the script on a slave node commanded by master node.
  step {
    name              = "Execute Python Script"
    action_on_failure = "CONTINUE" # Or "TERMINATE_CLUSTER"
    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = ["python","/home/hadoop/main.py", "Food_Establishment_Inspection_Data_20250906.csv", "--output_s3_uri", "s3://${aws_s3_bucket.emr_bucket.id}/monthly_build/2023-09/output"]
    }
  }
}


