# AI Usage Disclosure

The instructions permit AI tooling and require identifying AI-generated content
and the refinements made to it. Inline `AI-ASSISTED` and `[SAAD]` comments mark
the same information in the source.

Tool: Claude (Anthropic).

**Generated** is tool output. **Refinements** are changes made to it. Some
started as tool recommendations I evaluated and adopted, others as corrections I
identified. I reviewed the reasoning in both cases.

## app/main.py

**Generated:** FastAPI scaffold, metric definitions, endpoint handlers.

**Refinements:**

- Expanded from one metric to three. Request count and latency give Prometheus
  something to alert on. A separate health check counter keeps the scrape path
  observable with no application traffic.
- Removed counter increments from `/metrics`. Prometheus scrapes every 15
  seconds, which would dominate the request volume signal.
- Added variable latency to `/work` so the histogram fills more than one bucket.
- Constrained labels to `endpoint` and `status` to bound the series count.
- Added response class declarations so the generated OpenAPI contract reports
  the correct content types. FastAPI defaulted `/health` and `/metrics` to
  `application/json` when the handlers return plain text and Prometheus
  exposition format.

## app/Dockerfile

**Generated:** Base image, dependency install, entrypoint.

**Refinements:**

- Added non-root `appuser` with `nologin` as its shell. Moved `USER` after `pip
  install` so package installation keeps the write access it needs.
- Ordered `COPY requirements.txt` before `COPY main.py` so a code change reuses
  the cached dependency layer.
- Added a `HEALTHCHECK` polling `/health`, giving a liveness signal independent
  of Prometheus.
- Selected the slim base to reduce the package count the Task 2 container scan
  reports.

## app/README.md

**Generated:** Structure, endpoint and metric tables, first draft of the
security rationale.

**Refinements:**

- Replaced example output with verified output from local runs.
- Removed a section describing security groups that had not been built.
- Verified every SOC 2 and PCI DSS reference against the published standards.
  PCI DSS 7.2.1 replaced with 2.2.4 and 2.2.6, since 7.2.x addresses user access
  rather than process privilege. SOC 2 CC6.3 removed for the same reason. PCI
  DSS 2.2.1 removed, since that content sits at 2.2.4 in v4.0.1 rather than the
  v3.2.1 numbering.
- Reframed the unencrypted scrape path from a gap to a documented risk
  acceptance with a remediation path.

## .gitignore

**Generated:** Exclusion patterns for Terraform, Python, credentials, editor
artifacts.

**Refinements:**
- Removed `.terraform.lock.hcl`. The lock file pins provider versions and
  belongs in version control.
- Removed `!example.tfvars`. The exception pointed at a filename I do not
  create, and `terraform.tfvars.example` was never matched by `*.tfvars` in the
  first place.
- Added `*.tfplan`. Saved plan files hold resolved values including the
  operator IP and rendered user data.

## terraform/modules/app_stack/versions.tf

**Generated:** `terraform` block with a version floor and the AWS provider
constraint.

**Refinements:**
- Set the floor at 1.10.0 rather than a lower version. That release added
  `use_lockfile` for S3 native state locking. The assessment IAM policy has no
  DynamoDB permissions, so a lock table is not available and the floor is a
  hard dependency rather than a preference.
- Kept the provider at `~> 6.0`. Minor and patch upgrades are allowed, 7.0 is
  blocked. The lock file pins the exact build and checksum, the constraint only
  bounds what `init -upgrade` selects.
- Kept provider configuration out of the module. A child module that configures
  its own provider cannot be called twice with different settings, which breaks
  the nonprod and prod split the assessment asks for.

## terraform/modules/app_stack/variables.tf

**Generated:** Fourteen variable declarations with types, descriptions and
defaults.

**Refinements:**
- Added a validation block on `environment` restricting it to `nonprod` or
  `prod`. Free text produces resource names that look legitimate and match
  nothing.
- Added a validation block on `ssh_ingress_cidr` requiring `/32`. The assessment
  requires SSH from one address. A `/24` typo in a tfvars file opens 256
  addresses and produces no error. This turns it into a plan failure.
