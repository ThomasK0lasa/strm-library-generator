#!/bin/bash
# _sub_funcs.sh — Shared subtitle utility functions.
# Sourced by sub_handler.sh and run_sub_sync.sh — do not run directly.

is_subtitle() {
    local ext="${1##*.}"
    for e in "${SLG_SUBTITLE_EXTENSIONS[@]}"; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

_get_source_root() {
    local path="$1"
    for mapping in "${SLG_LIBRARIES[@]}"; do
        local source_root="${mapping%%:*}"
        if [[ "$path" == "$source_root"* ]]; then
            echo "$source_root"
            return
        fi
    done
}

_get_strm_root_for_path() {
    local path="$1"
    for mapping in "${SLG_LIBRARIES[@]}"; do
        local strm_root="${mapping##*:}"
        if [[ "$path" == "$strm_root"* ]]; then
            echo "$strm_root"
            return
        fi
    done
}

_get_source_for_strm() {
    local strm_root="$1"
    for mapping in "${SLG_LIBRARIES[@]}"; do
        local source_root="${mapping%%:*}"
        local mapped_strm="${mapping##*:}"
        if [[ "$strm_root" == "$mapped_strm" ]]; then
            echo "$source_root"
            return
        fi
    done
}

_get_strm_roots_for_source() {
    local source_root="$1"
    for mapping in "${SLG_LIBRARIES[@]}"; do
        local mapped_source="${mapping%%:*}"
        local strm_root="${mapping##*:}"
        if [[ "$mapped_source" == "$source_root" ]]; then
            echo "$strm_root"
        fi
    done
}
