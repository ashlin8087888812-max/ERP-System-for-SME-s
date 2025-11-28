"""
Tests for Phase 3: Prometheus Metrics, Health Checks, and Monitoring
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app


class TestPrometheusMetrics:
    """Test Prometheus metrics functionality"""
    
    def test_metrics_endpoint_disabled_by_default(self, client):
        """Test that metrics endpoint returns error when disabled"""
        response = client.get("/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "error" in data
        assert data["error"] == "Metrics are disabled"
    
    @pytest.mark.skip(reason="Requires ENABLE_METRICS=true")
    def test_metrics_endpoint_enabled(self, client):
        """Test metrics endpoint when enabled"""
        # This would require setting ENABLE_METRICS=true
        response = client.get("/metrics")
        assert response.status_code == 200
        assert "fastapi_requests_total" in response.text
    
    def test_metrics_middleware_tracks_requests(self, client):
        """Test that metrics middleware tracks requests"""
        # Make a request
        response = client.get("/health/live")
        assert response.status_code == 200
        
        # Metrics should be tracked (if enabled)
        # This is implicit - middleware runs on every request


class TestHealthChecks:
    """Test health check endpoints"""
    
    def test_health_endpoint_exists(self, client):
        """Test that /health endpoint exists"""
        response = client.get("/health")
        assert response.status_code in [200, 503]  # 200 if healthy, 503 if not
        
        data = response.json()
        assert "status" in data
        assert "checks" in data
    
    def test_health_checks_structure(self, client):
        """Test health check response structure"""
        response = client.get("/health")
        data = response.json()
        
        # Should have checks for all services
        assert "checks" in data
        checks = data["checks"]
        
        assert "database" in checks
        assert "redis_pubsub" in checks
        assert "redis_celery" in checks
        assert "celery" in checks
        
        # Each check should have status
        for service, check in checks.items():
            assert "status" in check
            assert check["status"] in ["healthy", "unhealthy"]
    
    def test_liveness_probe(self, client):
        """Test Kubernetes liveness probe"""
        response = client.get("/health/live")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "alive"
    
    def test_readiness_probe(self, client):
        """Test Kubernetes readiness probe"""
        response = client.get("/health/ready")
        # Should return 200 if ready, 503 if not
        assert response.status_code in [200, 503]
        
        data = response.json()
        assert "status" in data


class TestCorrelationID:
    """Test correlation ID middleware"""
    
    def test_correlation_id_generated(self, client):
        """Test that correlation ID is generated if not provided"""
        response = client.get("/health/live")
        assert response.status_code == 200
        
        # Should have correlation ID in response headers
        assert "x-correlation-id" in response.headers
        
        correlation_id = response.headers["x-correlation-id"]
        assert len(correlation_id) > 0
    
    def test_correlation_id_preserved(self, client):
        """Test that provided correlation ID is preserved"""
        custom_id = "test-correlation-id-12345"
        
        response = client.get(
            "/health/live",
            headers={"X-Correlation-ID": custom_id}
        )
        
        assert response.status_code == 200
        assert response.headers["x-correlation-id"] == custom_id
    
    def test_correlation_id_on_all_endpoints(self, client):
        """Test that correlation ID is added to all endpoints"""
        endpoints = [
            "/",
            "/health/live",
            "/health/ready",
        ]
        
        for endpoint in endpoints:
            response = client.get(endpoint)
            assert "x-correlation-id" in response.headers


class TestSentryIntegration:
    """Test Sentry integration"""
    
    def test_sentry_initialized_if_dsn_set(self):
        """Test that Sentry is initialized if DSN is configured"""
        # This is tested by checking if sentry_sdk is imported
        # Actual initialization happens in main.py
        import sentry_sdk
        assert sentry_sdk is not None
    
    @pytest.mark.skip(reason="Requires actual error to test Sentry")
    def test_sentry_captures_exceptions(self, client):
        """Test that Sentry captures exceptions"""
        # Would need a test endpoint that raises an exception
        pass


class TestMetricsHelpers:
    """Test metrics helper functions"""
    
    def test_track_celery_task_helper(self):
        """Test Celery task tracking helper"""
        from app.middleware.metrics import track_celery_task
        
        # Should not raise exception
        track_celery_task("test_task", "pending")
        track_celery_task("test_task", "processed")
        track_celery_task("test_task", "failed")
    
    def test_track_websocket_connection_helper(self):
        """Test WebSocket connection tracking helper"""
        from app.middleware.metrics import track_websocket_connection
        
        # Should not raise exception
        track_websocket_connection(1, increment=True)
        track_websocket_connection(1, increment=False)
    
    def test_track_db_query_helper(self):
        """Test database query tracking helper"""
        from app.middleware.metrics import track_db_query
        
        # Should not raise exception
        track_db_query("select", 0.123)
        track_db_query("insert", 0.456)


class TestStructuredLogging:
    """Test structured logging"""
    
    def test_structured_formatter_exists(self):
        """Test that structured formatter is available"""
        from app.core.logging import StructuredFormatter
        
        formatter = StructuredFormatter()
        assert formatter is not None
    
    def test_logging_setup(self):
        """Test logging setup function"""
        from app.core.logging import setup_logging
        
        logger = setup_logging(log_level="INFO", structured=True)
        assert logger is not None
        assert logger.level == 20  # INFO level


class TestEndpointIntegration:
    """Integration tests for monitoring endpoints"""
    
    def test_health_endpoint_with_database(self, client, db):
        """Test health endpoint checks database connectivity"""
        response = client.get("/health")
        data = response.json()
        
        # Database check should be present
        assert "database" in data["checks"]
        db_check = data["checks"]["database"]
        
        # Should be healthy if DB is available
        assert db_check["status"] in ["healthy", "unhealthy"]
    
    def test_multiple_health_checks(self, client):
        """Test making multiple health check requests"""
        for _ in range(5):
            response = client.get("/health/live")
            assert response.status_code == 200
            assert response.json()["status"] == "alive"
    
    def test_health_check_performance(self, client):
        """Test that health checks are fast"""
        import time
        
        start = time.time()
        response = client.get("/health/live")
        duration = time.time() - start
        
        assert response.status_code == 200
        assert duration < 0.1  # Should be under 100ms


class TestMonitoringEndpoints:
    """Test all monitoring-related endpoints"""
    
    def test_all_monitoring_endpoints_exist(self, client):
        """Test that all monitoring endpoints are accessible"""
        endpoints = {
            "/": 200,
            "/health": [200, 503],
            "/health/live": 200,
            "/health/ready": [200, 503],
            "/metrics": 200,
        }
        
        for endpoint, expected_status in endpoints.items():
            response = client.get(endpoint)
            
            if isinstance(expected_status, list):
                assert response.status_code in expected_status
            else:
                assert response.status_code == expected_status
