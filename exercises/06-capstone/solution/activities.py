import requests
from temporalio import activity
from temporalio.exceptions import ApplicationError

ADNET = "http://localhost:9999"


@activity.defn
def validate_creative(campaign: str) -> str:
    resp = requests.post(f"{ADNET}/validate-creative", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    return resp.json()["creative_id"]


@activity.defn
def reserve_budget(campaign: str) -> str:
    resp = requests.post(f"{ADNET}/reserve-budget", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    return resp.json()["reservation_id"]


@activity.defn
def publish_to_channel(campaign: str, channel: str) -> str:
    activity.logger.info("Publishing to %s (attempt %d)", channel, activity.info().attempt)
    resp = requests.post(f"{ADNET}/publish/{channel}", json={"campaign": campaign}, timeout=5)
    if 400 <= resp.status_code < 500:
        raise ApplicationError(
            f"{channel} rejected the campaign: {resp.json().get('error', resp.text)}",
            type="ChannelPolicyError",
            non_retryable=True,
        )
    resp.raise_for_status()
    return resp.json()["placement_id"]


@activity.defn
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
