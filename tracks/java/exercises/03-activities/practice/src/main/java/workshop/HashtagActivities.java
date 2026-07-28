package workshop;

import io.temporal.activity.ActivityInterface;
import java.util.List;

@ActivityInterface
public interface HashtagActivities {
  List<String> fetchHashtags(String channel);
}
