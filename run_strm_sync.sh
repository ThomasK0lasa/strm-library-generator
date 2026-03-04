#!/bin/bash
# run_strm_sync.sh — Full scan: creates missing STRM files and removes orphaned ones.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/settings.sh"
. "$SCRIPT_DIR/_strm_funcs.sh"

LOG="${SLG_LOG_RUN_STRM_SYNC:-/var/log/slg_run_strm_sync.log}"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }


log "=== STRM Sync started ==="

for mapping in "${SLG_LIBRARIES[@]}"; do
    source_root="${mapping%%:*}"
    strm_root="${mapping##*:}"
    log "Processing: $source_root -> $strm_root"

    # Pass 1: create missing .strm files
    while IFS= read -r -d '' source_file; do
        is_video "$source_file" || continue
        relative="${source_file#$source_root/}"
        strm_dir="$strm_root/$(dirname "$relative")"
        strm_file="$strm_dir/$(basename "${source_file%.*}").strm"
        if [[ ! -f "$strm_file" ]]; then
            mkdir -p "$strm_dir"
            echo "$source_file" > "$strm_file"
            log "[+] Created: $strm_file"
        fi
    done < <(find "$source_root" -type f -print0)

    # Pass 2: remove orphaned .strm files
    while IFS= read -r -d '' strm_file; do
        relative="${strm_file#$strm_root/}"
        source_base="$source_root/${relative%.strm}"
        found=false
        for ext in "${SLG_VIDEO_EXTENSIONS[@]}"; do
            if [[ -f "$source_base.$ext" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            rm -f "$strm_file"
            log "[-] Removed orphan: $strm_file"
        fi
    done < <(find "$strm_root" -type f -name "*.strm" -print0)

    # Pass 3: remove folders in strm_root not present in source
    while IFS= read -r strm_dir; do
        relative="${strm_dir#$strm_root/}"
        if [[ ! -d "$source_root/$relative" ]]; then
            rm -rf "$strm_dir"
            log "[-] Removed folder: $strm_dir"
        fi
    done < <(find "$strm_root" -mindepth 1 -type d | sort -r)

done

log "=== STRM Sync finished ==="
