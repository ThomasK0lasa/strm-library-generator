#!/bin/bash
# run_sub_sync.sh — Full scan: syncs subtitle files between source and STRM folders.
# Source -> all mapped STRM folders, STRM -> source and other STRM folders.
# Newer file wins in both directions.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/settings.sh"
. "$SCRIPT_DIR/_sub_funcs.sh"

LOG="${SLG_LOG_RUN_SUB_SYNC:-/var/log/slg_run_sub_sync.log}"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

sync_file() {
    local src="$1"
    local dst="$2"
    if [[ ! -f "$dst" ]] || [[ "$src" -nt "$dst" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -p "$src" "$dst"
        log "[>] Synced: $src -> $dst"
    fi
}

log "=== Sub Sync started ==="

declare -A _seen_sources
declare -A _seen_strm

for mapping in "${SLG_LIBRARIES[@]}"; do
    source_root="${mapping%%:*}"
    strm_root="${mapping##*:}"

    # Pass 1: source -> all STRM roots
    if [[ -z "${_seen_sources[$source_root]+x}" ]]; then
        _seen_sources[$source_root]=1
        log "Scanning source: $source_root"
        while IFS= read -r -d '' file; do
            is_subtitle "$file" || continue
            relative="${file#$source_root/}"
            while IFS= read -r dst_strm_root; do
                sync_file "$file" "$dst_strm_root/$relative"
            done < <(_get_strm_roots_for_source "$source_root")
        done < <(find "$source_root" -type f -print0)
    fi

    # Pass 2: STRM -> source and other STRM roots
    if [[ -z "${_seen_strm[$strm_root]+x}" ]]; then
        _seen_strm[$strm_root]=1
        log "Scanning STRM: $strm_root"
        src_root=$(_get_source_for_strm "$strm_root")
        while IFS= read -r -d '' file; do
            is_subtitle "$file" || continue
            relative="${file#$strm_root/}"
            sync_file "$file" "$src_root/$relative"
            while IFS= read -r other_strm_root; do
                [[ "$other_strm_root" == "$strm_root" ]] && continue
                sync_file "$file" "$other_strm_root/$relative"
            done < <(_get_strm_roots_for_source "$src_root")
        done < <(find "$strm_root" -type f -print0)
    fi

done

log "=== Sub Sync finished ==="
