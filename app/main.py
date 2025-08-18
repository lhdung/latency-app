import os
import time
import socket
import threading
from typing import Optional, Dict, Any

from fastapi import FastAPI
from fastapi.responses import JSONResponse, PlainTextResponse

from prometheus_client import Gauge, Counter, Histogram, CollectorRegistry, generate_latest, CONTENT_TYPE_LATEST


# Configuration via environment variables - TARGET_HOST must be provided
TARGET_HOST = os.getenv("TARGET_HOST")
TARGET_PORT = int(os.getenv("TARGET_PORT", "80"))

# Validate required configuration
if not TARGET_HOST:
    raise ValueError("TARGET_HOST environment variable is required")
CHECK_INTERVAL_SECONDS = float(os.getenv("CHECK_INTERVAL_SECONDS", "5"))
CONNECT_TIMEOUT_SECONDS = float(os.getenv("CONNECT_TIMEOUT_SECONDS", "3"))


# Prometheus metrics registry and metrics
registry = CollectorRegistry()
latency_gauge_ms = Gauge(
    "network_latency_ms",
    "Latest measured TCP connect latency in milliseconds",
    ["target_host", "target_port"],
    registry=registry,
)
success_counter = Counter(
    "network_latency_success_total",
    "Number of successful latency measurements",
    ["target_host", "target_port"],
    registry=registry,
)
failure_counter = Counter(
    "network_latency_failure_total",
    "Number of failed latency measurements",
    ["target_host", "target_port"],
    registry=registry,
)
latency_hist_ms = Histogram(
    "network_latency_histogram_ms",
    "Histogram of observed TCP connect latency in ms",
    ["target_host", "target_port"],
    # Buckets chosen for typical internet latencies
    buckets=(1, 2, 5, 10, 20, 50, 100, 200, 400, 800, 1600, 3200),
    registry=registry,
)


class LatencyStore:
    """Thread-safe store for the latest measurement and metadata."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._latest_latency_ms: Optional[float] = None
        self._last_success_unix: Optional[float] = None
        self._last_error_message: Optional[str] = None
        self._last_error_unix: Optional[float] = None

    def update_success(self, latency_ms: float) -> None:
        with self._lock:
            self._latest_latency_ms = latency_ms
            self._last_success_unix = time.time()
            self._last_error_message = None
            self._last_error_unix = None

    def update_failure(self, error_message: str) -> None:
        with self._lock:
            self._last_error_message = error_message
            self._last_error_unix = time.time()

    def snapshot(self) -> Dict[str, Any]:
        with self._lock:
            return {
                "latest_latency_ms": self._latest_latency_ms,
                "last_success_unix": self._last_success_unix,
                "last_error_message": self._last_error_message,
                "last_error_unix": self._last_error_unix,
            }


latency_store = LatencyStore()


def measure_tcp_connect_latency_ms(hostname: str, port: int, timeout_seconds: float) -> float:
    """Measure TCP connect latency (ms) to the given host:port.

    Returns the latency in milliseconds or raises an exception on failure.
    """
    start = time.perf_counter()
    with socket.create_connection((hostname, port), timeout=timeout_seconds):
        pass
    end = time.perf_counter()
    return (end - start) * 1000.0


def measurement_worker() -> None:
    labels = {"target_host": TARGET_HOST, "target_port": str(TARGET_PORT)}
    while True:
        try:
            latency_ms = measure_tcp_connect_latency_ms(
                TARGET_HOST, TARGET_PORT, CONNECT_TIMEOUT_SECONDS
            )
            latency_store.update_success(latency_ms)
            latency_gauge_ms.labels(**labels).set(latency_ms)
            latency_hist_ms.labels(**labels).observe(latency_ms)
            success_counter.labels(**labels).inc()
        except Exception as exc:  # noqa: BLE001 - we want to surface any failure
            msg = f"{type(exc).__name__}: {exc}"
            latency_store.update_failure(msg)
            failure_counter.labels(**labels).inc()
        finally:
            time.sleep(CHECK_INTERVAL_SECONDS)


app = FastAPI(title="Network Latency Monitor", version="1.0.0")


@app.on_event("startup")
def start_background_worker() -> None:
    thread = threading.Thread(target=measurement_worker, name="latency-worker", daemon=True)
    thread.start()


@app.get("/")
def root():
    return {
        "service": "Network Latency Monitor",
        "version": "1.0.0",
        "endpoints": {
            "latency": "/latency",
            "metrics": "/metrics",
            "health": "/health"
        },
        "target": f"{TARGET_HOST}:{TARGET_PORT}"
    }


@app.get("/latency")
def get_latency() -> JSONResponse:
    data = latency_store.snapshot()
    body = {
        "target_host": TARGET_HOST,
        "target_port": TARGET_PORT,
        "check_interval_seconds": CHECK_INTERVAL_SECONDS,
        "connect_timeout_seconds": CONNECT_TIMEOUT_SECONDS,
        **data,
    }
    return JSONResponse(content=body)


@app.get("/metrics")
def metrics() -> PlainTextResponse:
    output = generate_latest(registry)
    return PlainTextResponse(content=output, media_type=CONTENT_TYPE_LATEST)


@app.get("/health")
def health():
    data = latency_store.snapshot()
    is_healthy = (
        data["latest_latency_ms"] is not None and 
        data["last_success_unix"] is not None and
        (time.time() - data["last_success_unix"]) < 30  # Success within last 30 seconds
    )
    
    return {
        "status": "healthy" if is_healthy else "unhealthy",
        "target": f"{TARGET_HOST}:{TARGET_PORT}",
        "last_successful_measurement": data["last_success_unix"],
        "last_error": data["last_error_message"]
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8000")),
        reload=False,
        log_level="info",
    )
