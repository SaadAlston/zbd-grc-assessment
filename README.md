# zbd-grc-assessment

Candidate: Saad Alston

## Status
- [x] Task 1, Step 1: Repository setup
- [ ] Task 1, Step 2: API with health and metrics endpoints
- [ ] Task 1, Step 3: AWS credentials
- [ ] Task 1, Step 4: Terraform EC2 provisioning
- [ ] Task 1, Step 5: Prometheus scraping and security group validation
- [ ] Task 2: CI/CD, container scan, S3 backend, module refactor
- [ ] Task 3: Patch automation, SSM State Manager, root login alarm

## Repository layout

- `app/` API service, Dockerfile, and application documentation
- `terraform/` infrastructure as code, modules and environments
- `.github/workflows/` CI/CD pipelines
- `docs/` architecture, security rationale, AI usage disclosure

## Resource tagging

All AWS resources are tagged through the Terraform provider `default_tags`
block so no resource can be created untagged:

- candidate: saad_alston
- server_name: instance_a or instance_b

## AI usage

AI-assisted content is marked inline with `AI-ASSISTED` and `REFINED`
comments. Full accounting in `docs/ai-usage.md`.
