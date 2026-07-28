from temporalio import workflow


@workflow.defn
class TaglineWorkflow:
    @workflow.run
    async def run(self, brand: str) -> str:
        workflow.logger.info("Generating tagline for %s", brand)
        return f"{brand}: Taste the Meow!"
