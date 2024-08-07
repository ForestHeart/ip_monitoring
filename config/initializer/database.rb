require 'yaml'
require 'sequel'

env = ENV['RACK_ENV'] || 'development'
config = YAML.load_file(File.expand_path('../../database.yml', __FILE__))[env]

DB = Sequel.connect(
  adapter: config['adapter'],
  database: config['database'],
  host: config['host'],
  user: config['user'],
  password: config['password']
)
