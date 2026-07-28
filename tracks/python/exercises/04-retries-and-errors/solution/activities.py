import requests
from temporalio import activity
from temporalio.exceptions import ApplicationError

ADNET = "http://localhost:9999"


@activity.defn
def publish_post(channel: str) -> str:
    attempt = activity.info().attempt
    activity.logger.info("Publishing to %s (attempt %d)", channel, attempt)
    resp = requests.post(f"{ADNET}/publish/{channel}", json={"campaign": "summer-splash"}, timeout=5)
    if 400 <= resp.status_code < 500:
        # A 4xx is the ad network saying "no, and asking again won't help."
        # non_retryable=True tells Temporal not to waste retries on it.
        raise ApplicationError(
            f"{channel} rejected the post: {resp.json().get('error', resp.text)}",
            type="ChannelPolicyError",
            non_retryable=True,
        )
    resp.raise_for_status()  # 5xx raises here -> retryable by default
    return resp.json()["placement_id"]
