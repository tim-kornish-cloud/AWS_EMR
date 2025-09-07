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

  #ingress {
  #  from_port   = 8443 # EMR console (if needed)
  #  to_port     = 8443
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"] # Restrict to your specific IP or CIDR range in production
  #}

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