---
slug: activities
type: challenge
title: 3. Activities
teaser: Workflows orchestrate. Activities do the work.
notes:
- type: text
  contents: |-
    # Exercise 3: Activities
    move network I/O into an Activity implementation and call it from a Workflow through a typed stub.
tabs:
- id: rwlxd7ymbp5k
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: j9n3vyntfmuj
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: r6s2pf3a70dl
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: ntvobc5kuxyr
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: qt2vvky5elu6
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: dszekeakry9q
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: yul2zveak2d2
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: basic
timelimit: 900
enhanced_loading: null
---

# Exercise 3: Activities

**Goal:** move network I/O into an Activity implementation and call it from
a Workflow through a typed stub.

Java Workflow code has no sandbox. Never perform network, file, database,
clock, random, or thread operations in it. Put side effects in an
`@ActivityInterface` implementation and create a stub:

```java
HashtagActivities activities =
    Workflow.newActivityStub(
        HashtagActivities.class,
        ActivityOptions.newBuilder()
            .setStartToCloseTimeout(Duration.ofSeconds(10))
            .build());
```

1. Implement `HashtagActivitiesImpl.fetchHashtags`: GET
   `/trending/<channel>`, decode JSON, and return the hashtag list.
2. In `SocialPostWorkflowImpl`, call it with the incoming channel.
3. In `SocialPostWorker`, register `new HashtagActivitiesImpl()`.
4. Start the Worker:

```bash
mvn -q -f exercises/03-activities/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.SocialPostWorker
```

Then:

```bash
temporal workflow start \
  --type SocialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
temporal workflow result -w social-post-1
```

The result must contain `#CatsOfCatstagram` and `#SummerSplash`. If the
Activity implementation is not registered, the Activity remains pending
and the Worker reports that its type is unknown.
