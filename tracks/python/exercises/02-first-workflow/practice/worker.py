import asyncio

from temporalio.client import Client
from temporalio.worker import Worker

from workflows import TaglineWorkflow


async def main():
    client = await Client.connect("localhost:7233")
    worker = Worker(
        client,
        task_queue="TODO",  # TODO: Part C — the starter command targets the task queue "tagline-tasks"
        workflows=[TaglineWorkflow],
    )
    print("Worker started on task queue 'tagline-tasks'. Ctrl-C to stop.")
    await worker.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Worker stopped.")
