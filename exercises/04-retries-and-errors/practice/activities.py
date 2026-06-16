import requests
from temporalio import activity
from temporalio.exceptions import ApplicationError  # noqa: F401  (used in Part D)

ADNET = "http://localhost:9999"


@activity.defn
def publish_post(channel: str) -> str:
    attempt = activity.info().attempt
    activity.logger.info("Publishing to %s (attempt %d)", channel, attempt)
    resp = requests.post(f"{ADNET}/publish/{channel}", json={"campaign": "summer-splash"}, timeout=5)
    # TODO: Part D — a 4xx response is a *business* failure: the channel said no,
    # and retrying will never change its mind. Detect it and fail fast. The API
    # shape (ApplicationError is already imported above):
    #
    #   if 400 <= resp.status_code < 500:
    #       raise ApplicationError(
    #           "human-readable message",    # what went wrong
    #           type="ChannelPolicyError",   # typed: visible to the workflow, the UI, and retry policies
    #           non_retryable=True,          # the opt-out — without this, Temporal retries
    #       )                                #   ApplicationError like any other exception
    resp.raise_for_status()  # 5xx raises here -> retryable by default
    return resp.json()["placement_id"]
