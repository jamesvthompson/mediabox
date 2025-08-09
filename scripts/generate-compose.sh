#!/usr/bin/env bash
set -euo pipefail
# === generate-compose.sh (merged services fallback) ===
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_DIR="$ROOT_DIR/compose"
OUT="${OUT:-$ROOT_DIR/docker-compose.generated.yml}"
CONFIG_YML="$ROOT_DIR/prep/config.yml"

APPS_CSV="${APPS:-}"   # comma/space/semicolon list
DRY_RUN="${DRY_RUN:-0}"

norm_list(){ echo "$*" | tr ',;' '  ' | xargs || true; }

# Resolve app list
APPS_NORMALIZED="$(norm_list "$APPS_CSV")"
if [[ -z "$APPS_NORMALIZED" ]]; then
  if command -v yq >/dev/null 2>&1; then
    APPS_NORMALIZED="$(yq '.apps | to_entries | map(select(.value==true)) | .[].key' "$CONFIG_YML" | xargs || true)"
  else
    APPS_NORMALIZED="$(awk '/^apps:/{flag=1;next}/^[^[:space:]]/{flag=0}flag' "$CONFIG_YML" \
      | grep -E ':[[:space:]]*true' | cut -d: -f1 | xargs || true)"
  fi
fi
[[ -z "$APPS_NORMALIZED" ]] && { echo "No apps selected."; exit 1; }

# Build list of files: base + each app fragment
files=("$COMPOSE_DIR/base.yml")
for app in $APPS_NORMALIZED; do
  f="$COMPOSE_DIR/${app}.yml"
  if [[ -f "$f" ]]; then files+=("$f"); else echo "Warning: missing fragment: $f" >&2; fi
done

# If yq exists, do a proper deep merge
if command -v yq >/dev/null 2>&1; then
  if [[ "$DRY_RUN" = "1" ]]; then
    yq eval-all 'reduce .[] as $item ({}; . * $item)' "${files[@]}"
    exit 0
  else
    yq eval-all 'reduce .[] as $item ({}; . * $item)' "${files[@]}" > "$OUT"
    echo "Wrote $OUT"
    exit 0
  fi
fi

# Fallback: manual merge
# Strategy:
#  1) Start from base.yml verbatim
#  2) Append ALL service entries from each fragment WITHOUT repeating "services:" header
# Assumptions: fragments only define under "services:" top-level

# Load base into a temp and ensure it has a top-level 'services:' key
tmp="$(mktemp)"
cat "$COMPOSE_DIR/base.yml" > "$tmp"

# Check if base has a 'services:' key; if not, append it
if ! grep -qE '^[[:space:]]*services:[[:space:]]*$' "$tmp"; then
  printf "\nservices:\n" >> "$tmp"
fi

# Function: append services from a fragment (strip first 'services:' line)
append_fragment_services () {
  local frag="$1"
  # Print everything AFTER the first 'services:' line
  awk '
    BEGIN{found=0}
    /^[[:space:]]*services:[[:space:]]*$/ {found=1; next}
    { if(found) print }
  ' "$frag" >> "$tmp"
}

# Append each fragment's service entries
for f in "${files[@]:1}"; do
  append_fragment_services "$f"
done

if [[ "$DRY_RUN" = "1" ]]; then
  cat "$tmp"
  rm -f "$tmp"
  exit 0
else
  mv "$tmp" "$OUT"
  echo "Wrote $OUT"
fi
