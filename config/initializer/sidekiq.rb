require 'sidekiq'
require 'sidekiq/logger'
require_relative './database'
require_relative '../../app/models/ip'
require_relative '../../app/models/ping_result'
require_relative '../../app/services/ping'
require_relative './scheduler'

Sidekiq.configure_server do |config|
  # for sidekiq 7 get RedisTimeoutError
  # add timeout
  # https://github.com/sidekiq/sidekiq/issues/6162
  config.redis = { ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }, timeout: 10 }
  config.logger = Sidekiq::Logger.new($stdout)
  config.logger.formatter = Sidekiq::Logger::Formatters::Pretty.new
  # config.logger.level = Logger::WARN
end

Sidekiq.configure_client do |config|
  config.redis = { ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
end
