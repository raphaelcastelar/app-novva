#!/usr/bin/env bash
set -euo pipefail

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
public_api_url="${NOVVA_PUBLIC_API_URL:-https://api-novva.inovarcontabilidadex.com.br/api/v1/}"

cd "$app_root"
flutter build ios --release \
  --dart-define="NOVVA_API_BASE_URL=$public_api_url" \
  --dart-define=NOVVA_USE_MOCK_API=false \
  "$@"
