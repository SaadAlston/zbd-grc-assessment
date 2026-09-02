# AI-ASSISTED: Terraform version and provider constraints generated with Claude.

terraform {
  # [SAAD] 1.10 is the floor for use_lockfile on the S3 backend. The IAM
  # policy has no DynamoDB permissions, so state locking has to be native to
  # S3 rather than a lock table. Pinning the floor here makes that dependency
  # explicit instead of leaving it as an undocumented assumption.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      # [SAAD] Pessimistic constraint allows 6.x minor and patch and blocks
      # 7.0. Provider major versions carry breaking changes. The constraint
      # bounds what init -upgrade selects. The lock file pins the exact build
      # and its checksum.
      version = "~> 6.0"
    }
  }
}