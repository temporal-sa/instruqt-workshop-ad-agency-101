# frozen_string_literal: true

require 'json'
require 'net/http'
require 'temporalio/activity'
require 'temporalio/error'

class PublishPost < Temporalio::Activity::Definition
  ADNET = URI('http://localhost:9999')

  def execute(channel)
    puts "Publishing to #{channel} (attempt #{Temporalio::Activity::Context.current.info.attempt})"
    response = Net::HTTP.start(ADNET.host, ADNET.port, open_timeout: 5, read_timeout: 5) do |http|
      http.post("/publish/#{channel}", JSON.generate({ 'campaign' => 'summer-splash' }),
                'content-type' => 'application/json')
    end

    # TODO: Part D — 4xx is a permanent business failure. Detect it and:
    #
    # raise Temporalio::Error::ApplicationError.new(
    #   'human-readable message',
    #   type: 'ChannelPolicyError',
    #   non_retryable: true
    # )

    raise "#{response.code} #{response.message}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('placement_id')
  end
end
