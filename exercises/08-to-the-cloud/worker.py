"""The same worker you ran all workshop — pointed at Temporal Cloud.

Notice what changed compared to exercises/02-first-workflow/solution/worker.py:
the Client.connect() call. Nothing else. Workflow code, task queues, CLI
commands — all identical. That's the dev-server-to-production story.
"""

import asyncio
import os
import sys

from temporalio.client import Client
from temporalio.worker import Worker

from workflows import TaglineWorkflow

REQUIRED = ("TEMPORAL_ADDRESS", "TEMPORAL_NAMESPACE", "TEMPORAL_API_KEY")


async def main():
    missing = [k for k in REQUIRED if not os.environ.get(k)]
    if missing:
        sys.exit(f"Set {', '.join(missing)} first — see the README in this directory.")

    client = await Client.connect(
        os.environ["TEMPORAL_ADDRESS"],        # regional endpoint, e.g. us-east-1.aws.api.temporal.io:7233
        namespace=os.environ["TEMPORAL_NAMESPACE"],  # <namespace>.<account-id>
        api_key=os.environ["TEMPORAL_API_KEY"],
        tls=True,                              # Cloud always speaks TLS
    )
    worker = Worker(
        client,
        task_queue="tagline-tasks",
        workflows=[TaglineWorkflow],
    )
    print(f"Worker connected to {os.environ['TEMPORAL_NAMESPACE']} on Temporal Cloud. Ctrl-C to stop.")
    await worker.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Worker stopped.")
