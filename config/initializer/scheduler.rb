
require 'rufus-scheduler'
require_relative '../../app/services/ping'

scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  active_ips = IP.where(enabled: true)
  active_ips.each do |ip|
    Ping.schedule_ping(ip.id)
  end
  Ping.log_active_ips_count
end
