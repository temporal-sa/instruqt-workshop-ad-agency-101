package workshop;

import io.temporal.client.WorkflowClient;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerFactory;
import java.util.concurrent.CountDownLatch;

public final class TaglineWorker {
  private TaglineWorker() {}

  public static void main(String[] args) throws InterruptedException {
    WorkflowServiceStubs service = WorkflowServiceStubs.newLocalServiceStubs();
    WorkflowClient client = WorkflowClient.newInstance(service);
    WorkerFactory factory = WorkerFactory.newInstance(client);
    Worker worker = factory.newWorker("TODO"); // TODO: Part C — use "tagline-tasks"
    worker.registerWorkflowImplementationTypes(TaglineWorkflowImpl.class);
    factory.start();
    System.out.println("Worker started on task queue 'tagline-tasks'. Ctrl-C to stop.");
    new CountDownLatch(1).await();
  }
}
