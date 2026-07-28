package workshop;

import io.temporal.testing.WorkflowReplayer;
import java.io.File;

public final class Replay {
  private Replay() {}

  public static void main(String[] args) throws Exception {
    File history = new File("exercises/07-bonus-observability/history.json");
    if (!history.isFile()) {
      throw new IllegalStateException(
          "history.json not found. Export it first:\n"
              + "  temporal workflow show -w campaign-summer-splash -o json "
              + "> exercises/07-bonus-observability/history.json");
    }
    WorkflowReplayer.replayWorkflowExecution(history, CampaignWorkflowImpl.class);
    System.out.println(
        "Replay OK: your Workflow code is compatible with the recorded history.");
  }
}
