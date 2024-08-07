require 'spec_helper'
require 'faker'

RSpec.describe IPMonitoring do
  let(:ip_params) { { ip: Faker::Internet.unique.ip_v4_address, enabled: true } }
  let(:ipv6_params) { { ip: Faker::Internet.unique.ip_v6_address, enabled: true } }
  let(:invalid_ip_params) { { ip: 'invalid_ip', enabled: true } }
  let(:created_ip) { IP.create(address: ip_params[:ip], enabled: ip_params[:enabled]) }

  before(:each) do
    Faker::UniqueGenerator.clear # Clear the unique generator to avoid collisions
  end

  describe 'POST /ips' do
    it 'creates a new IP address' do
      post '/ips', ip_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)['ip']).to eq(ip_params[:ip])
    end

    it 'creates a new IPv6 address' do
      post '/ips', ipv6_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body)['ip']).to eq(ipv6_params[:ip])
    end

    it 'returns an error with invalid IP' do
      post '/ips', invalid_ip_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to eq('Invalid IP address')
    end

    it 'returns an error when IP address is not unique' do
      IP.create(address: ip_params[:ip], enabled: ip_params[:enabled])
      post '/ips', ip_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to eq('address is already taken')
    end
  end

  describe 'POST /ips/:id/enable' do
    it 'enables an IP address' do
      post "/ips/#{created_ip.id}/enable"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['enabled']).to be true
    end
  end

  describe 'POST /ips/:id/disable' do
    it 'disables an IP address' do
      post "/ips/#{created_ip.id}/disable"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['enabled']).to be false
    end
  end

  describe 'GET /ips/:id/stats' do
    it 'returns statistics for an IP address' do
      get "/ips/#{created_ip.id}/stats", { time_from: (Time.now - 3600).to_s, time_to: Time.now.to_s }
      expect(last_response.status).to eq(200)
    end
  end

  describe 'GET /ips/:id/stats' do
    it 'returns statistics for an IP address' do
      PingResult.create(ip_id: created_ip.id, success: true, rtt: 100.0, timestamp: Time.now - 1800)
      PingResult.create(ip_id: created_ip.id, success: true, rtt: 120.0, timestamp: Time.now - 1200)
      PingResult.create(ip_id: created_ip.id, success: true, rtt: 200.0, timestamp: Time.now - 900)
      PingResult.create(ip_id: created_ip.id, success: false, rtt: nil, timestamp: Time.now - 300)

      get "/ips/#{created_ip.id}/stats", { time_from: (Time.now - 3600).to_s, time_to: Time.now.to_s }
      expect(last_response.status).to eq(200)
      stats = JSON.parse(last_response.body)
      expect(stats['average_rtt']).to eq(140.0) # 420 / 3 = 140
      expect(stats['min_rtt']).to eq(100.0)
      expect(stats['max_rtt']).to eq(200.0)
      expect(stats['median_rtt']).to eq(120.0)  # 100 - 120 - 200

      # отклонения = [140 - 100, 140 - 120, 140 - 200] = [40, 20, 60]
      # сумма квадратов = 1600 + 400 + 3600 = 5600
      # корень(5600/3) = 43.2
      expect(stats['stddev_rtt']).to be_within(0.1).of(43.2)
      expect(stats['packet_loss']).to be_within(0.01).of(25) # 1/4
    end

    it 'returns a packet loss of 100% if there are no successful pings' do
      PingResult.create(ip_id: created_ip.id, success: false, rtt: nil, timestamp: Time.now - 1800)

      get "/ips/#{created_ip.id}/stats", { time_from: (Time.now - 3600).to_s, time_to: Time.now.to_s }
      stats = JSON.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(stats['packet_loss']).to eq(100.0)
      expect(stats['average_rtt']).to be_nil
      expect(stats['min_rtt']).to be_nil
      expect(stats['max_rtt']).to be_nil
      expect(stats['median_rtt']).to be_nil
      expect(stats['stddev_rtt']).to be_nil
    end
  end

  describe 'DELETE /ips/:id' do
    it 'deletes an IP address' do
      delete "/ips/#{created_ip.id}"
      expect(last_response.status).to eq(204)
    end
  end
end
