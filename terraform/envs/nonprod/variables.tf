# AI-ASSISTED: root module variable definitions generated with Claude.

variable "aws_region" {
  description = "Region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "candidate" {
  description = "Candidate name in snake case. Applied to every resource by default_tags."
  type        = string
  default     = "saad_alston"
}

# [SAAD] No default. The value is my current public address, it changes, and a
# stale default silently grants SSH to whoever holds that address now. Supplied
# in terraform.tfvars, which is gitignored.
variable "ssh_ingress_cidr" {
  description = "Operator public IP in /32 form. Validated in the module."
  type        = string
}

variable "key_pair_name" {
  description = "Existing EC2 key pair. Created outside Terraform so the private key never enters state."
  type        = string
  default     = "saad-alston-assessment"
}

variable "repo_url" {
  description = "HTTPS clone URL for the application repository."
  type        = string
  default     = "https://github.com/SaadAlston/zbd-grc-assessment.git"
}