# AI-ASSISTED: AMI data source and both EC2 instances generated with Claude.

# [SAAD] AMI resolved at plan time rather than hardcoded. A pinned AMI ID goes
# stale and stops receiving patches. Resolving the latest Amazon Linux 2023
# image means a rebuild gets current packages. The tradeoff is that the AMI can
# change between plan and apply, so the plan output is the record of which
# image was selected.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  # [SAAD] IMDSv2 required rather than optional. IMDSv1 answers an unauthenticated
  # GET, so a server side request forgery in the application reaches instance
  # metadata and retrieves the role credentials. Requiring a token turns that
  # into a PUT the forged request cannot make. hop_limit 1 stops a container
  # on the host from reaching metadata through the bridge.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20

    tags = {
      Name = "${var.candidate}-${var.environment}-instance-a-root"
    }
  }

  user_data = templatefile("${path.module}/user_data_instance_a.sh.tftpl", {
    log_group_name = aws_cloudwatch_log_group.api.name
    aws_region     = data.aws_region.current.region
    repo_url       = var.repo_url
    container_name = var.container_name
    api_port       = var.api_port
  })

  # [SAAD] user_data_replace_on_change forces a new instance when the script
  # changes. Without it Terraform updates the attribute and leaves the running
  # host untouched, so the state says one thing and the instance is another.
  # Replacement is the honest behavior for immutable infrastructure.
  user_data_replace_on_change = true

  tags = {
    Name        = "${var.candidate}-${var.environment}-instance-a"
    server_name = "instance_a"
  }
}

# [SAAD] Instance B's user data references aws_instance.api.private_ip, which
# creates an implicit dependency. Terraform orders A before B from that
# reference alone, no depends_on needed. The cost is coupling: replacing A
# changes B's user data and replaces B as well. That coupling is real. B
# cannot scrape a target it cannot address, and a hardcoded IP would hide the
# dependency rather than remove it.
resource "aws_instance" "prometheus" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.prometheus.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20

    tags = {
      Name = "${var.candidate}-${var.environment}-instance-b-root"
    }
  }

  user_data = templatefile("${path.module}/user_data_instance_b.sh.tftpl", {
    log_group_name  = aws_cloudwatch_log_group.prometheus.name
    aws_region      = data.aws_region.current.region
    api_private_ip  = aws_instance.api.private_ip
    api_port        = var.api_port
    prometheus_port = var.prometheus_port
  })

  user_data_replace_on_change = true

  tags = {
    Name        = "${var.candidate}-${var.environment}-instance-b"
    server_name = "instance_b"
  }
}

data "aws_region" "current" {}