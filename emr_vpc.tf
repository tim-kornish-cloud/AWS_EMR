# Author: Timothy Kornish
# CreatedDate: 8/31/2025
# Description: set up a VPC with the following:
#                 - aws_vpc
#                 - aws_availability_zones
#                 - aws_subnet
#                 - aws_internet_gateway
#                 - aws_route_table
#                 - aws_route_table_association
#                 - aws_vpc_endpoint
# follows youtube tutorial: https://www.youtube.com/watch?v=8bOgOvz6Tcg&list=PLkbxKqEYgUFSDTNZ0LoTLWfPNBd7D3-iZ&index=11

# create aws vpc resource
resource "aws_vpc" "emr_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "emr-vpc"
  }
}

# create a data list of availability zones
data "aws_availability_zones" "emr_vpc_available" {
  state = "available"
}

# create a data variable to retreive the current region
data "aws_region" "current" {}

# output the current region to console
output "current_aws_region" {
  description = "The name of the current AWS region."
  value       = data.aws_region.current.region
}

# create a public subnet
resource "aws_subnet" "emr_public_subnet" {
  # for each loop to create a subnet for each area in region
  for_each          = toset(data.aws_availability_zones.emr_vpc_available.names)
  vpc_id            = aws_vpc.emr_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.emr_vpc.cidr_block, 8, index(data.aws_availability_zones.emr_vpc_available.names, each.value))
  availability_zone = each.value
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${each.key}"
    "for-use-with-amazon-emr-managed-policies" = "true"
  }
}

# create internet gateway
resource "aws_internet_gateway" "emr_igw" {
  vpc_id = aws_vpc.emr_vpc.id
  tags = {
    Name = "EMRInternetGateway"
  }
}

# create a route table for the vpc IPs
resource "aws_route_table" "emr_vpc_route_table" {
  vpc_id = aws_vpc.emr_vpc.id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "emr_public_subnet_association" {
  # for each loop  to associate each subnet created to the single route table
  for_each       = toset(data.aws_availability_zones.emr_vpc_available.names)
  subnet_id      = aws_subnet.emr_public_subnet[each.value].id
  route_table_id = aws_route_table.emr_vpc_route_table.id
}

# create a vpc gateway endpoint pointing towards the s3 bucket
resource "aws_vpc_endpoint" "emr_vpc_s3_gateway_endpoint" {
  vpc_id       = aws_vpc.emr_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.emr_vpc_route_table.id
  ]

  # Add a policy to restrict access to specific S3 buckets
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.emr_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.emr_bucket.id}/*",
        ]
      },
    ]
  })

  tags = {
    Name = "emr-s3-gateway-endpoint"
  }
}
