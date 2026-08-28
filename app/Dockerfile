# AI-ASSISTED: base Dockerfile generated with Claude.
# REFINED BY SAAD: changes marked [SAAD] below.
FROM python:3.12-slim

# [SAAD] Non-root runtime user. A container running as root violates CIS Docker
# Benchmark 4.1 and maps to NIST 800-53 AC-6 least privilege. Created before
# dependency install so file ownership is correct at runtime.
RUN useradd --create-home --shell /usr/sbin/nologin appuser

WORKDIR /app

# [SAAD] Requirements copied and installed before application code so Docker
# layer caching skips the dependency install when only main.py changes. Cuts
# CI build time in Task 2.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# [SAAD] Slim base image with no build toolchain, which reduces the package
# count the container scan reports in the Task 2 pipeline.
USER appuser

EXPOSE 8080

# [SAAD] Container-level healthcheck so the runtime reports state independent
# of Prometheus. Supports SI-4 system monitoring.
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]