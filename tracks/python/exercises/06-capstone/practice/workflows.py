from datetime import timedelta  # noqa: F401  (used in Part C)

from temporalio import workflow
from temporalio.common import RetryPolicy  # noqa: F401  (used in Part C)

with workflow.unsafe.imports_passed_through():
    from activities import (
        generate_launch_report,
        publish_to_channel,
        reserve_budget,
        validate_creative,
    )

CHANNELS = ["meowta", "catstagram", "pettok"]


@workflow.defn
class CampaignWorkflow:
    @workflow.run
    async def run(self, campaign: str) -> dict:
        # This used to be launch_campaign() in app.py:
        #
        #   creative_id = validate_creative(campaign)
        #   reservation_id = reserve_budget(campaign)
        #   placements = []
        #   for channel in CHANNELS:
        #       placements.append(publish_to_channel(campaign, channel))
        #   return generate_launch_report(campaign, creative_id, reservation_id, placements)
        #
        # TODO: Part C — rebuild it durably: replace each direct call with
        # await workflow.execute_activity(...). Every call needs a
        # start_to_close_timeout; give publish_to_channel a RetryPolicy with
        # non_retryable_error_types=["ChannelPolicyError"].
        # Multi-argument activities take args=[...], e.g.
        #   workflow.execute_activity(publish_to_channel, args=[campaign, channel], ...)
        raise NotImplementedError("Part C")
