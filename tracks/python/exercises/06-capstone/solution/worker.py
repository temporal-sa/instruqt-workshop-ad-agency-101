import asyncio
from concurrent.futures import ThreadPoolExecutor

from temporalio.client import Client
from temporalio.worker import Worker

from activities import (
    generate_launch_report,
    publish_to_channel,
    reserve_budget,
    validate_creative,
)
from workflows import CampaignWorkflow


async def main():
    client = await Client.connect("localhost:7233")
    with ThreadPoolExecutor(max_workers=10) as activity_executor:
        worker = Worker(
            client,
            task_queue="campaign-tasks",
            workflows=[CampaignWorkflow],
            activities=[validate_creative, reserve_budget, publish_to_channel, generate_launch_report],
            activity_executor=activity_executor,
        )
        print("Worker started on task queue 'campaign-tasks'. Ctrl-C to stop.")
        await worker.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Worker stopped.")
