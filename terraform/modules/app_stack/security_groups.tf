# AI-ASSISTED: security groups and rules for the API and Prometheus instances generated with Claude.

# [SAAD] Groups and rules are separate resources rather than inline ingress
# and egress blocks. Inline blocks are authoritative, so Terraform reverts any
# rule added outside the config on the next apply. Step 5 requires me to break
# a rule and restore it, and separate rule resources make that a targeted
# change to one addressable resource instead of an edit inside a group.
resource "aws_security_group" "api" {
  name        = "${var.candidate}-${var.environment}-api-sg"
  description = "Instance A. API server. SSH from operator IP, metrics from Prometheus only."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.candidate}-${var.environment}-api-sg"
  }
}

resource "aws_security_group" "prometheus" {
  name        = "${var.candidate}-${var.environment}-prometheus-sg"
  description = "Instance B. Prometheus. SSH and UI from operator IP only."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.candidate}-${var.environment}-prometheus-sg"
  }
}

# [SAAD] The rule the assessment is testing. Source is the Prometheus security
# group ID, not a CIDR. The instance private IP changes on replacement and a
# CIDR rule would either break or be written wide enough to cover the subnet.
# Group as source means the permission follows membership, so anything in the
# Prometheus group can scrape and nothing else can, regardless of addressing.
resource "aws_vpc_security_group_ingress_rule" "api_metrics_from_prometheus" {
  security_group_id            = aws_security_group.api.id
  referenced_security_group_id = aws_security_group.prometheus.id
  from_port                    = var.api_port
  to_port                      = var.api_port
  ip_protocol                  = "tcp"
  description                  = "Prometheus scrape of /metrics on instance A"

  tags = {
    Name = "${var.candidate}-${var.environment}-api-metrics-from-prometheus"
  }
}

# [SAAD] SSH restricted to a single /32 validated in variables.tf. The module
# rejects anything wider at plan time rather than trusting the tfvars file.
resource "aws_vpc_security_group_ingress_rule" "api_ssh" {
  security_group_id = aws_security_group.api.id
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH from operator IP"

  tags = {
    Name = "${var.candidate}-${var.environment}-api-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_ssh" {
  security_group_id = aws_security_group.prometheus.id
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "SSH from operator IP"

  tags = {
    Name = "${var.candidate}-${var.environment}-prometheus-ssh"
  }
}

# [SAAD] The Prometheus UI is reachable from my IP only. It is needed as
# evidence for Step 5, showing the target transition to down when the scrape
# rule is removed. Same /32 restriction as SSH.
resource "aws_vpc_security_group_ingress_rule" "prometheus_ui" {
  security_group_id = aws_security_group.prometheus.id
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = var.prometheus_port
  to_port           = var.prometheus_port
  ip_protocol       = "tcp"
  description       = "Prometheus UI from operator IP"

  tags = {
    Name = "${var.candidate}-${var.environment}-prometheus-ui"
  }
}

# [SAAD] Egress is open to 0.0.0.0/0 on both instances. User data pulls Docker
# packages, the CloudWatch agent and container images from the internet, and
# the instances have no NAT or VPC endpoints. This is the widest rule in the
# module and it is a deliberate scope decision, not an oversight. Narrowing it
# means either VPC endpoints for SSM, ECR, logs and S3, or an egress proxy with
# an allowlist. Both are the right answer in production and neither fits a
# two-instance sandbox with no NAT gateway budget.
resource "aws_vpc_security_group_egress_rule" "api_all" {
  # checkov:skip=CKV_AWS_382:Egress to 0.0.0.0/0 required for package and image pulls. No NAT gateway or VPC endpoints in this environment. Documented risk acceptance with compensating controls in the module README.
  security_group_id = aws_security_group.api.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound for package and container image pulls"

  tags = {
    Name = "${var.candidate}-${var.environment}-api-egress"
  }
}

resource "aws_vpc_security_group_egress_rule" "prometheus_all" {
  # checkov:skip=CKV_AWS_382:Egress to 0.0.0.0/0 required for package and image pulls. No NAT gateway or VPC endpoints in this environment. Documented risk acceptance with compensating controls in the module README.
  security_group_id = aws_security_group.prometheus.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound for package and container image pulls"

  tags = {
    Name = "${var.candidate}-${var.environment}-prometheus-egress"
  }
}