from fastapi.testclient import TestClient
from backend.main import app


def test_health_endpoint():
    client = TestClient(app)
    r = client.get('/health')
    assert r.status_code == 200
    data = r.json()
    assert data.get('status') == 'ok'
