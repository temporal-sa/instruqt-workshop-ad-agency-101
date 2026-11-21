use std::time::Duration;

use temporalio_macros::{workflow, workflow_methods};
use temporalio_sdk::{ActivityOptions, WorkflowContext, WorkflowResult};

use crate::activities::{HashtagActivities, TaglineActivities};

const BRAND: &str = "CatNip Cola";

fn activity_options() -> ActivityOptions {
    ActivityOptions::start_to_close_timeout(Duration::from_secs(10))
}

#[workflow]
#[derive(Default)]
pub struct SocialPostWorkflow;

#[workflow_methods]
impl SocialPostWorkflow {
    #[run]
    pub async fn run(ctx: &mut WorkflowContext<Self>, channel: String) -> WorkflowResult<String> {
        let tagline = ctx
            .execute_activity(
                TaglineActivities::generate_tagline,
                BRAND.to_string(),
                activity_options(),
            )
            .await?;
        let hashtags = ctx
            .execute_activity(
                HashtagActivities::fetch_hashtags,
                channel,
                activity_options(),
            )
            .await?;
        Ok(format!("{tagline} {}", hashtags.join(" ")))
    }
}
