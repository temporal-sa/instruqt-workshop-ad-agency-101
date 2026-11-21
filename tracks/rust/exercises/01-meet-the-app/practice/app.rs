//! Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?
//!
//! Run it:
//!   cargo run -q --bin campaign-app

use std::time::Duration;

use serde::Serialize;
use serde_json::{Value, json};

const ADNET: &str = "http://localhost:9999";
const CHANNELS: [&str; 3] = ["meowta", "catstagram", "pettok"];

type AppResult<T> = Result<T, Box<dyn std::error::Error>>;

#[derive(Debug, Serialize)]
struct LaunchReport {
    campaign: String,
    status: &'static str,
    creative_id: String,
    reservation_id: String,
    placements: Vec<String>,
    channels_live: usize,
}

async fn post(http: &reqwest::Client, path: &str, body: Value) -> AppResult<Value> {
    let response = http
        .post(format!("{ADNET}{path}"))
        .json(&body)
        .timeout(Duration::from_secs(5))
        .send()
        .await?;
    let status = response.status();
    if !status.is_success() {
        let text = response.text().await?;
        return Err(format!("{status}: {text}").into());
    }
    Ok(response.json().await?)
}

fn field(body: &Value, name: &str) -> String {
    body[name].as_str().unwrap_or_default().to_owned()
}

async fn validate_creative(http: &reqwest::Client, campaign: &str) -> AppResult<String> {
    let body = post(http, "/validate-creative", json!({ "campaign": campaign })).await?;
    let creative_id = field(&body, "creative_id");
    println!("  ✅ Creative approved: {creative_id}");
    Ok(creative_id)
}

async fn reserve_budget(http: &reqwest::Client, campaign: &str) -> AppResult<String> {
    let body = post(http, "/reserve-budget", json!({ "campaign": campaign })).await?;
    let reservation_id = field(&body, "reservation_id");
    println!(
        "  💸 Budget reserved: ${} ({reservation_id})",
        body["amount"].as_u64().unwrap_or_default()
    );
    Ok(reservation_id)
}

async fn publish_to_channel(
    http: &reqwest::Client,
    campaign: &str,
    channel: &str,
) -> AppResult<String> {
    let body = post(
        http,
        &format!("/publish/{channel}"),
        json!({ "campaign": campaign }),
    )
    .await?;
    let placement_id = field(&body, "placement_id");
    println!("  📣 Live on {channel}: {placement_id}");
    Ok(placement_id)
}

fn generate_launch_report(
    campaign: &str,
    creative_id: String,
    reservation_id: String,
    placements: Vec<String>,
) -> LaunchReport {
    let report = LaunchReport {
        campaign: campaign.to_owned(),
        status: "LIVE",
        creative_id,
        reservation_id,
        channels_live: placements.len(),
        placements,
    };
    println!("  📊 Launch report: {report:?}");
    report
}

async fn launch_campaign(campaign: &str) -> AppResult<LaunchReport> {
    let http = reqwest::Client::new();
    println!("🚀 Launching campaign '{campaign}' for CatNip Cola...");
    let creative_id = validate_creative(&http, campaign).await?;
    tokio::time::sleep(Duration::from_secs(1)).await;
    let reservation_id = reserve_budget(&http, campaign).await?;
    tokio::time::sleep(Duration::from_secs(1)).await;

    // This Vec lives only in this process's memory.
    let mut placements = Vec::new();
    for channel in CHANNELS {
        placements.push(publish_to_channel(&http, campaign, channel).await?);
        tokio::time::sleep(Duration::from_secs(1)).await;
    }

    Ok(generate_launch_report(
        campaign,
        creative_id,
        reservation_id,
        placements,
    ))
}

#[tokio::main]
async fn main() -> AppResult<()> {
    launch_campaign("summer-splash").await?;
    Ok(())
}
