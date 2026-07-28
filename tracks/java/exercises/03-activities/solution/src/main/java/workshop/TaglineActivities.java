package workshop;

import io.temporal.activity.ActivityInterface;

@ActivityInterface
public interface TaglineActivities {
  String generateTagline(String brand);
}
