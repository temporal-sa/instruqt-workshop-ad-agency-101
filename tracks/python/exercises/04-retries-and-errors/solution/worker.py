import asyncio
from concurrent.futures import ThreadPoolExecutor

from temporalio.client import Client
from temporalio.worker import Worker

from activities import publish_post
from workflows import PublishWorkflow


async def main():
    client = await Client.connect("localhost:7233")
    with ThreadPoolExecutor(max_workers=10) as activity_executor:
        worker = Worker(
            client,
            task_queue="publish-tasks",
            workflows=[PublishWorkflow],
            activities=[publish_post],
            activity_executor=activity_executor,
        )
        print("Worker started on task queue 'publish-tasks'. Ctrl-C to stop.")
        await worker.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Worker stopped.")
