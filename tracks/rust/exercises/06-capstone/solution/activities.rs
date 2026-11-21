use std::time::Duration;

use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use temporalio_macros::activities;
use temporalio_sdk::{
    ApplicationFailure,
    activities::{ActivityContext, ActivityError},
};

const ADNET: &str = "http://localhost:9999";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LaunchReport {
    pub campaign: String,
    pub status: String,
    pub creative_id: String,
    pub reservation_id: String,
    pub placements: Vec<String>,
    pub channels_live: usize,
}

async fn post_json(path: &str, body: Value) -> Result<(reqwest::StatusCode, Value), ActivityError> {
    let response = reqwest::Client::new()
        .post(format!("{ADNET}{path}"))
        .json(&body)
        .timeout(Duration::from_secs(5))
        .send()
        .await?;
    let status = response.status();
    let parsed: Value = response.json().await.unwrap_or_default();
    Ok((status, parsed))
}

fn http_error(status: reqwest::StatusCode, body: &Value) -> ActivityError {
    ApplicationFailure::new(format!("{status}: {body}")).into()
}

fn field(body: &Value, name: &str) -> String {
    body[name].as_str().unwrap_or_default().to_owned()
}

// These are the same four operations from exercise 1. With #[activities],
// each #[activity] method becomes an Activity named
// "CampaignActivities::<method name>".
pub struct CampaignActivities;

#[activities]
impl CampaignActivities {
    #[activity]
    pub async fn validate_creative(
        _ctx: ActivityContext,
        campaign: String,
    ) -> Result<String, ActivityError> {
        let (status, body) =
            post_json("/validate-creative", json!({ "campaign": campaign })).await?;
        if !status.is_success() {
            return Err(http_error(status, &body));
        }
        Ok(field(&body, "creative_id"))
    }

    #[activity]
    pub async fn reserve_budget(
        _ctx: ActivityContext,
        campaign: String,
    ) -> Result<String, ActivityError> {
        let (status, body) = post_json("/reserve-budget", json!({ "campaign": campaign })).await?;
        if !status.is_success() {
            return Err(http_error(status, &body));
        }
        Ok(field(&body, "reservation_id"))
    }

    #[activity]
    pub async fn publish_to_channel(
        ctx: ActivityContext,
        campaign: String,
        channel: String,
    ) -> Result<String, ActivityError> {
        println!("Publishing to {channel} (attempt {})", ctx.info().attempt);
        let (status, body) = post_json(
            &format!("/publish/{channel}"),
            json!({ "campaign": campaign }),
        )
        .await?;
        if status.is_client_error() {
            let reason = body["error"].as_str().unwrap_or("rejected");
            return Err(ActivityError::application(
                ApplicationFailure::builder(format!("{channel} rejected the campaign: {reason}"))
                    .type_name("ChannelPolicyError".to_string())
                    .non_retryable(true)
                    .build(),
            ));
        }
        if !status.is_success() {
            return Err(http_error(status, &body));
        }
        Ok(field(&body, "placement_id"))
    }

    #[activity]
    pub async fn generate_launch_report(
        _ctx: ActivityContext,
        campaign: String,
        creative_id: String,
        reservation_id: String,
        placements: Vec<String>,
    ) -> Result<LaunchReport, ActivityError> {
        Ok(LaunchReport {
            campaign,
            status: "LIVE".to_string(),
            creative_id,
            reservation_id,
            channels_live: placements.len(),
            placements,
        })
    }
}
