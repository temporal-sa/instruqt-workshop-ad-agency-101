package workshop;

import io.temporal.workflow.Workflow;

public class TaglineWorkflowImpl implements TaglineWorkflow {
  @Override
  public String generate(String brand) {
    Workflow.getLogger(TaglineWorkflowImpl.class).info("Generating tagline for {}", brand);
    return brand + ": Taste the Meow!";
  }
}
