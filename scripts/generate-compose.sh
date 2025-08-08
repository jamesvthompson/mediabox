#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_DIR="$ROOT_DIR/compose"
OUT="$ROOT_DIR/docker-compose.generated.yml"

APPS_CSV="${APPS:-}"   # comma/space/semicolon list
CONFIG_YML="$ROOT_DIR/prep/config.yml"

# Normalize delimiter to spaces
APPS_NORMALIZED="$(echo "$APPS_CSV" | tr ',;' '  ' | xargs || true)"

# If no APPS provided, read from config.yml
if [[ -z "$APPS_NORMALIZED" ]]; then
  if command -v yq >/dev/null 2>&1; then
    APPS_NORMALIZED="$(yq '.apps | to_entries | map(select(.value==true)) | .[].key' "$CONFIG_YML" | xargs || true)"
  else
    APPS_NORMALIZED="$(awk '/^apps:/{flag=1;next}/^[^[:space:]]/{flag=0}flag' "$CONFIG_YML" \
      | grep -E ':[[:space:]]*true' | cut -d: -f1 | xargs || true)"
  fi
fi

if [[ -z "$APPS_NORMALIZED" ]]; then
  echo "No apps selected. Set APPS env (e.g. APPS=\"plex,sonarr,radarr\") or enable apps in prep/config.yml under 'apps:'."
  exit 1
fi

declare -a files
files=("$COMPOSE_DIR/base.yml")
for app in $APPS_NORMALIZED; do
  f="$COMPOSE_DIR/${app}.yml"
  if [[ -f "$f" ]]; then
    files+=("$f")
  else
    echo "Warning: no compose fragment for app '$app' ($f missing), skipping." >&2
  fi
done

if command -v yq >/dev/null 2>&1; then
  yq eval-all 'reduce .[] as $item ({}; . * $item)' "${files[@]}" > "$OUT"
else
  {
    echo "# GENERATED; do not edit"
    for f in "${files[@]}"; do
      echo -e "\n# === $f ==="
      cat "$f"
    done
  } > "$OUT"
fi

echo "Wrote $OUT"
