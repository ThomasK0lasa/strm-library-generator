#!/bin/bash
# _strm_handler.sh — STRM file creation/deletion logic.
# Sourced by watcher.sh — do not run directly.

. "$SCRIPT_DIR/_strm_funcs.sh"

strm_handle_event() {
    local event_type="$1"
    local full_path="$2"
    local filename="$3"

    while IFS= read -r mapping; do
        local source_root="${mapping%%:*}"
        local strm_root="${mapping##*:}"
        local relative="${full_path#$source_root/}"
        local strm_target="$strm_root/$relative"

        case "$event_type" in

            CREATE|MOVED_TO)
                if [[ -d "$full_path" ]]; then
                    mkdir -p "$strm_target"
                    strm_log "[+] Folder created: $strm_target"
                    while IFS= read -r -d '' media_file; do
                        is_video "$media_file" || continue
                        local local_rel="${media_file#$source_root/}"
                        local local_dir
                        local_dir="$(dirname "$local_rel")"
                        local local_strm_dir="$strm_root/$local_dir"
                        local local_strm="$local_strm_dir/$(basename "${media_file%.*}").strm"
                        mkdir -p "$local_strm_dir"
                        echo "$media_file" > "$local_strm"
                        strm_log "[+] STRM created: $local_strm"
                    done < <(find "$full_path" -type f -print0)
                elif is_video "$filename"; then
                    local strm_dir="$strm_root/$(dirname "$relative")"
                    local strm_file="$strm_dir/$(basename "${filename%.*}").strm"
                    mkdir -p "$strm_dir"
                    echo "$full_path" > "$strm_file"
                    strm_log "[+] STRM created: $strm_file"
                fi
                ;;

            DELETE|MOVED_FROM)
                if [[ -d "$strm_target" ]]; then
                    rm -rf "$strm_target"
                    strm_log "[-] Folder removed: $strm_target"
                elif is_video "$filename"; then
                    local strm_file="$strm_root/$(dirname "$relative")/$(basename "${filename%.*}").strm"
                    if [[ -f "$strm_file" ]]; then
                        rm -f "$strm_file"
                        strm_log "[-] STRM removed: $strm_file"
                    fi
                fi
                ;;

        esac
    done < <(get_strm_mappings_for "$full_path")
}
