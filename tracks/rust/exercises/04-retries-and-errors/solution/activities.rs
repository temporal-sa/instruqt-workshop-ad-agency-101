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

        if status.is_client_error() {
            // 4xx is a permanent business failure: retrying cannot fix it.
            let detail: Value = response.json().await.unwrap_or_default();
            let reason = detail["error"].as_str().unwrap_or("rejected");
            return Err(ActivityError::application(
                ApplicationFailure::builder(format!("{channel} rejected the post: {reason}"))
                    .type_name("ChannelPolicyError".to_string())
                    .non_retryable(true)
                    .build(),
            ));
        }
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
