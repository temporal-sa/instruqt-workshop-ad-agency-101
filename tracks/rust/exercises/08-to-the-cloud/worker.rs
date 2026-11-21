//! The same Worker as exercise 2, connected to Temporal Cloud.
//! Workflow code and Task Queue configuration are unchanged.
//!
//!   cargo run -q --bin cloud-worker

mod workflows;

use temporalio_client::{Client, ClientOptions, Connection, ConnectionOptions, Url};
use temporalio_sdk::{Runtime, Worker, WorkerOptions};
use workflows::TaglineWorkflow;

const TASK_QUEUE: &str = "tagline-tasks";
const REQUIRED: [&str; 3] = ["TEMPORAL_ADDRESS", "TEMPORAL_NAMESPACE", "TEMPORAL_API_KEY"];

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let missing: Vec<&str> = REQUIRED
        .into_iter()
        .filter(|name| std::env::var(name).map_or(true, |value| value.is_empty()))
        .collect();
    if !missing.is_empty() {
        return Err(format!(
            "Set {} first — see this exercise's README.",
            missing.join(", ")
        )
        .into());
    }

    let address = std::env::var("TEMPORAL_ADDRESS")?;
    let namespace = std::env::var("TEMPORAL_NAMESPACE")?;
    let api_key = std::env::var("TEMPORAL_API_KEY")?;

    // An API key turns on TLS; Temporal Cloud requires both.
    let connection_options = ConnectionOptions::new(Url::parse(&format!("https://{address}"))?)
        .api_key(api_key)
        .build();
    let connection = Connection::connect(connection_options).await?;
    let client = Client::new(connection, ClientOptions::new(namespace.clone()).build())?;

    let runtime = Runtime::from_current_tokio(Default::default())?;
    let worker_options = WorkerOptions::new(TASK_QUEUE)
        .register_workflow::<TaglineWorkflow>()?
        .build();
    let mut worker = Worker::new(&runtime, client, worker_options)?;
    println!("Worker connected to {namespace} on Temporal Cloud. Ctrl-C to stop.");
    worker.run().await?;
    Ok(())
}
