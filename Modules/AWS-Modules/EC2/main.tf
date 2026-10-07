############################################
# Local Values
############################################

locals {
  normalized_volume_type = lower(var.root_volume_type)

  common_tags = merge(
    var.tags,
    {
      Name        = var.instance_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Application = var.application_name
    }
  )
}


############################################
# Validate Existing VPC
############################################

data "aws_vpc" "selected" {
  id = var.vpc_id
}


############################################
# Validate Existing Subnet
############################################

data "aws_subnet" "selected" {
  id = var.subnet_id

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}


############################################
# Validate Security Groups
############################################

data "aws_security_group" "selected" {
  for_each = toset(var.security_group_ids)

  id = each.value

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}


############################################
# AMI
############################################

data "aws_ssm_parameter" "amazon_linux_ami" {
  name = var.ami_ssm_parameter
}


############################################
# IAM Role
############################################

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}


resource "aws_iam_role" "ec2" {
  name = "${var.instance_name}-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = local.common_tags
}


############################################
# SSM Access
############################################

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ec2.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


############################################
# Instance Profile
############################################

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.instance_name}-profile"

  role = aws_iam_role.ec2.name

  tags = local.common_tags
}


############################################
# EC2 Instance
############################################

resource "aws_instance" "this" {

  ami = data.aws_ssm_parameter.amazon_linux_ami.value

  instance_type = var.instance_type

  subnet_id = data.aws_subnet.selected.id

  ##########################################
  # Security Groups
  ##########################################

  vpc_security_group_ids = [
    for sg in data.aws_security_group.selected : sg.id
  ]

  ##########################################
  # IAM
  ##########################################

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  ##########################################
  # Network Security
  ##########################################

  associate_public_ip_address = false

  ##########################################
  # EBS Optimization
  ##########################################

  ebs_optimized = true

  ##########################################
  # Monitoring
  ##########################################

  monitoring = true

  ##########################################
  # IMDSv2
  ##########################################

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  ##########################################
  # Root Volume
  ##########################################

  root_block_device {

    volume_size = var.root_volume_size

    volume_type = local.normalized_volume_type

    encrypted = true

    kms_key_id = var.kms_key_id

    delete_on_termination = true

    tags = merge(
      local.common_tags,
      {
        Name = "${var.instance_name}-root-volume"
      }
    )
  }

  ##########################################
  # User Data
  ##########################################

  user_data = var.user_data

  ##########################################
  # Tags
  ##########################################

  tags = local.common_tags

  ##########################################
  # Lifecycle
  ##########################################

  lifecycle {

    precondition {
      condition = contains(
        ["gp3", "io1", "io2"],
        local.normalized_volume_type
      )

      error_message = "root_volume_type must be gp3, io1, or io2."
    }

    precondition {
      condition = data.aws_subnet.selected.vpc_id == data.aws_vpc.selected.id

      error_message = "The subnet must belong to the specified VPC."
    }
  }

  ##########################################
  # Explicit Dependency
  ##########################################

  depends_on = [
    aws_iam_role_policy_attachment.ssm
  ]
}
