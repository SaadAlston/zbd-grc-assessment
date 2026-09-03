# zbd-grc-assessment

Candidate: Saad Alston

## Status

- [x] Task 1, Step 1: Repository setup
- [x] Task 1, Step 2: API with health and metrics endpoints
- [x] Task 1, Step 3: AWS credentials
- [x] Task 1, Step 4: Terraform EC2 provisioning
- [x] Task 1, Step 5: Prometheus scraping and security group validation
- [x] Task 2: CI/CD, container scan, S3 backend, module refactor
- [ ] Task 3: Patch automation, SSM State Manager, root login alarm

## Repository layout

- `app/` API service, Dockerfile, and application documentation
- `terraform/modules/app_stack/` the module both environments call
- `terraform/envs/nonprod/` applied environment
- `terraform/envs/prod/` second caller, not applied
- `.github/workflows/` CI pipeline
- `docs/` AI usage disclosure and evidence

## Deployed environment

Account 957731521676, us-east-1. VPC 10.42.0.0/16 with one public subnet.
Instance A runs the API container. Instance B runs Prometheus and scrapes
instance A over the private address.

State lives in S3 at `zbd-saad-alston-tfstate-957731521676` with versioning,
default encryption, public access blocked, and S3 native locking through
`use_lockfile`. The bucket is created outside Terraform. State infrastructure
should not live in the stack it stores, since a destroy would remove the
bucket holding its own state mid-operation.

## Environments

`nonprod` and `prod` are separate directories calling the same module, not
Terraform workspaces. Separate directories give each environment its own
backend key and its own state object, so a mistake in one cannot reach the
other. Workspaces share a backend and separate state only by which workspace
is selected at the terminal.

`prod` is not applied. It exists to show the module takes two callers with
different inputs. What differs: a separate state key, CIDR 10.43.0.0/16 so
the two environments do not overlap, 365 day log retention against PCI DSS
v4.0.1 requirement 10.5.1, and flow logs left enabled because the permission
constraint that removed them from nonprod is a property of this assessment
account rather than of the module.

## Task 1, Step 5: security group validation

The scrape rule permits the Prometheus security group to reach port 8000 on
instance A. Source is the security group ID, not a CIDR, so the permission
follows group membership rather than an address that changes on replacement.

Rule removed:

    aws ec2 revoke-security-group-ingress \
      --group-id sg-01734b3f80e41615b \
      --security-group-rule-ids sgr-0cd443e3eca67d265

Prometheus reported the target DOWN within one scrape interval, with
`context deadline exceeded` on `http://10.42.1.197:8000/metrics`. The error
is a timeout rather than a connection refusal, which is the distinction
worth noting: a security group drops packets silently instead of sending a
TCP reset. A refused connection would mean the port was reachable and
nothing was listening. A timeout means the packet never arrived.

Restored with `terraform apply`, which also demonstrates drift correction
rather than a second manual change. Target returned to UP.

Evidence: `docs/evidence/step5-target-down.png` and
`docs/evidence/step5-target-up.png`.

## CI pipeline

`.github/workflows/terraform.yml`. Scanning runs before anything touches AWS,
ordered secrets, then infrastructure code, then the container image. Cheapest
and most damaging first.

- Gitleaks over full history. A scan of the tip commit misses a credential
  added earlier in the branch, and a public repository is cloned in full.
- Checkov against `terraform/` with `soft_fail: false`. Findings that are
  accepted carry an inline `checkov:skip` with a written rationale, so the
  acceptance is reviewable in the diff rather than invisible in a log.
- Trivy against the built image, failing on HIGH and CRITICAL, ignoring
  unfixed. A finding with no available patch cannot be actioned by the
  pipeline and belongs in vulnerability management, not a merge block.

Plan runs on pull requests. Apply runs on merge to main. Plan is the review
artifact and apply is the gated action.

Two gaps, stated rather than hidden. Credentials are GitHub secrets because
this account has no OIDC provider configured; OIDC with an assumed role is
the correct pattern and removes the long-lived key. Apply has no required
reviewer, because approving my own apply is not a control.

## Risk acceptances

Each carries an inline rationale at the point of the finding.

- `CKV_AWS_158` CloudWatch log groups not encrypted with a customer managed
  key. No KMS permissions in the assessment IAM policy. Logs are still
  encrypted at rest with an AWS managed key.
- `CKV_AWS_338` retention under one year. Sandbox decision at 30 days in
  nonprod, 365 in prod.
- `CKV_AWS_382` egress to 0.0.0.0/0. No NAT gateway or VPC endpoints.
  Compensating controls are non-root single-container hosts and an instance
  role scoped to logging and session access.
- `CKV_AWS_130` public IPs on the subnet. SSH is a stated requirement and
  both hosts pull packages with no NAT gateway. Access is restricted to one
  operator /32.
- `CKV_AWS_126` detailed monitoring disabled. Prometheus already scrapes
  application metrics.
- `CKV_AWS_135` EBS optimization. t3.micro has it enabled by default and the
  attribute is not configurable, so this is a false positive rather than an
  acceptance.

VPC flow logs are absent from nonprod. The flow log role needed write access
to one log group and `iam:CreatePolicy` is explicitly denied in this account.
The available workaround was attaching `CloudWatchLogsFullAccess`, which
grants the role write access to every log group in a shared account. The
control was removed rather than the permission widened.

The Prometheus scrape path is unencrypted HTTP. It stays inside the VPC on a
private address, never crosses the internet gateway, and is reachable only
through the source security group rule. Production would terminate TLS at
the scrape target or move the traffic onto a service mesh.

## Resource tagging

All AWS resources are tagged through the Terraform provider `default_tags`
block so no resource can be created untagged:

- candidate: saad_alston
- server_name: instance_a or instance_b

## AI usage

AI-assisted content is marked inline with `AI-ASSISTED` headers naming what
was generated, and `[SAAD]` comments explaining the decision behind each
change made to it. Full per-file accounting in `docs/ai-usage.md`.