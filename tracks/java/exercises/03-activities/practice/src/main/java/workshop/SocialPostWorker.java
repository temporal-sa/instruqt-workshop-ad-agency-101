package workshop;

import io.temporal.client.WorkflowClient;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerFactory;
import java.util.concurrent.CountDownLatch;

public final class SocialPostWorker {
  private SocialPostWorker() {}

  public static void main(String[] args) throws InterruptedException {
    WorkflowClient client = WorkflowClient.newInstance(WorkflowServiceStubs.newLocalServiceStubs());
    WorkerFactory factory = WorkerFactory.newInstance(client);
    Worker worker = factory.newWorker("social-tasks");
    worker.registerWorkflowImplementationTypes(SocialPostWorkflowImpl.class);
    worker.registerActivitiesImplementations(
        new TaglineActivitiesImpl()
        // TODO: Part D — add new HashtagActivitiesImpl()
    );
    factory.start();
    System.out.println("Worker started on task queue 'social-tasks'. Ctrl-C to stop.");
    new CountDownLatch(1).await();
  }
}
