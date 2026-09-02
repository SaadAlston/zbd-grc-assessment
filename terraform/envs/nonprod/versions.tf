# AI-ASSISTED: root module version constraints, provider configuration and default tags generated with Claude.

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# [SAAD] The provider is configured here rather than in the module. A child
# module that configures its own provider cannot be called twice with
# different settings, so provider configuration in a module makes the nonprod
# and prod split impossible.
provider "aws" {
  region = var.aws_region

  # [SAAD] default_tags applies the candidate tag to every taggable resource
  # the provider creates, including resources I did not write a tags block for.
  # Tagging by hand means the one resource somebody forgets is the one that
  # survives teardown unattributed in a shared account.
  default_tags {
    tags = {
      candidate = var.candidate
    }
  }
}