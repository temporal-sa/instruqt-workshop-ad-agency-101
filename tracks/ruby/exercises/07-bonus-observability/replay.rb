# frozen_string_literal: true

# Replay the capstone history against the learner's current Workflow code.
#
# First export:
#   temporal workflow show -w campaign-summer-splash -o json \
#     > exercises/07-bonus-observability/history.json
# Then:
#   bundle exec ruby exercises/07-bonus-observability/replay.rb

require 'temporalio/worker'
require 'temporalio/worker/workflow_replayer'
require 'temporalio/workflow_history'
require_relative '../06-capstone/practice/workflows'

history_path = File.join(__dir__, 'history.json')
unless File.file?(history_path)
  abort <<~MSG
    history.json not found. Export it first:
      temporal workflow show -w campaign-summer-splash -o json > exercises/07-bonus-observability/history.json
  MSG
end

history = Temporalio::WorkflowHistory.from_history_json(File.read(history_path))
replayer = Temporalio::Worker::WorkflowReplayer.new(workflows: [CampaignWorkflow])
# Raises on any replay failure, including a non-determinism error.
replayer.replay_workflow(history)
puts 'Replay OK: your Workflow code is compatible with the recorded history.'
