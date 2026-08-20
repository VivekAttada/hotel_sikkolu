#!/usr/bin/env bash
set -o errexit

bundle install

# Build CSS into app/assets/builds (required before assets:precompile)
npm install
npm run build:css

if [ ! -f app/assets/builds/application.css ]; then
  echo "ERROR: CSS build failed — application.css not found"
  exit 1
fi

echo "==> CSS build OK ($(wc -c < app/assets/builds/application.css) bytes)"

# Compile digested assets into public/assets so production can serve them
echo "==> Precompiling assets..."
SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

if ! ls public/assets/application-*.css >/dev/null 2>&1; then
  echo "ERROR: assets:precompile did not create public/assets/application-*.css"
  ls -la public/assets || true
  exit 1
fi

echo "==> Precompiled assets:"
ls -la public/assets/application-*.css public/assets/*.png 2>/dev/null | head -20
