# Author: Timothy Kornish
# CreatedDate: 8/31/2025
# Description: set up an Elastic Map Reduce cluster in spark
# follows youtube tutorial: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11

# set location of the cluster
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "emr_service_role" {
  name = "EMR_Service_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "emr_service_role_policy" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_instance_profile" "emr_ec2_instance_profile" {
  name = "EMR_EC2_Instance_Profile"
  role = aws_iam_role.emr_ec2_role.name
}

resource "aws_iam_role" "emr_ec2_role" {
  name = "EMR_EC2_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "emr_ec2_role_policy" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
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
  for_each          = toset(data.aws_availability_zones.emr_vpc_available.names)

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
}

resource "aws_security_group" "emr_cluster_access" {
  name        = "emr_cluster_access"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.emr_vpc.id

  #ingress {
  #  from_port       = 9443
  #  to_port         = 9443
  #  protocol        = "tcp"
  #  # This rule is specific to the EMR service's managed prefix list.
  #  # The actual IP ranges are maintained by AWS.
  #  prefix_list_ids = [aws_vpc_endpoint.emr_vpc_s3_gateway_endpoint.prefix_list_id] # Replace with the EMR service prefix list ID for your region
  #}

  ingress {
    from_port   = 22 # SSH access
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your specific IP or CIDR range in production
  }

  ingress {
    from_port   = 8443 # EMR console (if needed)
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your specific IP or CIDR range in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_subnet.emr_public_subnet]

  lifecycle {
    ignore_changes = [
      ingress,
      egress,
    ]
  }

  tags = {
    name = "emr_cluster_access"
  }
}

#resource "aws_security_group" "emr_cluster_service_access" {
#  name        = "emr_cluster_service_access"
#  description = "Allow inbound traffic"
#  vpc_id      = aws_vpc.emr_vpc.id
#
#  #ingress {
#  protocol        = "tcp"
#  #  # This rule is specific to the EMR service's managed prefix list.
#  #  # The actual IP ranges are maintained by AWS.
#  #  prefix_list_ids = [aws_vpc_endpoint.emr_vpc_s3_gateway_endpoint.prefix_list_id] # Replace with the EMR service prefix list ID for your region
#  #}
#  ingress {
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  depends_on = [aws_subnet.emr_public_subnet]
#
#  lifecycle {
#    ignore_changes = [
#      ingress,
#    ]
#}
#
#  tags = {
#    name = "emr_cluster_service_access"
#  }
#}
