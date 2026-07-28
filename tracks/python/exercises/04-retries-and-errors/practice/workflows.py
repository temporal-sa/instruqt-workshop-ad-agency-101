from datetime import timedelta

from temporalio import workflow
from temporalio.common import RetryPolicy  # noqa: F401  (used in Part C)

with workflow.unsafe.imports_passed_through():
    from activities import publish_post


@workflow.defn
class PublishWorkflow:
    @workflow.run
    async def run(self, channel: str) -> str:
        return await workflow.execute_activity(
            publish_post,
            channel,
            start_to_close_timeout=timedelta(seconds=10),
            # TODO: Part C — add a custom retry policy:
            # retry_policy=RetryPolicy(
            #     initial_interval=timedelta(seconds=1),
            #     backoff_coefficient=2.0,
            #     maximum_interval=timedelta(seconds=10),
            # ),
        )
