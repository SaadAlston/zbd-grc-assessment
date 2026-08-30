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

**Refinement:** Removed `.terraform.lock.hcl`. The lock file pins provider
versions and belongs in version control.

## Not AI-generated

- Repository structure and environment separation.
- Verification commands and captured output.
- The decision to map controls to SOC 2 and PCI DSS rather than NIST 800-53.