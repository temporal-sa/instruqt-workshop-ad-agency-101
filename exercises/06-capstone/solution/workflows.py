from datetime import timedelta

from temporalio import workflow
from temporalio.common import RetryPolicy

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
        creative_id = await workflow.execute_activity(
            validate_creative,
            campaign,
            start_to_close_timeout=timedelta(seconds=10),
        )
        reservation_id = await workflow.execute_activity(
            reserve_budget,
            campaign,
            start_to_close_timeout=timedelta(seconds=10),
        )
        placements = []
        for channel in CHANNELS:
            placements.append(
                await workflow.execute_activity(
                    publish_to_channel,
                    args=[campaign, channel],
                    start_to_close_timeout=timedelta(seconds=10),
                    retry_policy=RetryPolicy(
                        initial_interval=timedelta(seconds=1),
                        backoff_coefficient=2.0,
                        maximum_interval=timedelta(seconds=10),
                        non_retryable_error_types=["ChannelPolicyError"],
                    ),
                )
            )
        return await workflow.execute_activity(
            generate_launch_report,
            args=[campaign, creative_id, reservation_id, placements],
            start_to_close_timeout=timedelta(seconds=10),
        )
