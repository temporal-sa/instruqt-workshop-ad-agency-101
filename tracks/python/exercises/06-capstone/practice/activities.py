# These are the same four functions from exercises/01-meet-the-app/practice/app.py
# (prints removed). Right now they're plain Python functions.
#
# TODO: Part B — make each one an Activity by adding the @activity.defn decorator.
# TODO: Part D — in publish_to_channel, treat 4xx as a business failure:
#   raise ApplicationError(..., type="ChannelPolicyError", non_retryable=True)
#   (exactly like exercise 04 — mind the comparison direction, 400 <= not
#   400 >=, and keep the raise INSIDE the if, or successes will raise too)

import requests
from temporalio import activity  # noqa: F401  (used in Part B)
from temporalio.exceptions import ApplicationError  # noqa: F401  (used in Part D)

ADNET = "http://localhost:9999"


def validate_creative(campaign: str) -> str:
    resp = requests.post(f"{ADNET}/validate-creative", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    return resp.json()["creative_id"]


def reserve_budget(campaign: str) -> str:
    resp = requests.post(f"{ADNET}/reserve-budget", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    return resp.json()["reservation_id"]


def publish_to_channel(campaign: str, channel: str) -> str:
    resp = requests.post(f"{ADNET}/publish/{channel}", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    return resp.json()["placement_id"]


def generate_launch_report(campaign: str, creative_id: str, reservation_id: str,
                           placements: list[str]) -> dict:
    return {
        "campaign": campaign,
        "status": "LIVE",
        "creative_id": creative_id,
        "reservation_id": reservation_id,
        "placements": placements,
        "channels_live": len(placements),
    }
