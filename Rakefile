require 'sequel'
require 'sequel/extensions/migration'
require 'rake'
require 'yaml'

namespace :db do
  desc "Create the database"
  task :create do
    config = YAML.load_file('config/database.yml')['development']
    db_name = config['database']
    db_user = config['user']
    db_password = config['password']
    db_host = config['host']

    begin
      Sequel.connect(
        adapter: config['adapter'],
        host: db_host,
        user: db_user,
        password: db_password,
        database: 'postgres'
      ) do |db|
        # Check if the database exists
        existing_dbs = db.fetch("SELECT datname FROM pg_database WHERE datname = ?", db_name).all
        if existing_dbs.empty?
          db.run "CREATE DATABASE #{db_name}"
          puts "Database #{db_name} created"
        else
          puts "Database #{db_name} already exists"
        end
      end
    rescue Sequel::DatabaseError => e
      puts "Database creation failed: #{e.message}"
    end
  end

  desc 'Migrate the database'
  task :migrate do
    require_relative 'config/initializer/database'
    Sequel.extension :migration
    Sequel::Migrator.run(DB, 'db/migrate')
  end

  desc 'Rollback all migrations'
  task :rollback_all do
    require_relative 'config/initializer/database'
    Sequel.extension :migration
    Sequel::Migrator.run(DB, 'db/migrate', target: 0)
  end

  desc 'Reset the database'
  task reset: [:rollback_all, :migrate]
end
