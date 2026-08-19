#!/usr/bin/env bash
set -o errexit

bundle install
npm install
npm run build:css

if [ ! -f app/assets/builds/application.css ]; then
  echo "ERROR: CSS build failed — application.css not found"
  exit 1
fi

echo "==> CSS build OK ($(wc -c < app/assets/builds/application.css) bytes)"
