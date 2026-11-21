# frozen_string_literal: true

require 'temporalio/error'
require 'temporalio/retry_policy'
require 'temporalio/workflow'
require_relative 'activities'

class CampaignWorkflow < Temporalio::Workflow::Definition
  CHANNELS = %w[meowta catstagram pettok].freeze

  def execute(campaign)
    # This used to be launch_campaign in app.rb:
    #
    # creative_id = validate_creative(campaign)
    # reservation_id = reserve_budget(campaign)
    # placements = CHANNELS.map { |channel| publish_to_channel(campaign, channel) }
    # generate_launch_report(campaign, creative_id, reservation_id, placements)
    #
    # TODO: Part C — rebuild the sequence above with
    # Temporalio::Workflow.execute_activity(ActivityClass, *args, ...).
    # Give every Activity a 10-second start_to_close_timeout. Give
    # PublishToChannel a Temporalio::RetryPolicy whose
    # non_retryable_error_types includes "ChannelPolicyError".
    raise Temporalio::Error::ApplicationError.new('Complete Part C', type: 'IncompleteExercise')
  end
end
