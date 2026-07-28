import pytest

from services.adnet import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    return app.test_client()


def test_health_reports_chaos_on_by_default(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok", "chaos": True}


def test_chaos_toggle(client):
    assert client.post("/chaos/off").get_json() == {"chaos": False}
    assert client.get("/chaos").get_json() == {"chaos": False}
    assert client.post("/chaos/on").get_json() == {"chaos": True}


def test_tagline(client):
    resp = client.get("/tagline", query_string={"brand": "CatNip Cola"})
    assert resp.status_code == 200
    assert resp.get_json() == {"tagline": "CatNip Cola: Taste the Meow!"}


def test_trending_known_channel(client):
    resp = client.get("/trending/catstagram")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["channel"] == "catstagram"
    assert "#CatsOfCatstagram" in body["hashtags"]


def test_trending_unknown_channel_404(client):
    assert client.get("/trending/myspace").status_code == 404


def test_validate_creative_deterministic(client):
    resp = client.post("/validate-creative", json={"campaign": "summer-splash"})
    assert resp.status_code == 200
    assert resp.get_json() == {"creative_id": "creative-summer-splash", "status": "approved"}


def test_reserve_budget_deterministic(client):
    resp = client.post("/reserve-budget", json={"campaign": "summer-splash"})
    assert resp.status_code == 200
    assert resp.get_json() == {"reservation_id": "budget-summer-splash", "amount": 50000}


def test_publish_ok_channel(client):
    resp = client.post("/publish/meowta", json={"campaign": "summer-splash"})
    assert resp.status_code == 200
    assert resp.get_json() == {"placement_id": "meowta-summer-splash", "channel": "meowta"}


def test_publish_pettok_503_while_chaos_on(client):
    assert client.post("/publish/pettok", json={"campaign": "x"}).status_code == 503


def test_publish_pettok_ok_when_chaos_off(client):
    client.post("/chaos/off")
    assert client.post("/publish/pettok", json={"campaign": "x"}).status_code == 200


def test_publish_dogbook_always_403(client):
    client.post("/chaos/off")
    resp = client.post("/publish/dogbook", json={"campaign": "x"})
    assert resp.status_code == 403
    assert "banned" in resp.get_json()["error"]


def test_publish_unknown_channel_404(client):
    assert client.post("/publish/myspace", json={"campaign": "x"}).status_code == 404
