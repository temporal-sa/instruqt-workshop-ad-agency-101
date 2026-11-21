# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'activities'

class SocialPostWorkflow < Temporalio::Workflow::Definition
  BRAND = 'CatNip Cola'

  def execute(channel)
    tagline = Temporalio::Workflow.execute_activity(
      GenerateTagline, BRAND,
      start_to_close_timeout: 10
    )
    # TODO: Part C — schedule the FetchHashtags Activity the same way:
    # hashtags = Temporalio::Workflow.execute_activity(
    #   FetchHashtags, channel,
    #   start_to_close_timeout: 10
    # )
    # execute_activity schedules an Activity Task; it does not call the
    # implementation directly inside the Workflow.
    hashtags = []
    "#{tagline} #{hashtags.join(' ')}"
  end
end
