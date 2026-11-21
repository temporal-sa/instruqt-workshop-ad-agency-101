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

class GenerateTagline < Temporalio::Activity::Definition
  def execute(brand)
    AdNet.get_json("/tagline?#{URI.encode_www_form(brand:)}").fetch('tagline')
  end
end

class FetchHashtags < Temporalio::Activity::Definition
  def execute(channel)
    AdNet.get_json("/trending/#{channel}").fetch('hashtags')
  end
end
