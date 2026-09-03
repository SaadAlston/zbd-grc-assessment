# AI-ASSISTED: S3 backend configuration for the prod environment generated with Claude.

# [SAAD] Same bucket as nonprod, different key. One bucket to secure, audit and
# apply lifecycle rules to, with state separated per environment by prefix.
# The alternative is a bucket per environment, which is the stronger isolation
# and the right answer when environments live in separate AWS accounts. In a
# single shared account a second bucket adds a second thing to configure
# correctly without adding a real boundary.
terraform {
  backend "s3" {
    bucket = "zbd-saad-alston-tfstate-957731521676"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"

    encrypt      = true
    use_lockfile = true
  }
}