mod activities;
mod workflows;

use activities::PublishActivities;
use temporalio_client::{
    Client, ClientOptions, Connection, envconfig::LoadClientConfigProfileOptions,
};
use temporalio_sdk::{Runtime, Worker, WorkerOptions};
use workflows::PublishWorkflow;

const TASK_QUEUE: &str = "publish-tasks";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let runtime = Runtime::from_current_tokio(Default::default())?;
    let (connection_options, client_options) =
        ClientOptions::load_from_config(LoadClientConfigProfileOptions::default())?;
    let connection = Connection::connect(connection_options).await?;
    let client = Client::new(connection, client_options)?;

    let worker_options = WorkerOptions::new(TASK_QUEUE)
        .register_workflow::<PublishWorkflow>()?
        .register_activities(PublishActivities)
        .build();

    let mut worker = Worker::new(&runtime, client, worker_options)?;
    println!("Worker started on task queue '{TASK_QUEUE}'. Ctrl-C to stop.");
    worker.run().await?;
    Ok(())
}
