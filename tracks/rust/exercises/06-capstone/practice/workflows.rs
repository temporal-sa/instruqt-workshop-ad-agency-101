#![allow(dead_code, unused_imports)] // Used once you finish Part C.

use std::time::Duration;

use temporalio_common::RetryPolicy;
use temporalio_macros::{workflow, workflow_methods};
use temporalio_sdk::{ActivityOptions, ApplicationFailure, WorkflowContext, WorkflowResult};

use crate::activities::{CampaignActivities, LaunchReport};

const CHANNELS: [&str; 3] = ["meowta", "catstagram", "pettok"];

#[workflow]
#[derive(Default)]
pub struct CampaignWorkflow;

#[workflow_methods]
impl CampaignWorkflow {
    #[run]
    pub async fn run(
        ctx: &mut WorkflowContext<Self>,
        campaign: String,
    ) -> WorkflowResult<LaunchReport> {
        // This used to be launch_campaign() in app.rs:
        //
        // let creative_id = validate_creative(campaign).await?;
        // let reservation_id = reserve_budget(campaign).await?;
        // let mut placements = Vec::new();
        // for channel in CHANNELS {
        //     placements.push(publish_to_channel(campaign, channel).await?);
        // }
        // generate_launch_report(campaign, creative_id, reservation_id, placements)
        //
        // TODO: Part C — rebuild that sequence with ctx.execute_activity(...).
        // Give every Activity a 10-second start-to-close timeout. Give
        // publish_to_channel a RetryPolicy whose non_retryable_error_types
        // includes "ChannelPolicyError". Pass multiple arguments as a tuple:
        //
        // ctx.execute_activity(
        //     CampaignActivities::publish_to_channel,
        //     (campaign.clone(), channel.to_string()),
        //     options,
        // )
        // .await?
        let _ = (ctx, campaign, CHANNELS);
        Err(
            ApplicationFailure::non_retryable("Part C: CampaignWorkflow is not implemented yet")
                .into(),
        )
    }
}
