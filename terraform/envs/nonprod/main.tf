# AI-ASSISTED: module call for the nonprod environment generated with Claude.

# [SAAD] Directory per environment rather than workspaces. Workspaces share one
# backend key and one set of variable files, so the only thing separating
# nonprod from prod is which workspace is selected at the terminal. A directory
# makes the environment visible in the path, lets the two configs diverge, and
# makes a prod apply a deliberate cd rather than a forgotten select.
module "app_stack" {
  source = "../../modules/app_stack"

  candidate        = var.candidate
  environment      = "nonprod"
  ssh_ingress_cidr = var.ssh_ingress_cidr
  key_pair_name    = var.key_pair_name
  repo_url         = var.repo_url
  # [SAAD] Flow logs disabled. The role needs write access to its log group,
  # and the scoped customer managed policy fails because iam:CreatePolicy is
  # explicitly denied by security_engineer_policy in this account. The
  # available workaround is attaching CloudWatchLogsFullAccess, which grants
  # write access to every log group in a shared account. Step 5 evidence comes
  # from the Prometheus target state instead.
  enable_flow_logs = false
}