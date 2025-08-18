# Network Latency Monitor

A simple FastAPI application that measures TCP connect latency to target servers and exposes the metrics via HTTP endpoints.

## 🚀 Features

- **Continuous Monitoring**: Measures latency every 5 seconds
- **HTTP Endpoints**: JSON data at `/latency` and Prometheus metrics at `/metrics`
- **Health Checks**: Built-in health monitoring at `/health`
- **Docker Ready**: Containerized for easy deployment
- **CI/CD**: Automated builds with GitHub Actions

## 📊 Endpoints

- `GET /` - Service information and available endpoints
- `GET /latency` - Latest latency measurement in JSON format
- `GET /metrics` - Prometheus-compatible metrics
- `GET /health` - Health check status

## 🛠️ Local Development

### Prerequisites
- Python 3.11+
- Docker (optional)

### Run with Python
```bash
# Install dependencies
pip install -r requirements.txt

# Set target (optional)
export TARGET_HOST=google.com
export TARGET_PORT=443

# Run the application
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Run with Docker
```bash
# Build image
docker build -t latency-monitor .

# Run container
docker run -p 8000:8000 \
  -e TARGET_HOST=google.com \
  -e TARGET_PORT=443 \
  latency-monitor
```

## 🌐 Usage

Visit `http://localhost:8000/latency` to see current latency data:

```json
{
  "target_host": "google.com",
  "target_port": 443,
  "check_interval_seconds": 5.0,
  "connect_timeout_seconds": 3.0,
  "latest_latency_ms": 24.5,
  "last_success_unix": 1704067200.145,
  "last_error_message": null,
  "last_error_unix": null
}
```

## ⚙️ Configuration

Configure via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET_HOST` | *Required* | Hostname/IP to measure latency to |
| `TARGET_PORT` | `80` | Port to connect to |
| `CHECK_INTERVAL_SECONDS` | `5` | How often to measure latency |
| `CONNECT_TIMEOUT_SECONDS` | `3` | Connection timeout |
| `PORT` | `8000` | HTTP server port |

**Note**: `TARGET_HOST` is required and must be set when running the container.

## 🔄 CI/CD

This project uses GitHub Actions for automated building and publishing:

- **Triggers**: Push to `main`/`develop` branches, PRs to `main`
- **Builds**: Multi-architecture Docker images (AMD64, ARM64)
- **Publishes**: `lhdung/latency-app:${{ github.sha }}` and tagged versions
- **Security**: Trivy vulnerability scanning

### Docker Hub Images

Images are published to: `docker.io/lhdung/latency-app`

Available tags:
- `latest` - Latest main branch build
- `main-<sha>` - Specific commit from main branch
- `<sha>` - Any commit SHA

### Pull and Run

```bash
# Pull latest image
docker pull lhdung/latency-app:latest

# Run with custom target
docker run -p 8000:8000 \
  -e TARGET_HOST=1.1.1.1 \
  -e TARGET_PORT=53 \
  lhdung/latency-app:latest
```

## 🔧 Setup Secrets

To enable automatic publishing, add these secrets to your GitHub repository:

1. Go to Repository → Settings → Secrets and Variables → Actions
2. Add secrets:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub password or access token

## 📈 Monitoring

The application provides Prometheus-compatible metrics for monitoring:

```
# HELP network_latency_ms Latest measured TCP connect latency in milliseconds
# TYPE network_latency_ms gauge
network_latency_ms{target_host="google.com",target_port="443"} 24.5

# HELP network_latency_success_total Number of successful latency measurements
# TYPE network_latency_success_total counter
network_latency_success_total{target_host="google.com",target_port="443"} 142
```

## 🏗️ Architecture

The application uses a multi-threaded design:
- **Background Worker**: Continuously measures latency every 5 seconds
- **HTTP Server**: Serves cached measurements instantly via REST API
- **Thread-Safe Storage**: Safely shares data between worker and API threads

This ensures fast API responses (no waiting for measurements) while maintaining fresh data.

## 📝 License

MIT License - see LICENSE file for details.
