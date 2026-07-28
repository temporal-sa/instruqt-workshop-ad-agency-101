import requests
from temporalio import activity

ADNET = "http://localhost:9999"


@activity.defn
def generate_tagline(brand: str) -> str:
    resp = requests.get(f"{ADNET}/tagline", params={"brand": brand}, timeout=5)
    resp.raise_for_status()
    return resp.json()["tagline"]


@activity.defn
def fetch_hashtags(channel: str) -> list[str]:
    resp = requests.get(f"{ADNET}/trending/{channel}", timeout=5)
    resp.raise_for_status()
    return resp.json()["hashtags"]
