import requests
from temporalio import activity

ADNET = "http://localhost:9999"


# The worked example: an activity is a plain function with a decorator.
# Activities are where ALL fallible, non-deterministic work lives — network
# calls, disk, anything that can fail. Temporal times them out and retries
# them; your workflow just awaits the result.
@activity.defn
def generate_tagline(brand: str) -> str:
    resp = requests.get(f"{ADNET}/tagline", params={"brand": brand}, timeout=5)
    resp.raise_for_status()
    return resp.json()["tagline"]


# TODO: Part B — write the fetch_hashtags activity.
# It takes a channel name (str) and returns the list of trending hashtags (list[str]).
# AdNet endpoint:  GET http://localhost:9999/trending/<channel>
# The response body looks like: {"channel": "catstagram", "hashtags": ["#...", "#..."]}
# Model it on generate_tagline above — and don't forget the @activity.defn decorator.
