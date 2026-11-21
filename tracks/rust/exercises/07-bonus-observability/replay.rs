//! Replay the capstone's Event History against your current exercise 6
//! Workflow code.
//!
//!   cargo run -q --bin replay                     # campaign-summer-splash
//!   cargo run -q --bin replay -- <workflow-id>    # any CampaignWorkflow
//!
//! The Rust SDK's `WorkflowHistory::from_json` reads the SDK's own JSON
//! encoding, not the proto-JSON that `temporal workflow show -o json`
//! writes. So this program fetches the same history straight from the
//! Temporal Service, then replays it locally.

// Compile the learner's exercise 6 practice code into this program.
#[path = "../06-capstone/practice/activities.rs"]
mod activities;
#[path = "../06-capstone/practice/workflows.rs"]
mod workflows;

use temporalio_client::{
    Client, ClientOptions, Connection, WorkflowFetchHistoryOptions,
    envconfig::LoadClientConfigProfileOptions,
};
use temporalio_sdk::workflow_replayer::{WorkflowReplayer, WorkflowReplayerOptions};
use workflows::CampaignWorkflow;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let workflow_id = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "campaign-summer-splash".to_string());

    let (connection_options, client_options) =
        ClientOptions::load_from_config(LoadClientConfigProfileOptions::default())?;
    let connection = Connection::connect(connection_options).await?;
    let client = Client::new(connection, client_options)?;
    let history = client
        .get_workflow_handle::<CampaignWorkflow>(workflow_id.clone())
        .fetch_history(WorkflowFetchHistoryOptions::default());

    // The replayer runs Workflow code against the recorded Event History. It
    // never calls the real Activities: their results come from the history.
    let options = WorkflowReplayerOptions::new()
        .register_workflow::<CampaignWorkflow>()?
        .build();
    let replayer = WorkflowReplayer::new(options)?;
    replayer.replay_workflow(history).await?;

    println!(
        "Replay OK: your Workflow code is compatible with the recorded history of {workflow_id}."
    );
    Ok(())
}
