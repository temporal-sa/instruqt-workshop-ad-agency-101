# frozen_string_literal: true

require 'temporalio/retry_policy'
require 'temporalio/workflow'
require_relative 'activities'

class PublishWorkflow < Temporalio::Workflow::Definition
  def execute(channel)
    Temporalio::Workflow.execute_activity(
      PublishPost, channel,
      start_to_close_timeout: 10
      # TODO: Part C — add a custom retry policy (mind the comma above):
      # retry_policy: Temporalio::RetryPolicy.new(
      #   initial_interval: 1,
      #   backoff_coefficient: 2,
      #   max_interval: 10
      # )
    )
  end
end
