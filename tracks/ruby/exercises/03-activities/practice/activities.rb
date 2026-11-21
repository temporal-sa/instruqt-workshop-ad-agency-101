# frozen_string_literal: true

require 'json'
require 'net/http'
require 'temporalio/activity'

module AdNet
  BASE = URI('http://localhost:9999')

  def self.get_json(path)
    response = Net::HTTP.start(BASE.host, BASE.port, open_timeout: 5, read_timeout: 5) do |http|
      http.get(path)
    end
    raise "#{response.code} #{response.message}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end

# The worked example: an Activity is a class that subclasses
# Temporalio::Activity::Definition and implements execute. Activities contain
# fallible, non-deterministic work such as network I/O.
class GenerateTagline < Temporalio::Activity::Definition
  def execute(brand)
    AdNet.get_json("/tagline?#{URI.encode_www_form(brand:)}").fetch('tagline')
  end
end

# TODO: Part B — define a FetchHashtags Activity class.
# Its execute(channel) method returns an Array of hashtag Strings.
# AdNet endpoint: GET http://localhost:9999/trending/<channel>
