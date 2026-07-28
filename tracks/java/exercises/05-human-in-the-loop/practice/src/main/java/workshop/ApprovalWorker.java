package workshop;

import io.temporal.client.WorkflowClient;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerFactory;
import java.util.concurrent.CountDownLatch;

public final class ApprovalWorker {
  private ApprovalWorker() {}

  public static void main(String[] args) throws InterruptedException {
    WorkflowClient client = WorkflowClient.newInstance(WorkflowServiceStubs.newLocalServiceStubs());
    WorkerFactory factory = WorkerFactory.newInstance(client);
    Worker worker = factory.newWorker("approval-tasks");
    worker.registerWorkflowImplementationTypes(CampaignApprovalWorkflowImpl.class);
    factory.start();
    System.out.println("Worker started on task queue 'approval-tasks'. Ctrl-C to stop.");
    new CountDownLatch(1).await();
  }
}
