# AI-ASSISTED: VPC, subnet, routing and flow log resources generated with Claude.

# [SAAD] Own VPC rather than the existing 10.0.0.0/16. This is a shared
# sandbox with other candidates and a founder instance running. A separate
# CIDR means nothing I create can route to anything I did not, and destroy
# removes everything without touching another tenant.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.candidate}-${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.candidate}-${var.environment}-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.candidate}-${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.candidate}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# [SAAD] The default security group is created by AWS with the VPC and cannot
# be deleted. Left alone it permits all traffic between anything attached to
# it. Emptying both rule sets means an instance attached by mistake gets no
# connectivity rather than unrestricted connectivity.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.candidate}-${var.environment}-default-sg-locked"
  }
}

# [SAAD] Flow logs produce the evidence for Step 5. When I break the source
# security group rule the Prometheus UI shows the target down. Flow logs show
# REJECT records for the scrape connection at the same time, which proves the
# security group caused it rather than the application failing.
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  # checkov:skip=CKV_AWS_158:No KMS permissions in the assessment IAM policy. CloudWatch Logs encrypts at rest with an AWS managed key by default. Documented risk acceptance, not an omission.
  name              = "/aws/vpc/${var.candidate}-${var.environment}-flow-logs"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.candidate}-${var.environment}-flow-logs"
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.candidate}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

# [SAAD] Standalone managed policy rather than an inline role policy. The
# assessment IAM policy grants iam:CreatePolicy and iam:AttachRolePolicy but
# not iam:PutRolePolicy, so an inline policy fails at apply. Verified against
# the policy document before writing this. Same scoping either way.
resource "aws_iam_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name        = "${var.candidate}-${var.environment}-flow-logs-policy"
  description = "Write access limited to the VPC flow log group."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

# [SAAD] Scoped to the flow log group ARN rather than using the AWS managed
# CloudWatchLogsFullAccess. The role writes to one log group. The managed
# policy would grant write access to every log group in a shared account.
resource "aws_iam_role_policy_attachment" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  role       = aws_iam_role.flow_logs[0].name
  policy_arn = aws_iam_policy.flow_logs[0].arn
}

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  max_aggregation_interval = 60

  tags = {
    Name = "${var.candidate}-${var.environment}-flow-log"
  }
}