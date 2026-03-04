#!/bin/bash
# _strm_funcs.sh — Shared STRM utility functions.
# Sourced by strm_handler.sh and run_strm_sync.sh — do not run directly.

is_video() {
    local ext="${1##*.}"
    for e in "${SLG_VIDEO_EXTENSIONS[@]}"; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

get_strm_mappings_for() {
    local source_path="$1"
    for mapping in "${SLG_LIBRARIES[@]}"; do
        local source_root="${mapping%%:*}"
        if [[ "$source_path" == "$source_root"* ]]; then
            echo "$mapping"
        fi
    done
}
