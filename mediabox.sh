#!/usr/bin/env bash
set -euo pipefail
### MBX FLAGS BEGIN
# Minimal helper: read/modify apps in prep/config.yml without hard dependency on yq
MBX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MBX_CFG="$MBX_ROOT/prep/config.yml"
MBX_COMPOSE_DIR="$MBX_ROOT/compose"

mbx_normalize_list(){ echo "$*" | tr ',;' '  ' | xargs; }

mbx_enabled_apps(){
  if command -v yq >/dev/null 2>&1; then
    yq '.apps | to_entries | map(select(.value==true)) | .[].key' "$MBX_CFG"
  else
    awk '/^apps:/{flag=1;next}/^[^[:space:]]/{flag=0}flag' "$MBX_CFG" \
      | grep -E ':[[:space:]]*true' | cut -d: -f1
  fi
}

mbx_set_app_state(){ # app state(true|false)
  local app="$1" state="$2"
  if command -v yq >/dev/null 2>&1; then
    tmp="$(mktemp)"; yq -y ".apps.${app} = ${state}" "$MBX_CFG" > "$tmp" && mv "$tmp" "$MBX_CFG"
  else
    # ensure key exists; then set value
    grep -q "^[[:space:]]*$app:" "$MBX_CFG" || printf "  %s: %s\n" "$app" "$state" >> "$MBX_CFG"
    awk -v K="$app" -v V="$state" '
      BEGIN{inapps=0}
      /^apps:/{inapps=1; print; next}
      /^[^[:space:]]/ && inapps==1 {inapps=0}
      { if(inapps==1){
          gsub("^([[:space:]]*)" K ":[[:space:]]*(true|false).*","\\1" K ": " V)
        } print
      }' "$MBX_CFG" > "$MBX_CFG.tmp" && mv "$MBX_CFG.tmp" "$MBX_CFG"
  fi
}

