# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/worker'
require_relative 'activities'
require_relative 'workflows'

client = Temporalio::Client.connect('localhost:7233', 'default')
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'campaign-tasks',
  workflows: [CampaignWorkflow],
  activities: [] # TODO: Part E — register the four Activity classes
)
puts "Worker started on task queue 'campaign-tasks'. Ctrl-C to stop."
worker.run(shutdown_signals: %w[SIGINT SIGTERM])
