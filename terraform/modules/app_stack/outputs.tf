# AI-ASSISTED: module outputs generated with Claude.

# [SAAD] Outputs are the only supported way for a caller to read values from a
# child module. These are the addresses and identifiers needed to SSH in,
# reach the Prometheus UI, and target the scrape rule when breaking and
# restoring it for Step 5.

output "instance_a_public_ip" {
  description = "Public address of instance A. SSH target."
  value       = aws_instance.api.public_ip
}

output "instance_a_private_ip" {
  description = "Private address of instance A. Prometheus scrape target."
  value       = aws_instance.api.private_ip
}

output "instance_b_public_ip" {
  description = "Public address of instance B. SSH and Prometheus UI target."
  value       = aws_instance.prometheus.public_ip
}

output "prometheus_url" {
  description = "Prometheus UI. Reachable from the operator IP only."
  value       = "http://${aws_instance.prometheus.public_ip}:${var.prometheus_port}"
}

# [SAAD] The scrape rule ID is exposed because Step 5 requires breaking it and
# restoring it. Having the address here means the change is a targeted apply
# against a known resource rather than hunting for it in the console.
output "scrape_rule_id" {
  description = "Security group rule permitting the Prometheus scrape. Target for the Step 5 break and restore."
  value       = aws_vpc_security_group_ingress_rule.api_metrics_from_prometheus.id
}

output "api_security_group_id" {
  description = "Security group attached to instance A."
  value       = aws_security_group.api.id
}

output "prometheus_security_group_id" {
  description = "Security group attached to instance B."
  value       = aws_security_group.prometheus.id
}

output "log_group_names" {
  description = "CloudWatch log groups receiving system and container logs."
  value = {
    instance_a = aws_cloudwatch_log_group.api.name
    instance_b = aws_cloudwatch_log_group.prometheus.name
    flow_logs  = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
  }
}