# AI-ASSISTED: root module output pass-through generated with Claude.

# [SAAD] Module outputs are not visible from the root unless re-declared here.
# These are the values needed to SSH in, reach the Prometheus UI, and target
# the scrape rule for the Step 5 break and restore.

output "instance_a_public_ip" {
  description = "SSH target for instance A."
  value       = module.app_stack.instance_a_public_ip
}

output "instance_a_private_ip" {
  description = "Prometheus scrape target."
  value       = module.app_stack.instance_a_private_ip
}

output "instance_b_public_ip" {
  description = "SSH target for instance B."
  value       = module.app_stack.instance_b_public_ip
}

output "prometheus_url" {
  description = "Prometheus UI. Operator IP only."
  value       = module.app_stack.prometheus_url
}

output "scrape_rule_id" {
  description = "Security group rule to target for the Step 5 break and restore."
  value       = module.app_stack.scrape_rule_id
}

output "log_group_names" {
  description = "CloudWatch log groups receiving system and container logs."
  value       = module.app_stack.log_group_names
}