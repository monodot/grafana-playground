"""
Simulates a specific failure mode for the Grafana Terraform provider:
- POST /api/datasources (create) is allowed through
- Subsequent GET /api/datasources/... (read-back to confirm creation) fails
  with 503 for the first FAIL_COUNT attempts, then passes through
"""
from mitmproxy import http

FAIL_COUNT = 4

datasource_get_failures = 0


def request(flow: http.HTTPFlow) -> None:
    global datasource_get_failures

    path = flow.request.path
    method = flow.request.method

    is_datasource_get = method == "GET" and path.startswith("/api/datasources")

    if is_datasource_get and datasource_get_failures < FAIL_COUNT:
        datasource_get_failures += 1
        print(
            f"[inject] 503 for datasource GET {datasource_get_failures}/{FAIL_COUNT}: {path}"
        )
        flow.response = http.Response.make(
            503,
            b"Service Unavailable (injected by mitmproxy)",
            {"Content-Type": "text/plain"},
        )
    else:
        print(f"[passthrough] {method} {path}")
