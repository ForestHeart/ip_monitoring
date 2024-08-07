require 'net/ping'
require 'sidekiq'
require 'rufus-scheduler'
require 'ipaddress'
require 'pry'
require_relative '../models/ip'
require_relative '../models/ping_result'

class Ping
  include Sidekiq::Job

  def perform(ip_id)
    ip = IP[ip_id]
    return unless ip&.enabled

    pinger = Net::Ping::External.new(ip.address)
    pinger.timeout = 1
    result = if IPAddress.valid_ipv6?(ip.address)
               pinger.ping6
             else
               pinger.ping
             end
    rtt = pinger.duration * 1000 if result

    PingResult.create(ip_id: ip.id, success: result, rtt: rtt)
    if result
      Sidekiq.logger.info("Ping to #{ip.address}: success (RTT: #{rtt})")
    else
      error_message = pinger.warning || pinger.exception.to_s
      Sidekiq.logger.info("Ping to #{ip.address}: failure (Error: #{error_message})")
    end
  end

  def self.schedule_ping(ip_id)
    Sidekiq::Client.push(
      'class' => self,
      'args' => [ip_id]
    )
  end

  def self.log_active_ips_count
    active_ips_count = IP.where(enabled: true).count
    Sidekiq.logger.info "Active IPs count: #{active_ips_count}"
  end

  def self.calculate_stats(ip, from_time, to_time)
    results = PingResult.where(timestamp: from_time..to_time, ip_id: ip.id)
    # results = ip.ping_results.where(timestamp: from_time..to_time)

    return { error: 'No data for the specified period' } if results.empty?

    stats = results.select{
      [
        count(:id).as(:total_count),
        count(:rtt).as(:success_count),
        avg(:rtt).as(:average_rtt),
        min(:rtt).as(:min_rtt),
        max(:rtt).as(:max_rtt),
        percentile_cont(0.5).within_group(:rtt).as(:median_rtt),
        stddev_pop(:rtt).as(:stddev_rtt)
      ]
    }.first

    if stats[:success_count] == 0
      return {
        average_rtt: nil,
        min_rtt: nil,
        max_rtt: nil,
        median_rtt: nil,
        stddev_rtt: nil,
        packet_loss: 100.0
      }
    end

    total_count = stats[:total_count].to_f
    success_count = stats[:success_count].to_f
    loss_percentage = ((total_count - success_count) / total_count) * 100

    {
      average_rtt: stats[:average_rtt],
      min_rtt: stats[:min_rtt],
      max_rtt: stats[:max_rtt],
      median_rtt: stats[:median_rtt],
      stddev_rtt: stats[:stddev_rtt],
      packet_loss: loss_percentage
    }
  end
end
