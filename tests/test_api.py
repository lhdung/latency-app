"""Simple API tests for latency monitoring app"""
import os
from fastapi.testclient import TestClient
from unittest.mock import patch

os.environ["TARGET_HOST"] = "google.com"
os.environ["TARGET_PORT"] = "80"

# Create test client once
with patch("app.main.threading.Thread"):  # Mock background thread
    from app.main import app
    client = TestClient(app)

def test_root_endpoint():
    """Test GET / - service info"""
    response = client.get("/")
    assert response.status_code == 200
    
    data = response.json()
    assert data["service"] == "Network Latency Monitor"
    assert data["target"] == "google.com:80"

def test_latency_endpoint():
    """Test GET /latency - measurement data"""
    response = client.get("/latency")
    assert response.status_code == 200
    
    data = response.json()
    assert data["target_host"] == "google.com"
    assert data["target_port"] == 80

def test_health_endpoint():
    """Test GET /health - health check"""
    response = client.get("/health")
    assert response.status_code == 200
    
    data = response.json()
    assert "status" in data
    assert data["target"] == "google.com:80"

def test_metrics_endpoint():
    """Test GET /metrics - Prometheus metrics"""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "text/plain" in response.headers["content-type"]

def test_404_endpoint():
    """Test 404 for non-existent endpoint"""
    response = client.get("/nonexistent")
    assert response.status_code == 404
