require 'grape'
require 'grape-swagger'
require 'ipaddress'
require 'pry'
require_relative '../models/ip'
require_relative '../services/ping'

class IPMonitoring < Grape::API
  format :json

  rescue_from Sequel::ValidationFailed do |e|
    error!({ error: e.message }, 400)
  end

  helpers do
    def valid_ip?(ip)
      IPAddress.valid?(ip)
    end
  end

  resource :ips do
    desc 'Add a new IP address'
    params do
      requires :ip, type: String, desc: 'IPv4/IPv6 address'
      requires :enabled, type: Boolean, desc: 'Enable or disable monitoring'
    end
    post do
      error!('Invalid IP address', 400) unless valid_ip?(params[:ip])

      ip = IP.create({
        address: params[:ip],
        enabled: params[:enabled]
      })
      { id: ip.id, ip: ip.address, enabled: ip.enabled }
    end

    desc 'Get added IP list'
    get :list do
      IP.all.map do |ip|
        { id: ip.id, ip: ip.address, enabled: ip.enabled }
      end
    end

    route_param :id do
      desc 'Enable monitoring for an IP address'
      post :enable do
        ip = IP[params[:id]]
        error!('Not Found', 404) unless ip
        ip.update(enabled: true)
        status 200
        { id: ip.id, enabled: ip.enabled }
      end

      desc 'Disable monitoring for an IP address'
      post :disable do
        ip = IP[params[:id]]
        error!('Not Found', 404) unless ip
        ip.update(enabled: false)
        status 200
        { id: ip.id, enabled: ip.enabled }
      end

      desc 'Get statistics for an IP address'
      params do
        requires :time_from, type: DateTime, desc: 'Start time for statistics'
        requires :time_to, type: DateTime, desc: 'End time for statistics'
      end
      get :stats do
        ip = IP[params[:id]]
        error!('Not Found', 404) unless ip
        stats = Ping.calculate_stats(ip, params[:time_from], params[:time_to])
        stats.merge(address: ip.address, enabled: ip.enabled)
      end

      desc 'Delete an IP address'
      delete do
        ip = IP[params[:id]]
        error!('Not Found', 404) unless ip
        ip.destroy
        status 204
      end
    end
  end

  add_swagger_documentation(
    info: {
      title: 'IP Monitoring API',
      description: 'API for monitoring IP addresses'
    },
    api_version: 'v1',
    base_path: '/',
    hide_documentation_path: true,
    mount_path: '/docs'
  )
end
