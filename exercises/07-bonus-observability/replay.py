"""Replay the capstone's recorded history against YOUR workflow code.

This is how Temporal teams verify a workflow code change is compatible with
executions that are already running: replay real histories against the new
code and see whether the SDK detects a divergence (a "non-determinism error").

First export the history:
  temporal workflow show -w campaign-summer-splash -o json > exercises/07-bonus-observability/history.json
Then:
  uv run exercises/07-bonus-observability/replay.py
"""

import asyncio
import sys
from pathlib import Path

from temporalio.client import WorkflowHistory
from temporalio.worker import Replayer

# Replay against the code YOU wrote in the capstone.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "06-capstone" / "practice"))
from workflows import CampaignWorkflow  # noqa: E402


async def main():
    history_path = Path(__file__).resolve().parent / "history.json"
    if not history_path.exists():
        sys.exit(
            "history.json not found. Export it first:\n"
            "  temporal workflow show -w campaign-summer-splash -o json "
            "> exercises/07-bonus-observability/history.json"
        )
    replayer = Replayer(workflows=[CampaignWorkflow])
    await replayer.replay_workflow(
        WorkflowHistory.from_json("campaign-summer-splash", history_path.read_text())
    )
    print("Replay OK: your workflow code is compatible with the recorded history.")


if __name__ == "__main__":
    asyncio.run(main())
