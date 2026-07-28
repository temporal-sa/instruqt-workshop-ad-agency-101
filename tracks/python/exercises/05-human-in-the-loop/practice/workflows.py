import asyncio
from datetime import timedelta

from temporalio import workflow


@workflow.defn
class CampaignApprovalWorkflow:
    def __init__(self) -> None:
        self.approved_by: str | None = None

    @workflow.signal
    def approve(self, approver: str) -> None:
        # TODO: Part B — record who approved. Signal handlers are how the
        # outside world updates a *running* workflow's state: store the
        # approver's name on self so the waiting code below can see it.
        pass

    @workflow.run
    async def run(self, campaign: str, approval_deadline_seconds: int) -> dict:
        workflow.logger.info(
            "Campaign %s awaiting client approval (deadline: %ds)",
            campaign,
            approval_deadline_seconds,
        )
        try:
            # TODO: Part C — wait (durably!) for the approval, with a deadline:
            # await workflow.wait_condition(
            #     lambda: <approval has arrived>,
            #     timeout=timedelta(seconds=approval_deadline_seconds),
            # )
            # wait_condition parks the workflow until the lambda turns true —
            # however long that takes. The timeout is a DURABLE TIMER on the
            # server: it raises asyncio.TimeoutError here when it fires.
            raise NotImplementedError("Part C")
        except asyncio.TimeoutError:
            # Nobody approved in time -> the expiry branch.
            workflow.logger.info("Approval window expired for %s", campaign)
            return {
                "campaign": campaign,
                "status": "EXPIRED",
                "approved_by": None,
                "next_step": "escalate to the account exec (by fax, probably)",
            }
        # The signal arrived in time -> the approved branch.
        return {
            "campaign": campaign,
            "status": "APPROVED",
            "approved_by": self.approved_by,
            "next_step": "cleared for launch",
        }
