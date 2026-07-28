package workshop;

import io.temporal.client.WorkflowClient;
import io.temporal.client.WorkflowClientOptions;
import io.temporal.serviceclient.WorkflowServiceStubs;
import io.temporal.serviceclient.WorkflowServiceStubsOptions;
import io.temporal.worker.Worker;
import io.temporal.worker.WorkerFactory;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

public final class CloudWorker {
  private CloudWorker() {}

  public static void main(String[] args) throws InterruptedException {
    List<String> missing = new ArrayList<>();
    for (String name : List.of("TEMPORAL_ADDRESS", "TEMPORAL_NAMESPACE", "TEMPORAL_API_KEY")) {
      if (System.getenv(name) == null || System.getenv(name).isBlank()) missing.add(name);
    }
    if (!missing.isEmpty()) {
      throw new IllegalStateException(
          "Set " + String.join(", ", missing) + " first — see this exercise's README.");
    }

    String apiKey = System.getenv("TEMPORAL_API_KEY");
    WorkflowServiceStubs service =
        WorkflowServiceStubs.newServiceStubs(
            WorkflowServiceStubsOptions.newBuilder()
                .setTarget(System.getenv("TEMPORAL_ADDRESS"))
                .addApiKey(() -> apiKey)
                .build());
    WorkflowClient client =
        WorkflowClient.newInstance(
            service,
            WorkflowClientOptions.newBuilder()
                .setNamespace(System.getenv("TEMPORAL_NAMESPACE"))
                .build());
    WorkerFactory factory = WorkerFactory.newInstance(client);
    Worker worker = factory.newWorker("tagline-tasks");
    worker.registerWorkflowImplementationTypes(TaglineWorkflowImpl.class);
    factory.start();
    System.out.printf(
        "Worker connected to %s on Temporal Cloud. Ctrl-C to stop.%n",
        System.getenv("TEMPORAL_NAMESPACE"));
    new CountDownLatch(1).await();
  }
}
