use std::time::Duration;

use serde_json::{Value, json};
use temporalio_macros::activities;
use temporalio_sdk::{
    ApplicationFailure,
    activities::{ActivityContext, ActivityError},
};

const ADNET: &str = "http://localhost:9999";

pub struct PublishActivities;

#[activities]
impl PublishActivities {
    // Activity type: "PublishActivities::publish_post"
    #[activity]
    pub async fn publish_post(
        ctx: ActivityContext,
        channel: String,
    ) -> Result<String, ActivityError> {
        println!("Publishing to {channel} (attempt {})", ctx.info().attempt);
        let response = reqwest::Client::new()
            .post(format!("{ADNET}/publish/{channel}"))
            .json(&json!({ "campaign": "summer-splash" }))
            .timeout(Duration::from_secs(5))
            .send()
            .await?;
        let status = response.status();

        // TODO: Part D — 4xx is a permanent business failure. Detect it with
        // status.is_client_error() and return a non-retryable failure:
        //
        // return Err(ActivityError::application(
        //     ApplicationFailure::builder(format!("{channel} rejected the post"))
        //         .type_name("ChannelPolicyError".to_string())
        //         .non_retryable(true)
        //         .build(),
        // ));
        if !status.is_success() {
            // 5xx and other errors stay retryable.
            return Err(
                ApplicationFailure::new(format!("{status}: {}", response.text().await?)).into(),
            );
        }
        let body: Value = response.json().await?;
        Ok(body["placement_id"].as_str().unwrap_or_default().to_owned())
    }
}
