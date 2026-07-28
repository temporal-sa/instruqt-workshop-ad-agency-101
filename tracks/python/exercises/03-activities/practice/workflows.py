from datetime import timedelta

from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from activities import generate_tagline  # TODO: Part C — import fetch_hashtags here too

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
        # TODO: Part C — execute your fetch_hashtags activity for `channel`
        # (use workflow.execute_activity with a start_to_close_timeout, like above)
        hashtags: list[str] = []
        return f"{tagline} {' '.join(hashtags)}"