- Added a validation block on `log_retention_days` restricting values to the set
  CloudWatch accepts, with a default of 30. The CloudWatch default is never
  expire, which is a cost problem and a data minimization problem.
- Left `candidate`, `key_pair_name` and `repo_url` without defaults so the
  caller must supply them.

## terraform/modules/app_stack/network.tf

**Generated:** VPC, public subnet, internet gateway, route table and
association, flow log resources.

**Refinements:**
- Added `aws_default_security_group` with both rule sets emptied. AWS creates
  that group with the VPC and it cannot be deleted. Left alone it permits all
  traffic between attached resources. Emptying it means an instance attached by
  mistake gets no connectivity instead of unrestricted connectivity.
- Changed the flow log IAM policy from an inline role policy to a standalone
  `aws_iam_policy` plus an attachment. The assessment IAM policy grants
  `iam:CreatePolicy` and `iam:AttachRolePolicy` but not `iam:PutRolePolicy`, so
  the inline form fails at apply. Verified against the policy document before
  writing.
- Scoped that policy to the flow log group ARN rather than attaching the AWS
  managed `CloudWatchLogsFullAccess`, which would grant write access to every
  log group in a shared account.
- Set `max_aggregation_interval` to 60 rather than the 600 default, so REJECT
  records for the Step 5 break appear within a minute instead of ten.
- Made flow logs conditional on `enable_flow_logs` so the module runs without
  them if a caller does not want the cost.

## terraform/modules/app_stack/security_groups.tf

**Generated:** Two security groups and the ingress and egress rules.

**Refinements:**
- Changed inline `ingress` and `egress` blocks to separate rule resources.
  Inline blocks are authoritative, so Terraform reverts any rule added outside
  the config. Step 5 requires breaking one rule and restoring it, which is a
  targeted change against one addressable resource when rules are separate.
- Used `referenced_security_group_id` on the scrape rule rather than a CIDR.
  The instance private IP changes on replacement, so a CIDR rule either breaks
  or is written wide enough to cover the subnet. Group membership carries the
  permission instead of addressing.
- Restricted the Prometheus UI to the same operator `/32` as SSH. The UI is
  needed as Step 5 evidence and has no authentication.
- Added a Checkov skip on both egress rules with the reason recorded inline.
  Open egress is required because user data pulls packages and images and there
  is no NAT gateway or VPC endpoints. The production alternatives, endpoints for
  SSM, ECR, logs and S3 or an egress proxy with an allowlist, are named in the
  comment so the acceptance states what it is accepting.

## terraform/modules/app_stack/iam.tf

**Generated:** Instance role with trust policy, two managed policy attachments,
instance profile.

**Refinements:**
- Kept the module creating its own role rather than using the existing
  `AmazonSSMRoleForInstancesQuickSetup` in the account. That role is shared, its
  permission set is not mine, and it does not get destroyed with the stack.
- Used AWS managed policies for the CloudWatch agent and SSM rather than hand
  written equivalents. The agent's permission set changes as the agent updates,
  and maintaining a copy costs more than it returns at this scope.
- Documented the `iam:PassRole` dependency inline. The permission was absent
  from the assessment policy and blocked the instance profile. Isolated with a
  `RunInstances` dry run, requested from Thomas Montgomery, granted, then
  re-verified by dry run. The comment records the alternative rejected, which
  was static IAM keys in user data.

## terraform/modules/app_stack/logs.tf

**Generated:** CloudWatch log groups with retention.

**Refinements:**
- Split one shared log group into separate groups per instance role. Retention
  and access policy can then differ per workload. A single group means anything
  with read access to application logs also reads monitoring logs.
- Added a Checkov skip for `CKV_AWS_158` on both groups. The assessment IAM
  policy has no KMS permissions, so a customer managed key is not available.
  CloudWatch Logs still encrypts at rest with an AWS managed key. Recorded as a
  risk acceptance rather than left silent.
- Added a Checkov skip for `CKV_AWS_338` stating that 30 days is a sandbox
  decision and naming the production driver, PCI DSS v4.0.1 requirement 10.5.1,
  which is twelve months with three months immediately available.

## terraform/modules/app_stack/compute.tf

**Generated:** AMI data source and both `aws_instance` resources.

