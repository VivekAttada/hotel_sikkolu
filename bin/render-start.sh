#!/usr/bin/env bash
set -o errexit

export RAILS_ENV=production
export RACK_ENV=production

echo "==> Render start: RAILS_ENV=$RAILS_ENV"

if [ -z "${DATABASE_URL}" ]; then
  echo "ERROR: DATABASE_URL is not set. Link a PostgreSQL database in Render Environment."
  exit 1
fi

echo "==> Running database migrations..."
bundle exec rails db:migrate

echo "==> Seeding database..."
bundle exec rails db:seed

echo "==> Starting Puma..."
exec bundle exec puma -C config/puma.rb
