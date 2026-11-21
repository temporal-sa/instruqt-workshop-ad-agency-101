# frozen_string_literal: true

require 'temporalio/client'
require 'temporalio/worker'
require_relative 'workflows'

client = Temporalio::Client.connect('localhost:7233', 'default')
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'tagline-tasks',
  workflows: [TaglineWorkflow]
)
puts "Worker started on task queue 'tagline-tasks'. Ctrl-C to stop."
worker.run(shutdown_signals: %w[SIGINT SIGTERM])
