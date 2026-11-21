use std::time::Duration;

use temporalio_common::RetryPolicy;
use temporalio_macros::{workflow, workflow_methods};
use temporalio_sdk::{ActivityOptions, WorkflowContext, WorkflowResult};

use crate::activities::{CampaignActivities, LaunchReport};

const CHANNELS: [&str; 3] = ["meowta", "catstagram", "pettok"];

fn default_options() -> ActivityOptions {
    ActivityOptions::start_to_close_timeout(Duration::from_secs(10))
}

fn publishing_options() -> ActivityOptions {
    ActivityOptions::with_start_to_close_timeout(Duration::from_secs(10))
        .retry_policy(
            RetryPolicy::builder()
                .initial_interval(Duration::from_secs(1))
                .backoff_coefficient(2.0)
                .maximum_interval(Duration::from_secs(10))
                .non_retryable_error_types(["ChannelPolicyError"])
                .build(),
        )
        .build()
}

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
        let creative_id = ctx
            .execute_activity(
                CampaignActivities::validate_creative,
                campaign.clone(),
                default_options(),
            )
            .await?;
        let reservation_id = ctx
            .execute_activity(
                CampaignActivities::reserve_budget,
                campaign.clone(),
                default_options(),
            )
            .await?;

        let mut placements = Vec::new();
        for channel in CHANNELS {
            placements.push(
                ctx.execute_activity(
                    CampaignActivities::publish_to_channel,
                    (campaign.clone(), channel.to_string()),
                    publishing_options(),
                )
                .await?,
            );
        }

        let report = ctx
            .execute_activity(
                CampaignActivities::generate_launch_report,
                (campaign, creative_id, reservation_id, placements),
                default_options(),
            )
            .await?;
        Ok(report)
    }
}
