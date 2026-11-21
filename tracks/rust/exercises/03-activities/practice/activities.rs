#![allow(dead_code)] // HashtagActivities stays unused until you finish the TODOs.

use std::time::Duration;

use serde_json::Value;
use temporalio_macros::activities;
use temporalio_sdk::activities::{ActivityContext, ActivityError};

const ADNET: &str = "http://localhost:9999";

async fn get_json(path: &str) -> Result<Value, ActivityError> {
    let response = reqwest::Client::new()
        .get(format!("{ADNET}{path}"))
        .timeout(Duration::from_secs(5))
        .send()
        .await?
        .error_for_status()?;
    Ok(response.json().await?)
}

// The worked example: an Activity is an ordinary async method. Activities
// contain fallible, non-deterministic work such as network I/O.
pub struct TaglineActivities;

#[activities]
impl TaglineActivities {
    // Activity type: "TaglineActivities::generate_tagline"
    #[activity]
    pub async fn generate_tagline(
        _ctx: ActivityContext,
        brand: String,
    ) -> Result<String, ActivityError> {
        let body = get_json(&format!("/tagline?brand={}", brand.replace(' ', "%20"))).await?;
        Ok(body["tagline"].as_str().unwrap_or_default().to_owned())
    }
}

pub struct HashtagActivities;

#[activities]
impl HashtagActivities {
    // Activity type: "HashtagActivities::fetch_hashtags"
    #[activity]
    pub async fn fetch_hashtags(
        _ctx: ActivityContext,
        channel: String,
    ) -> Result<Vec<String>, ActivityError> {
        // TODO: Part B — fetch GET /trending/<channel> from AdNet and return
        // its "hashtags" list:
        //
        // let body = get_json(&format!("/trending/{channel}")).await?;
        // Ok(serde_json::from_value(body["hashtags"].clone())?)
        let _ = channel;
        Ok(Vec::new())
    }
}
