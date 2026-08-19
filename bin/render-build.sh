#!/usr/bin/env bash
set -o errexit

bundle install
npm install
npm run build:css

echo "==> Build complete."
