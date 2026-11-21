# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/worker'
require_relative 'activities'
require_relative 'workflows'

client = Temporalio::Client.connect('localhost:7233', 'default')
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'social-tasks',
  workflows: [SocialPostWorkflow],
  activities: [GenerateTagline] # TODO: Part D — register FetchHashtags too
)
puts "Worker started on task queue 'social-tasks'. Ctrl-C to stop."
worker.run(shutdown_signals: %w[SIGINT SIGTERM])
