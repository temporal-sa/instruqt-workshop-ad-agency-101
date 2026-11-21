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
    hashtags = Temporalio::Workflow.execute_activity(
      FetchHashtags, channel,
      start_to_close_timeout: 10
    )
    "#{tagline} #{hashtags.join(' ')}"
  end
end
