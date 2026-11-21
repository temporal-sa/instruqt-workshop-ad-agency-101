use temporalio_macros::{workflow, workflow_methods};
use temporalio_sdk::{WorkflowContext, WorkflowResult};

// The struct name is the Workflow type: "TaglineWorkflow".
#[workflow]
#[derive(Default)]
pub struct TaglineWorkflow;

#[workflow_methods]
impl TaglineWorkflow {
    #[run]
    pub async fn run(_ctx: &mut WorkflowContext<Self>, brand: String) -> WorkflowResult<String> {
        // TODO: Part B — return the tagline: the brand name, a colon and a
        // space, then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
        let _ = brand;
        Ok("TODO".to_string())
    }
}
