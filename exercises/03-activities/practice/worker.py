import asyncio
from concurrent.futures import ThreadPoolExecutor

from temporalio.client import Client
from temporalio.worker import Worker

from activities import generate_tagline  # TODO: Part D — import fetch_hashtags here too
from workflows import SocialPostWorkflow


async def main():
    client = await Client.connect("localhost:7233")
    with ThreadPoolExecutor(max_workers=10) as activity_executor:
        worker = Worker(
            client,
            task_queue="social-tasks",
            workflows=[SocialPostWorkflow],
            activities=[generate_tagline],  # TODO: Part D — register fetch_hashtags too
            activity_executor=activity_executor,
        )
        print("Worker started on task queue 'social-tasks'. Ctrl-C to stop.")
        await worker.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Worker stopped.")
