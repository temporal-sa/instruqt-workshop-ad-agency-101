# frozen_string_literal: true

require 'json'
require 'net/http'
require 'temporalio/activity'
require 'temporalio/error'

module AdNet
  BASE = URI('http://localhost:9999')

  # Returns [status_code, parsed_body].
  def self.post_json(path, body)
    response = Net::HTTP.start(BASE.host, BASE.port, open_timeout: 5, read_timeout: 5) do |http|
      http.post(path, JSON.generate(body), 'content-type' => 'application/json')
    end
    [response.code.to_i, JSON.parse(response.body)]
  end

  def self.successful(status, body, field)
    raise "#{status}: #{JSON.generate(body)}" unless status.between?(200, 299)

    body.fetch(field)
  end
end

# These are the same four operations from exercise 1, as plain Ruby classes.
#
# TODO: Part B — make each class a Temporalio Activity by subclassing
# Temporalio::Activity::Definition, e.g.
#   class ValidateCreative < Temporalio::Activity::Definition
# TODO: Part D — in PublishToChannel, turn 4xx into a non-retryable
# Temporalio::Error::ApplicationError with type "ChannelPolicyError".

class ValidateCreative
  def execute(campaign)
    status, body = AdNet.post_json('/validate-creative', { 'campaign' => campaign })
    AdNet.successful(status, body, 'creative_id')
  end
end

class ReserveBudget
  def execute(campaign)
    status, body = AdNet.post_json('/reserve-budget', { 'campaign' => campaign })
    AdNet.successful(status, body, 'reservation_id')
  end
end

class PublishToChannel
  def execute(campaign, channel)
    puts "Publishing to #{channel} (attempt #{Temporalio::Activity::Context.current.info.attempt})"
    status, body = AdNet.post_json("/publish/#{channel}", { 'campaign' => campaign })
    # TODO: Part D — fail fast when status >= 400 && status < 500.
    AdNet.successful(status, body, 'placement_id')
  end
end

class GenerateLaunchReport
  def execute(campaign, creative_id, reservation_id, placements)
    {
      'campaign' => campaign,
      'status' => 'LIVE',
      'creative_id' => creative_id,
      'reservation_id' => reservation_id,
      'placements' => placements,
      'channels_live' => placements.length
    }
  end
end
