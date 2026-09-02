# AI-ASSISTED: CloudWatch log groups for application and system logs generated with Claude.

# [SAAD] Separate log groups per instance role rather than one shared group.
# Retention, and later access policy, can differ per workload. A single group
# means anything with read access to application logs also reads monitoring
# logs. Splitting them keeps that a choice rather than a side effect.
resource "aws_cloudwatch_log_group" "api" {
  # checkov:skip=CKV_AWS_158:No KMS permissions in the assessment IAM policy. CloudWatch Logs encrypts at rest with an AWS managed key by default. Documented risk acceptance, not an omission.
  # checkov:skip=CKV_AWS_338:30 day retention is a sandbox decision, not a proposed standard. Production retention would be set against the applicable regulatory requirement, which for card data under PCI DSS v4.0.1 requirement 10.5.1 is 12 months with 3 months immediately available.
  name              = "/${var.candidate}/${var.environment}/instance-a"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.candidate}-${var.environment}-instance-a-logs"
  }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  # checkov:skip=CKV_AWS_158:No KMS permissions in the assessment IAM policy. CloudWatch Logs encrypts at rest with an AWS managed key by default. Documented risk acceptance, not an omission.
  # checkov:skip=CKV_AWS_338:30 day retention is a sandbox decision, not a proposed standard. Production retention would be set against the applicable regulatory requirement, which for card data under PCI DSS v4.0.1 requirement 10.5.1 is 12 months with 3 months immediately available.
  name              = "/${var.candidate}/${var.environment}/instance-b"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.candidate}-${var.environment}-instance-b-logs"
  }
}