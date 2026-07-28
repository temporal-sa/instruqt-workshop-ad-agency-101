package workshop;

import io.temporal.activity.ActivityInterface;

@ActivityInterface
public interface PublishActivities {
  String publishPost(String channel);
}
