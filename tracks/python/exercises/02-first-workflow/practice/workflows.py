from temporalio import workflow


@workflow.defn
class TaglineWorkflow:
    @workflow.run
    async def run(self, brand: str) -> str:
        workflow.logger.info("Generating tagline for %s", brand)
        # TODO: Part B — return the tagline: the brand name, a colon and a space,
        # then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
        return "TODO"
