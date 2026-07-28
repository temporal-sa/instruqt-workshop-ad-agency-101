package workshop;

import io.temporal.failure.ApplicationFailure;

public class CampaignWorkflowImpl implements CampaignWorkflow {
  @Override
  public LaunchReport launch(String campaign) {
    // TODO: Part C — create CampaignActivities stubs with 10-second
    // start-to-close timeouts. Give the publishing stub RetryOptions whose
    // doNotRetry list contains "ChannelPolicyError". Then run, in order:
    // validateCreative, reserveBudget, publishToChannel for each of
    // meowta/catstagram/pettok, and generateLaunchReport.
    throw ApplicationFailure.newFailure("Complete Part C", "IncompleteExercise");
  }
}
