package workshop;

import io.temporal.client.WorkflowClient;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerFactory;
import java.util.concurrent.CountDownLatch;

public final class CampaignWorker {
  private CampaignWorker() {}

  public static void main(String[] args) throws InterruptedException {
    WorkflowClient client = WorkflowClient.newInstance(WorkflowServiceStubs.newLocalServiceStubs());
    WorkerFactory factory = WorkerFactory.newInstance(client);
    Worker worker = factory.newWorker("campaign-tasks");
    worker.registerWorkflowImplementationTypes(CampaignWorkflowImpl.class);
    worker.registerActivitiesImplementations(new CampaignActivitiesImpl());
    factory.start();
    System.out.println("Worker started on task queue 'campaign-tasks'. Ctrl-C to stop.");
    new CountDownLatch(1).await();
  }
}
