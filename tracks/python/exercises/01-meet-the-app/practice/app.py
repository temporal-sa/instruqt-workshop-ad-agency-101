"""Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?

Run it:  uv run exercises/01-meet-the-app/practice/app.py
"""

import time

import requests

ADNET = "http://localhost:9999"
CHANNELS = ["meowta", "catstagram", "pettok"]


def validate_creative(campaign: str) -> str:
    resp = requests.post(f"{ADNET}/validate-creative", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    creative_id = resp.json()["creative_id"]
    print(f"  ✅ Creative approved: {creative_id}")
    return creative_id


def reserve_budget(campaign: str) -> str:
    resp = requests.post(f"{ADNET}/reserve-budget", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    body = resp.json()
    print(f"  💸 Budget reserved: ${body['amount']:,} ({body['reservation_id']})")
    return body["reservation_id"]


def publish_to_channel(campaign: str, channel: str) -> str:
    resp = requests.post(f"{ADNET}/publish/{channel}", json={"campaign": campaign}, timeout=5)
    resp.raise_for_status()
    placement_id = resp.json()["placement_id"]
    print(f"  📣 Live on {channel}: {placement_id}")
    return placement_id


def generate_launch_report(campaign: str, creative_id: str, reservation_id: str,
                           placements: list[str]) -> dict:
    report = {
        "campaign": campaign,
        "status": "LIVE",
        "creative_id": creative_id,
        "reservation_id": reservation_id,
        "placements": placements,
        "channels_live": len(placements),
    }
    print(f"  📊 Launch report: {report}")
    return report


def launch_campaign(campaign: str) -> dict:
    print(f"🚀 Launching campaign '{campaign}' for CatNip Cola...")
    creative_id = validate_creative(campaign)
    time.sleep(1)
    reservation_id = reserve_budget(campaign)
    time.sleep(1)
    placements = []
    for channel in CHANNELS:
        placements.append(publish_to_channel(campaign, channel))
        time.sleep(1)
    return generate_launch_report(campaign, creative_id, reservation_id, placements)


if __name__ == "__main__":
    launch_campaign("summer-splash")
