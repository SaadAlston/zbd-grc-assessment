# AI-ASSISTED: S3 backend configuration generated with Claude.

# [SAAD] The bucket is created outside Terraform by AWS CLI. State
# infrastructure cannot live in the stack it stores: the backend must exist
# before init, and a destroy of this stack would delete the bucket holding its
# own state mid-operation. Creation commands are recorded in the README.
terraform {
  backend "s3" {
    bucket = "zbd-saad-alston-tfstate-957731521676"

    # [SAAD] Key is prefixed by environment so nonprod and prod share one
    # bucket with separate state objects. Separate directories, separate
    # state, one bucket to secure and audit.
    key    = "nonprod/terraform.tfstate"
    region = "us-east-1"

    encrypt = true

    # [SAAD] S3 native locking rather than a DynamoDB table. The assessment
    # IAM policy has no DynamoDB permissions, and DynamoDB locking is
    # deprecated in favor of this. Terraform writes a lock file beside the
    # state object and refuses a concurrent apply.
    use_lockfile = true
  }
}