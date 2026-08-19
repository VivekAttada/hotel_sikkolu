#!/usr/bin/env bash
set -o errexit

bundle install
npm install
npm run build:css
bundle exec rails db:prepare
bundle exec rails db:seed
