# frozen_string_literal: true

require 'temporalio/retry_policy'
require 'temporalio/workflow'
require_relative 'activities'

class CampaignWorkflow < Temporalio::Workflow::Definition
  CHANNELS = %w[meowta catstagram pettok].freeze
  PUBLISH_RETRY_POLICY = Temporalio::RetryPolicy.new(
    initial_interval: 1,
    backoff_coefficient: 2,
    max_interval: 10,
    non_retryable_error_types: ['ChannelPolicyError']
  )

  def execute(campaign)
    creative_id = run_activity(ValidateCreative, campaign)
    reservation_id = run_activity(ReserveBudget, campaign)
    placements = CHANNELS.map do |channel|
      run_activity(PublishToChannel, campaign, channel, retry_policy: PUBLISH_RETRY_POLICY)
    end
    run_activity(GenerateLaunchReport, campaign, creative_id, reservation_id, placements)
  end

  private

  def run_activity(activity, *args, **options)
    Temporalio::Workflow.execute_activity(activity, *args, start_to_close_timeout: 10, **options)
  end
end
