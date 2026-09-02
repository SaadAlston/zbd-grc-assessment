# AI-ASSISTED: module variable definitions generated with Claude.

variable "candidate" {
  description = "Candidate name in snake case. Applied to every resource as a tag."
  type        = string
}

variable "environment" {
  description = "Environment name. Used in resource names to keep nonprod and prod distinguishable in a shared account."
  type        = string

  # [SAAD] Constrained rather than free text. The same module runs against
  # nonprod and prod, and a typo here produces resource names that look
  # legitimate but do not match anything the rest of the config expects.
  validation {
    condition     = contains(["nonprod", "prod"], var.environment)
    error_message = "environment must be nonprod or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the module VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.42.1.0/24"
}

variable "availability_zone" {
  description = "AZ for the subnet. Single AZ is deliberate for this assessment."
  type        = string
  default     = "us-east-1a"
}

variable "ssh_ingress_cidr" {
  description = "Single address permitted to reach SSH. Assessment requires operator IP only."
  type        = string

  # [SAAD] Enforcing /32 in the module rather than trusting the caller.
  # The assessment requires SSH from my IP only, and a /24 typo in a tfvars
  # file opens 256 addresses without producing any error. This turns that
  # into a plan failure.
  validation {
    condition     = can(cidrnetmask(var.ssh_ingress_cidr)) && endswith(var.ssh_ingress_cidr, "/32")
    error_message = "ssh_ingress_cidr must be a single address in /32 form."
  }
}

variable "instance_type" {
  description = "EC2 instance type for both instances."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair. Created outside Terraform so the private key never enters state."
  type        = string
}

variable "log_retention_days" {
  description = "Retention for the application and flow log groups."
  type        = number
  default     = 30

  # [SAAD] Explicit rather than left at never expire. Unbounded retention is
  # the CloudWatch default and it is both a cost problem and a data
  # minimization problem. 30 days is short for production. It is documented
  # as a sandbox decision, not proposed as a standard.
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be a retention period CloudWatch accepts."
  }
}

variable "enable_flow_logs" {
  description = "Create VPC flow logs. Used as evidence when the scrape security group rule is broken and restored."
  type        = bool
  default     = true
}

variable "api_port" {
  description = "Port the API container listens on. Prometheus scrapes /metrics here."
  type        = number
  default     = 8000
}

variable "prometheus_port" {
  description = "Port the Prometheus UI listens on."
  type        = number
  default     = 9090
}

variable "repo_url" {
  description = "HTTPS clone URL for the application repository. Cloned on instance A to build the image."
  type        = string
}

variable "container_name" {
  description = "Name for the application container and its local image tag."
  type        = string
  default     = "zbd-api"
}