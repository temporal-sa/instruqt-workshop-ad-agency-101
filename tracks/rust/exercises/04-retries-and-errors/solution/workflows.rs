use std::time::Duration;

use temporalio_common::RetryPolicy;
use temporalio_macros::{workflow, workflow_methods};
use temporalio_sdk::{ActivityOptions, WorkflowContext, WorkflowResult};

use crate::activities::PublishActivities;

#[workflow]
#[derive(Default)]
pub struct PublishWorkflow;

#[workflow_methods]
impl PublishWorkflow {
    #[run]
    pub async fn run(ctx: &mut WorkflowContext<Self>, channel: String) -> WorkflowResult<String> {
        let options = ActivityOptions::with_start_to_close_timeout(Duration::from_secs(10))
            .retry_policy(
                RetryPolicy::builder()
                    .initial_interval(Duration::from_secs(1))
                    .backoff_coefficient(2.0)
                    .maximum_interval(Duration::from_secs(10))
                    .build(),
            )
            .build();
        let placement_id = ctx
            .execute_activity(PublishActivities::publish_post, channel, options)
            .await?;
        Ok(placement_id)
    }
}