**Refinements:**
- Resolved the AMI by data source rather than pinning an ID. A pinned ID stops
  receiving patches. The tradeoff is that the image can change between plan and
  apply, so the plan output is the record of what was selected.
- Set `http_tokens` to `required` for IMDSv2. IMDSv1 answers an unauthenticated
  GET, so a server side request forgery in the application reaches instance
  metadata and retrieves role credentials. Requiring a token makes that a PUT
  the forged request cannot issue.
- Set `http_put_response_hop_limit` to 1 so a container on the host cannot reach
  metadata through the bridge network.
- Added `user_data_replace_on_change = true`. Without it Terraform updates the
  attribute and leaves the running host untouched, so state and instance
  disagree.
- Added `encrypted = true` on gp3 root volumes at 20GB.
- Passed instance A's private IP into instance B's user data rather than
  hardcoding it. That reference creates the implicit dependency, so Terraform
  orders A before B with no `depends_on`. The cost is that replacing A replaces
  B, which is recorded in the comment as accepted rather than hidden.

## terraform/modules/app_stack/outputs.tf

**Generated:** Output declarations for instance addresses and identifiers.

**Refinements:**
- Added `scrape_rule_id`. Step 5 requires breaking and restoring the scrape
  rule, and exposing the ID makes that a targeted apply against a known resource
  rather than a hunt through the console.
- Added `prometheus_url` as a constructed value so the UI address does not have
  to be assembled by hand.
- Grouped the log group names into a single map output, with the flow log entry
  returning null when flow logs are disabled.

## terraform/modules/app_stack/user_data_instance_a.sh.tftpl

**Generated:** Bootstrap script installing Docker, the CloudWatch agent, and
running the application container.

**Refinements:**
- Added `set -euxo pipefail`. Without `-e` a failed step leaves a half
  configured host that looks healthy in the console. `-x` writes every command
  to `cloud-init-output.log`, which makes that log a usable record of what ran.
- Wrote the SSH hardening as a drop-in at `99-hardening.conf` rather than
  editing `sshd_config`. Amazon Linux 2023 already defaults to these values.
  Setting them explicitly means a base image change cannot silently re-enable
  password authentication.
- Added `sshd -t` before restarting the service, so a bad config fails the
  script instead of locking the instance out.
- Added `dnf-automatic` limited to security updates. Recorded inline that this
  is a sandbox control and that production belongs in Patch Manager with a
  maintenance window, which is what Task 3 builds.
- Added the three log paths the CloudWatch agent ships: `/var/log/messages`,
  `/var/log/secure` and `cloud-init-output.log`. `secure` carries the SSH
  authentication record and `cloud-init-output.log` carries the bootstrap
  result.
- Changed container logging to the `awslogs` driver rather than having the agent
  tail a file. The daemon holds the instance role credentials and ships stdout
  directly, so no log file exists on disk to rotate or lose.
- Recorded that the image is built on the instance from the public repo, and
  that production would build once in CI, scan, push to ECR and pull an
  immutable digest. Building on the host puts a build toolchain on a running
  server, which is the reason not to do it outside a sandbox.

## terraform/modules/app_stack/user_data_instance_b.sh.tftpl

**Generated:** Bootstrap script installing Docker, the CloudWatch agent, and
running Prometheus with a templated configuration.

**Refinements:**
- Applied the same `set -euxo pipefail`, SSH drop-in, `sshd -t` check,
  `dnf-automatic` and CloudWatch agent configuration as instance A. The two
  hosts share a hardening baseline, so a control present on one is present on
  both.
- Templated `prometheus.yml` with instance A's private IP rather than a public
  address. The scrape then stays inside the VPC, never traverses the internet
  gateway, and the source security group rule is the only path to the target.
- Pinned the Prometheus image by digest rather than the `v3.1.0` tag. A tag is a
  mutable pointer, so the same user data would produce different software over
  time. A digest is a content hash, so a substituted image fails to pull instead
  of running silently. Digest read from the v3.1.0 tag on September 1, 2026.
- Left `git` out of the package list. Instance B builds nothing.

## Not AI-generated

- Repository structure and environment separation.
- Verification commands and captured output.
- The decision to map controls to SOC 2 and PCI DSS rather than NIST 800-53.