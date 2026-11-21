#![allow(unused_imports)] // Duration and select are used once you finish Part C.

use std::time::Duration;

use serde::{Deserialize, Serialize};
use temporalio_common::data_converters::MultiArgs2;
use temporalio_macros::{workflow, workflow_methods};
use temporalio_sdk::{SyncWorkflowContext, WorkflowContext, WorkflowResult, workflows::select};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApprovalReport {
    pub campaign: String,
    pub status: String, // "APPROVED" or "EXPIRED"
    pub approved_by: Option<String>,
    pub next_step: String,
}

#[workflow]
#[derive(Default)]
pub struct CampaignApprovalWorkflow {
    approved_by: Option<String>,
}

#[workflow_methods]
impl CampaignApprovalWorkflow {
    // MultiArgs2 accepts two separate inputs: --input '"summer-splash"' --input '120'
    #[run]
    pub async fn run(
        ctx: &mut WorkflowContext<Self>,
        input: MultiArgs2<String, u64>,
    ) -> WorkflowResult<ApprovalReport> {
        let MultiArgs2(campaign, approval_deadline_seconds) = input;
        // TODO: Part C — wait durably until the Signal sets approved_by, or
        // until a timer for the deadline fires, whichever comes first:
        //
        // let received = select! {
        //     result = ctx.wait_condition(|state| state.approved_by.is_some()) => {
        //         result?;
        //         true
        //     }
        //     _ = ctx.timer(Duration::from_secs(approval_deadline_seconds)) => false,
        // };
        let _ = approval_deadline_seconds;
        let received = false;

        if !received {
            return Ok(ApprovalReport {
                campaign,
                status: "EXPIRED".to_string(),
                approved_by: None,
                next_step: "escalate to the account exec (by fax, probably)".to_string(),
            });
        }
        Ok(ApprovalReport {
            campaign,
            status: "APPROVED".to_string(),
            approved_by: ctx.state(|state| state.approved_by.clone()),
            next_step: "cleared for launch".to_string(),
        })
    }

    // Signal name: "approve"
    #[signal]
    pub fn approve(&mut self, _ctx: &mut SyncWorkflowContext<Self>, approver: String) {
        // TODO: Part B — record who approved so the wait in run() can see it.
        let _ = approver;
    }
}
