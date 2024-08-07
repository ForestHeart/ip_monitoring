#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Run migrations
bundle exec rake db:migrate

# Then exec the container's main process
exec "$@"
