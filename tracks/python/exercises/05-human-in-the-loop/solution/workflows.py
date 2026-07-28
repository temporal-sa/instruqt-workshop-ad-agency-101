import asyncio
from datetime import timedelta

from temporalio import workflow


@workflow.defn
class CampaignApprovalWorkflow:
    def __init__(self) -> None:
        self.approved_by: str | None = None

    @workflow.signal
    def approve(self, approver: str) -> None:
        self.approved_by = approver

    @workflow.run
    async def run(self, campaign: str, approval_deadline_seconds: int) -> dict:
        workflow.logger.info(
            "Campaign %s awaiting client approval (deadline: %ds)",
            campaign,
            approval_deadline_seconds,
        )
        try:
            await workflow.wait_condition(
                lambda: self.approved_by is not None,
                timeout=timedelta(seconds=approval_deadline_seconds),
            )
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
