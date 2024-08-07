require 'yaml'
require 'erb'
require 'sequel'
require 'pry'

env = ENV['RACK_ENV'] || 'development'

erb_out = ERB.new(File.read(File.expand_path('../../database.yml', __FILE__))).result
config = YAML.load(erb_out)[env]

DB = Sequel.connect(
  adapter: config['adapter'],
  database: config['database'],
  host: config['host'],
  user: config['user'],
  password: config['password']
)
