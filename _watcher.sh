#!/bin/bash
# _watcher.sh — Main watcher for StrmLibGenerator.
# Starts a single inotifywait instance and routes events to strm_handler and sub_handler.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/settings.sh"
. "$SCRIPT_DIR/_strm_handler.sh"
[[ "${SLG_SYNC_SUBS}" == "true" ]] && . "$SCRIPT_DIR/_sub_handler.sh"

strm_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "${SLG_LOG_WATCHER:-/var/log/slg_watcher.log}"; }
sub_log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "${SLG_LOG_WATCHER:-/var/log/slg_watcher.log}"; }

# Build deduplicated source roots
declare -A _seen
source_roots=()
for mapping in "${SLG_LIBRARIES[@]}"; do
    src="${mapping%%:*}"
    if [[ -z "${_seen[$src]+x}" ]]; then
        source_roots+=("$src")
        _seen[$src]=1
    fi
done

# Build deduplicated strm roots
strm_roots=()
for mapping in "${SLG_LIBRARIES[@]}"; do
    dst="${mapping##*:}"
    if [[ -z "${_seen[$dst]+x}" ]]; then
        strm_roots+=("$dst")
        _seen[$dst]=1
    fi
done
unset _seen

watch_roots=("${source_roots[@]}")
[[ "${SLG_SYNC_SUBS}" == "true" ]] && watch_roots+=("${strm_roots[@]}")

strm_log "=== Watcher started ==="
strm_log "STRM watching: ${source_roots[*]}"
if [[ "${SLG_SYNC_SUBS}" == "true" ]]; then
    strm_log "Sub sync enabled, also watching: ${strm_roots[*]}"
    sub_log "=== Sub Sync started ==="
    sub_log "Watching: ${watch_roots[*]}"
    sub_log ""
fi
strm_log ""

while IFS=$'\t' read -r event dir filename; do

    full_path="${dir}${filename}"
    event_type="${event%%,*}"

    strm_handle_event "$event_type" "$full_path" "$filename"
    [[ "${SLG_SYNC_SUBS}" == "true" ]] && sub_handle_event "$event_type" "$full_path" "$filename"

done < <(inotifywait -m -r \
    -e create -e delete -e moved_from -e moved_to -e close_write \
    --format "$(printf '%s\t%s\t%s' '%e' '%w' '%f')" \
    "${watch_roots[@]}")