# API Service

FastAPI application exposing a health check and a Prometheus metrics endpoint.
Runs on Instance A. Scraped by Prometheus on Instance B. Packaged as a container
image.

## Endpoints

| Path | Method | Response | Purpose |
|---|---|---|---|
| `/health` | GET | `200`, body `I'm healthy` | Liveness check. Plain text so any checker parses it without a decoder. |
| `/metrics` | GET | `200`, Prometheus exposition format | Scrape target for Instance B. |
| `/work` | GET | `200`, JSON status and duration | Optional third endpoint. Generates 10ms to 400ms of latency so the histogram fills with a real distribution. |

`openapi.json` is the generated API contract, committed as a versioned artifact.
Regenerate it after any endpoint change:

```bash
curl -s http://localhost:8000/openapi.json | python -m json.tool > openapi.json
```

## Metrics

| Metric | Type | Labels | Reasoning |
|---|---|---|---|
| `app_requests_total` | Counter | `endpoint`, `status` | Request volume only increases. Labels split the series per route and status code, making per-endpoint error rate queryable. |
| `app_request_duration_seconds` | Histogram | `endpoint` | Latency needs percentiles. A Histogram buckets observations so p50, p95, and p99 are derivable. A Counter cannot answer a latency question. |
| `app_health_checks_total` | Counter | none | Separates health check volume from application traffic, so the scrape path is provably live with no user requests. |

Label cardinality is deliberately low. Each unique label combination creates a
separate time series, and Prometheus holds every series in memory, so
high-cardinality labels such as request IDs or user identifiers are excluded.

`prometheus_client` emits a companion `_created` gauge for each Counter and
Histogram holding the series initialization timestamp. Library behavior, not
application code. Consumers use them to detect counter resets after a restart.

## Build and run

```bash
cd app
docker build -t zbd-api:local .
docker run --rm -p 8000:8000 zbd-api:local
```

Generate traffic and read the metrics:

```bash
curl http://localhost:8000/health
for i in {1..10}; do curl -s http://localhost:8000/work > /dev/null; done
curl -s http://localhost:8000/metrics | grep app_
```

## Verification

Metrics after 5 health checks and 11 requests to `/work`:

```
app_requests_total{endpoint="/health",status="200"} 5.0
app_requests_total{endpoint="/work",status="200"} 11.0
app_request_duration_seconds_bucket{endpoint="/work",le="0.1"} 1.0
app_request_duration_seconds_bucket{endpoint="/work",le="0.25"} 3.0
app_request_duration_seconds_bucket{endpoint="/work",le="0.5"} 11.0
app_request_duration_seconds_count{endpoint="/work"} 11.0
app_request_duration_seconds_sum{endpoint="/work"} 3.177042007446289
app_health_checks_total 5.0
```

Buckets are cumulative. All 11 requests completed under 500ms, 3 under 250ms, 1
under 100ms. Count of 11 against a sum of 3.177 seconds gives a mean of 289ms,
consistent with the range the endpoint generates.

The `/health` count rises independently of manual requests because the container
HEALTHCHECK polls the endpoint every 30 seconds.

Runtime user:

```
$ docker exec 93a225bb6723 whoami
appuser
```

Container health status:

```
CONTAINER ID   IMAGE           STATUS
93a225bb6723   zbd-api:local   Up 3 minutes (healthy)
```

## Security decisions

Control references map to the SOC 2 Trust Services Criteria (2017, revised
points of focus 2022) and PCI DSS v4.0.1. Nothing here is a cardholder data
environment. These mappings show the assessment approach, not in-scope
compliance.

### Non-root container user

The image creates `appuser` with `nologin` as its shell and switches to that
user before the application starts. A compromised process inherits the
privileges of the account running it. Root would allow filesystem writes
anywhere, package installation, and a stronger position for a runtime escape to
the host.

Verified: `docker exec <container> whoami` returns `appuser`.

SOC 2 CC6.1. PCI DSS 2.2.4, 2.2.6. CIS Docker Benchmark 4.1.

### Slim base image

The base is `python:3.12-slim`. The full `python:3.12` image ships compilers,
headers, and utilities the application never calls. Each carries its own CVE
history and each is tooling available post-compromise. Removing them at build
time cuts attack surface and the finding volume the Task 2 container scan
produces.

SOC 2 CC7.1. PCI DSS 2.2.4.

### Pinned dependency versions

`requirements.txt` pins exact versions. With a floating range, `pip` resolves to
whatever is newest at build time, so the image scanned in CI and the image
running in production can differ. The scan result then describes an artifact
that no longer exists.

SOC 2 CC8.1. PCI DSS 6.3.2, which requires an inventory of third-party
components to support vulnerability and patch management.

### Base image pinned by digest

The build resolved `python:3.12-slim` to
`sha256:09f7da3bc104798d0afb40bc08d23ab2da20a76130cec1f2ef170848f5d85217`.
A tag is a mutable pointer and resolves to a different image after any upstream
rebuild. A digest is a content hash. Recording it means the artifact assessed
and the artifact deployed are the same bytes.

SOC 2 CC8.1. PCI DSS 6.3.2. DORA Article 28.

### Independent healthcheck

The Dockerfile polls `/health` locally every 30 seconds. Prometheus scrapes the
same application from Instance B. The duplication is deliberate. With only the
Prometheus signal, a Prometheus outage, a network partition, and a security
group misconfiguration are indistinguishable from an application failure.

Verified: `docker ps` reports `Up 3 minutes (healthy)`.

SOC 2 CC7.2. DORA Articles 9 and 10.

### Risk acceptance: unencrypted scrape path

Prometheus scrapes `/metrics` over plain HTTP. TLS on this path would satisfy
SOC 2 CC6.7, which covers protection of information during transmission.

The exposed metrics contain request counts and latency distributions. No
credentials, identifiers, or transaction data. Network-level compensating
controls are documented in `terraform/` once the security groups are built.

Production remediation would terminate TLS on the scrape endpoint with
certificates issued through ACM or an internal CA, and configure Prometheus to
verify them.

## AI usage

Application code and Dockerfile were drafted with AI assistance and refined
manually. Inline `AI-ASSISTED` and `[SAAD]` comments mark generated content and
the changes made. Full accounting in `../docs/ai-usage.md`.