require 'yaml'
require 'sequel'

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

port        ENV.fetch("PORT") { 9292 }

environment ENV.fetch("RACK_ENV") { "development" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

workers ENV.fetch("WEB_CONCURRENCY") { 2 }

preload_app!

on_worker_boot do
  env = ENV['RACK_ENV'] || 'development'
  config = YAML.load_file(File.expand_path('../database.yml', __FILE__))[env]

  DB = Sequel.connect(
    adapter: config['adapter'],
    database: config['database'],
    host: config['host'],
    user: config['user'],
    password: config['password']
  )
end

plugin :tmp_restart