mbx_list_available(){
  echo "Available app fragments in compose/:"
  shopt -s nullglob
  for f in "$MBX_COMPOSE_DIR"/*.yml; do
    base="$(basename "$f" .yml)"
    [[ "$base" == "base" ]] && continue
    echo "  - $base"
  done
  echo
  echo "Enabled in prep/config.yml:"
  mbx_enabled_apps | sed 's/^/  * /'
}

mbx_interactive_menu(){
  # simple toggle loop
  shopt -s nullglob
  mapfile -t ALL < <(for f in "$MBX_COMPOSE_DIR"/*.yml; do b="$(basename "$f" .yml)"; [[ "$b" != "base" ]] && echo "$b"; done | sort)
  declare -A enabled
  while read -r a; do enabled["$a"]=1; done < <(mbx_enabled_apps 2>/dev/null || true)

  while :; do
    echo
    echo "Select apps (toggle by number, ENTER to finish):"
    i=1
    for app in "${ALL[@]}"; do
      mark="[ ]"; [[ "${enabled[$app]:-0}" = "1" ]] && mark="[x]"
      printf "%2d) %s %s\n" "$i" "$mark" "$app"
      i=$((i+1))
    done
    read -rp "> " pick
    [[ -z "${pick:-}" ]] && break
    if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick>=1 && pick<=${#ALL[@]} )); then
      app="${ALL[$((pick-1))]}"
      if [[ "${enabled[$app]:-0}" = "1" ]]; then enabled["$app"]=0; else enabled["$app"]=1; fi
    else
      echo "Invalid choice."
    fi
  done

  # build APPS list and persist to config
  sel=()
  for app in "${ALL[@]}"; do
    if [[ "${enabled[$app]:-0}" = "1" ]]; then
      sel+=("$app")
      mbx_set_app_state "$app" true
    else
      mbx_set_app_state "$app" false
    fi
  done
  APPS="$(printf "%s " "${sel[@]}")"; export APPS
  echo "Selected: $APPS"
}

mbx_check_env(){
  # If a VPN client selected, make sure creds are present
  local need_vpn=0
  for a in $(echo "${APPS:-$(mbx_enabled_apps | xargs)}"); do
    [[ "$a" == "delugevpn" || "$a" == "qbittorrentvpn" ]] && need_vpn=1
  done
  if (( need_vpn )); then
    if ! grep -qE '^(VPN_USER|VPN_PASS)=' "$MBX_ROOT/.env" 2>/dev/null && { [[ -z "${VPN_USER:-}" ]] || [[ -z "${VPN_PASS:-}" ]]; }; then
      echo "⚠️  VPN-enabled client selected but VPN_USER/VPN_PASS not found (env or .env)."
      echo "    Set them in environment or in $MBX_ROOT/.env before launching."
      return 1
    fi
  fi
  return 0
}

# ---- Flag parsing (pre-flight) ----
MBX_DRY_RUN=0
MBX_NO_LAUNCH=0
MBX_DO_LIST=0
MBX_DO_ENABLE=""
MBX_DO_DISABLE=""
MBX_DO_INTERACTIVE=0
MBX_DO_CHECK_ENV=0

ARGS=("$@")
i=0
while (( i < ${#ARGS[@]} )); do
  arg="${ARGS[$i]}"
  case "$arg" in
    --list-apps) MBX_DO_LIST=1; i=$((i+1));;
    --enable)    MBX_DO_ENABLE="${ARGS[$((i+1))]:-}"; i=$((i+2));;
    --disable)   MBX_DO_DISABLE="${ARGS[$((i+1))]:-}"; i=$((i+2));;
    --interactive) MBX_DO_INTERACTIVE=1; i=$((i+1));;
    --dry-run)   MBX_DRY_RUN=1; i=$((i+1));;
    --no-launch) MBX_NO_LAUNCH=1; i=$((i+1));;
    --check-env) MBX_DO_CHECK_ENV=1; i=$((i+1));;
    --apps)      export APPS="${ARGS[$((i+1))]:-}"; i=$((i+2));;
    --apps=*)    export APPS="${arg#*=}"; i=$((i+1));;
    *)           # stop parsing at first unknown; let existing script handle the rest
                 break;;
  esac
done

# Execute flagged actions
if (( MBX_DO_LIST )); then
  mbx_list_available
  exit 0
fi

if [[ -n "$MBX_DO_ENABLE" ]]; then
  for a in $(mbx_normalize_list "$MBX_DO_ENABLE"); do mbx_set_app_state "$a" true; done
fi

if [[ -n "$MBX_DO_DISABLE" ]]; then
  for a in $(mbx_normalize_list "$MBX_DO_DISABLE"); do mbx_set_app_state "$a" false; done
fi

if (( MBX_DO_INTERACTIVE )); then
  mbx_interactive_menu
fi

if (( MBX_DO_CHECK_ENV )); then
  mbx_check_env || { echo "Environment check failed."; exit 1; }
fi

# If only managing config, allow exiting early with --no-launch
if (( MBX_NO_LAUNCH )) && (( MBX_DRY_RUN==0 )); then
  # Generate but do not launch
  DRY_RUN=0 OUT="$MBX_ROOT/docker-compose.generated.yml" APPS="${APPS:-}" bash "$MBX_ROOT/scripts/generate-compose.sh"
  echo "Skipping launch (--no-launch)."
  exit 0
fi

# If dry run, print the compose that would be used and exit
if (( MBX_DRY_RUN )); then
  DRY_RUN=1 APPS="${APPS:-}" bash "$MBX_ROOT/scripts/generate-compose.sh"
  exit 0
fi
### MBX FLAGS END
### MBX REQUIREMENTS BEGIN
mbx_selected_apps(){
  if [[ -n "${APPS:-}" ]]; then echo "$APPS" | tr ",;" "  " | xargs; else mbx_enabled_apps | xargs; fi
}

# Require: one download client, one manager, one player
mbx_check_requirements(){
  local ok_dl=0 ok_mgr=0 ok_player=0
  local sel; sel="$(mbx_selected_apps)"
  # groups
  local DL="delugevpn qbittorrentvpn sabnzbd"
  local MGR="radarr sonarr lidarr headphones"
  local PLAYER="plex emby jellyfin"
  for a in $sel; do
    for d in $DL; do [[ "$a" == "$d" ]] && ok_dl=1; done
    for m in $MGR; do [[ "$a" == "$m" ]] && ok_mgr=1; done
    for p in $PLAYER; do [[ "$a" == "$p" ]] && ok_player=1; done
  done
  local err=0
  if (( ! ok_dl )); then
    echo "❌ Selection missing a download client (choose one: delugevpn | qbittorrentvpn | sabnzbd)" >&2; err=1
  fi
  if (( ! ok_mgr )); then
    echo "❌ Selection missing a manager (choose one: radarr | sonarr | lidarr | headphones)" >&2; err=1
  fi
  if (( ! ok_player )); then
    echo "❌ Selection missing a player (choose one: plex | emby | jellyfin)" >&2; err=1
  fi
  if (( err )); then
    echo "Tip: use --interactive to toggle, or pass --apps \"plex sonarr delugevpn\"" >&2
    return 1
  fi
  return 0
}

# Run requirement check unless we are only listing apps
if (( MBX_DO_LIST==0 )); then
  mbx_check_requirements || exit 1
fi
### MBX REQUIREMENTS END
