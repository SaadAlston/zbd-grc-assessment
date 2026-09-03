# AI-ASSISTED: module call for the prod environment generated with Claude.

# [SAAD] This directory is not applied. It exists to prove the module takes two
# callers with different inputs, which is what the assessment asks for. Applying
# it would create a second pair of instances in a shared sandbox for no benefit.
# The value is in what differs from nonprod: a separate state key, a separate
# CIDR so the two environments could peer or be audited without collision, and
# flow logs left enabled because the permission constraint that removed them
# from nonprod is a property of this assessment account, not of the module.
module "app_stack" {
  source = "../../modules/app_stack"

  candidate        = var.candidate
  environment      = "prod"
  ssh_ingress_cidr = var.ssh_ingress_cidr
  key_pair_name    = var.key_pair_name
  repo_url         = var.repo_url

  # [SAAD] Distinct CIDR from nonprod's 10.42.0.0/16. Overlapping ranges block
  # peering and make flow log analysis ambiguous about which environment a
  # private address belongs to.
  vpc_cidr    = "10.43.0.0/16"
  subnet_cidr = "10.43.1.0/24"

  # [SAAD] 365 days rather than nonprod's 30. Production retention is set
  # against the applicable requirement. PCI DSS v4.0.1 requirement 10.5.1 is
  # twelve months with three months immediately available.
  log_retention_days = 365
}