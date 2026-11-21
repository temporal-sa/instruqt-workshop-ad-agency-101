# frozen_string_literal: true

# The same Worker as exercise 2, connected to Temporal Cloud.
# Workflow code and Task Queue configuration are unchanged.

require 'temporalio/client'
require 'temporalio/worker'
require_relative 'workflows'

REQUIRED = %w[TEMPORAL_ADDRESS TEMPORAL_NAMESPACE TEMPORAL_API_KEY].freeze

missing = REQUIRED.select { |name| ENV.fetch(name, '').strip.empty? }
abort "Set #{missing.join(', ')} first — see this exercise's README." unless missing.empty?

namespace = ENV.fetch('TEMPORAL_NAMESPACE')
client = Temporalio::Client.connect(
  ENV.fetch('TEMPORAL_ADDRESS'),
  namespace,
  api_key: ENV.fetch('TEMPORAL_API_KEY'),
  tls: true
)
worker = Temporalio::Worker.new(
  client:,
  task_queue: 'tagline-tasks',
  workflows: [TaglineWorkflow]
)
puts "Worker connected to #{namespace} on Temporal Cloud. Ctrl-C to stop."
worker.run(shutdown_signals: %w[SIGINT SIGTERM])
