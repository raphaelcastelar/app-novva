#!/usr/bin/env bash
set -euo pipefail

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
local_api_url="${NOVVA_LOCAL_API_URL:-http://127.0.0.1:8000/api/}"

cd "$app_root"
flutter run \
  --dart-define="NOVVA_API_BASE_URL=$local_api_url" \
  --dart-define=NOVVA_USE_MOCK_API=false \
  "$@"
