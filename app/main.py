# AI-ASSISTED: initial FastAPI + prometheus_client scaffold generated with Claude.
# REFINED BY SAAD: changes marked [SAAD] below.
import os
import random
import time

from fastapi import FastAPI, Response
from fastapi.responses import PlainTextResponse
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI(title="zbd-grc-assessment-api")

# [SAAD] Three metrics instead of the single required one. Request count and
# latency give Prometheus something to alert on. A separate health check counter
# proves the scrape path is live independent of application traffic.
REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total HTTP requests handled.",
    ["endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "app_request_duration_seconds",
    "Request latency in seconds.",
    ["endpoint"],
)
HEALTH_CHECKS = Counter(
    "app_health_checks_total",
    "Total health check requests received.",
)


# [SAAD] response_class declared so the generated OpenAPI contract reports
# text/plain. FastAPI defaults to application/json without it.
@app.get("/health", response_class=PlainTextResponse)
def health():
    HEALTH_CHECKS.inc()
    REQUEST_COUNT.labels(endpoint="/health", status="200").inc()
    return Response(content="I'm healthy", media_type="text/plain", status_code=200)


# [SAAD] Same reason. Carries the Prometheus exposition content type into the
# contract instead of application/json.
@app.get(
    "/metrics",
    response_class=Response,
    responses={200: {"content": {CONTENT_TYPE_LATEST: {}}}},
)
def metrics():
    # [SAAD] No counter increment here. Prometheus scrapes this endpoint every
    # 15 seconds, so counting scrapes would drown out real traffic signal.
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/work")
def work():
    # [SAAD] Third endpoint from the optional requirement. Generates variable
    # latency so the histogram produces a real distribution rather than a flat
    # line during the Prometheus demonstration.
    start = time.time()
    time.sleep(random.uniform(0.01, 0.4))
    duration = time.time() - start
    REQUEST_LATENCY.labels(endpoint="/work").observe(duration)
    REQUEST_COUNT.labels(endpoint="/work", status="200").inc()
    return {"status": "work complete", "duration_seconds": round(duration, 3)}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))