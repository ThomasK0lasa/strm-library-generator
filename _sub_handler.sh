#!/bin/bash
# _sub_handler.sh — Subtitle sync logic.
# Sourced by watcher.sh — do not run directly.

. "$SCRIPT_DIR/_sub_funcs.sh"

# Cooldown tracking — prevents sync loops when copying files triggers new events
declare -A _sub_cooldown
COOLDOWN_SECS=3

sub_handle_event() {
    local event_type="$1"
    local full_path="$2"
    local filename="$3"

    is_subtitle "$filename" || return
    sub_is_recently_synced "$full_path" && return

    local source_root strm_root
    source_root=$(_get_source_root "$full_path")
    strm_root=$(_get_strm_root_for_path "$full_path")

    case "$event_type" in
        CREATE|MOVED_TO|CLOSE_WRITE)
            if [[ -n "$source_root" ]]; then
                _handle_source_sub_create "$full_path"
            elif [[ -n "$strm_root" ]]; then
                _handle_strm_sub_create "$full_path"
            fi
            ;;
        DELETE|MOVED_FROM)
            if [[ -n "$source_root" ]]; then
                _handle_source_sub_delete "$full_path"
            elif [[ -n "$strm_root" ]]; then
                _handle_strm_sub_delete "$full_path"
            fi
            ;;
    esac
}

_handle_source_sub_create() {
    local file="$1"
    local source_root
    source_root=$(_get_source_root "$file")
    local relative="${file#$source_root/}"
    while IFS= read -r strm_root; do
        _sub_sync_file "$file" "$strm_root/$relative"
    done < <(_get_strm_roots_for_source "$source_root")
}

_handle_strm_sub_create() {
    local file="$1"
    local strm_root
    strm_root=$(_get_strm_root_for_path "$file")
    local relative="${file#$strm_root/}"
    local source_root
    source_root=$(_get_source_for_strm "$strm_root")

    _sub_sync_file "$file" "$source_root/$relative"

    while IFS= read -r other_strm_root; do
        [[ "$other_strm_root" == "$strm_root" ]] && continue
        _sub_sync_file "$file" "$other_strm_root/$relative"
    done < <(_get_strm_roots_for_source "$source_root")
}

_handle_source_sub_delete() {
    local file="$1"
    local source_root
    source_root=$(_get_source_root "$file")
    local relative="${file#$source_root/}"
    while IFS= read -r strm_root; do
        local dst="$strm_root/$relative"
        if [[ -f "$dst" ]]; then
            _sub_mark_synced "$dst"
            rm -f "$dst"
            sub_log "[-] Deleted: $dst"
        fi
    done < <(_get_strm_roots_for_source "$source_root")
}

_handle_strm_sub_delete() {
    local file="$1"
    local strm_root
    strm_root=$(_get_strm_root_for_path "$file")
    local relative="${file#$strm_root/}"
    local source_root
    source_root=$(_get_source_for_strm "$strm_root")
    local source_file="$source_root/$relative"

    if [[ -f "$source_file" ]]; then
        _sub_mark_synced "$source_file"
        rm -f "$source_file"
        sub_log "[-] Deleted: $source_file"
    fi

    while IFS= read -r other_strm_root; do
        [[ "$other_strm_root" == "$strm_root" ]] && continue
        local dst="$other_strm_root/$relative"
        if [[ -f "$dst" ]]; then
            _sub_mark_synced "$dst"
            rm -f "$dst"
            sub_log "[-] Deleted: $dst"
        fi
    done < <(_get_strm_roots_for_source "$source_root")
}

sub_is_recently_synced() {
    local path="$1"
    local ts="${_sub_cooldown[$path]}"
    [[ -z "$ts" ]] && return 1
    local now
    now=$(date +%s)
    if (( now - ts < COOLDOWN_SECS )); then
        return 0
    fi
    unset "_sub_cooldown[$path]"
    return 1
}

_sub_mark_synced() {
    _sub_cooldown["$1"]=$(date +%s)
}

_sub_sync_file() {
    local src="$1"
    local dst="$2"
    if [[ ! -f "$dst" ]] || [[ "$src" -nt "$dst" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -p "$src" "$dst"
        _sub_mark_synced "$dst"
        sub_log "[>] Synced: $src -> $dst"
    fi
}
