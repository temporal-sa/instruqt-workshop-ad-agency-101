# frozen_string_literal: true

# Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?
#
# Run it:
#   bundle exec ruby exercises/01-meet-the-app/practice/app.rb

require 'json'
require 'net/http'

ADNET = URI('http://localhost:9999')
CHANNELS = %w[meowta catstagram pettok].freeze

def post(path, body)
  response = Net::HTTP.start(ADNET.host, ADNET.port, open_timeout: 5, read_timeout: 5) do |http|
    http.post(path, JSON.generate(body), 'content-type' => 'application/json')
  end
  raise "#{response.code} #{response.message}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
end

def validate_creative(campaign)
  creative_id = post('/validate-creative', { 'campaign' => campaign }).fetch('creative_id')
  puts "  ✅ Creative approved: #{creative_id}"
  creative_id
end

def reserve_budget(campaign)
  body = post('/reserve-budget', { 'campaign' => campaign })
  amount = body.fetch('amount').to_s.reverse.scan(/\d{1,3}/).join(',').reverse
  puts "  💸 Budget reserved: $#{amount} (#{body.fetch('reservation_id')})"
  body.fetch('reservation_id')
end

def publish_to_channel(campaign, channel)
  placement_id = post("/publish/#{channel}", { 'campaign' => campaign }).fetch('placement_id')
  puts "  📣 Live on #{channel}: #{placement_id}"
  placement_id
end

def generate_launch_report(campaign, creative_id, reservation_id, placements)
  report = {
    'campaign' => campaign,
    'status' => 'LIVE',
    'creative_id' => creative_id,
    'reservation_id' => reservation_id,
    'placements' => placements,
    'channels_live' => placements.length
  }
  puts "  📊 Launch report: #{JSON.pretty_generate(report)}"
  report
end

def launch_campaign(campaign)
  puts "🚀 Launching campaign '#{campaign}' for CatNip Cola..."
  creative_id = validate_creative(campaign)
  sleep 1
  reservation_id = reserve_budget(campaign)
  sleep 1

  placements = []
  CHANNELS.each do |channel|
    placements << publish_to_channel(campaign, channel)
    sleep 1
  end

  generate_launch_report(campaign, creative_id, reservation_id, placements)
end

launch_campaign('summer-splash')
