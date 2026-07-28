from datetime import timedelta

from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from activities import fetch_hashtags, generate_tagline

BRAND = "CatNip Cola"


@workflow.defn
class SocialPostWorkflow:
    @workflow.run
    async def run(self, channel: str) -> str:
        tagline = await workflow.execute_activity(
            generate_tagline,
            BRAND,
            start_to_close_timeout=timedelta(seconds=10),
        )
        hashtags = await workflow.execute_activity(
            fetch_hashtags,
            channel,
            start_to_close_timeout=timedelta(seconds=10),
        )
        return f"{tagline} {' '.join(hashtags)}"
