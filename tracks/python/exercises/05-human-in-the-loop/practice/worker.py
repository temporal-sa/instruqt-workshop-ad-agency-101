import asyncio

from temporalio.client import Client
from temporalio.worker import Worker

from workflows import CampaignApprovalWorkflow


async def main():
    client = await Client.connect("localhost:7233")
    worker = Worker(
        client,
        task_queue="approval-tasks",
        workflows=[CampaignApprovalWorkflow],
    )
    print("Worker started on task queue 'approval-tasks'. Ctrl-C to stop.")
    await worker.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Worker stopped.")
