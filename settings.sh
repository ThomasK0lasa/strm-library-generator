#!/bin/bash
# settings.sh — StrmLibGenerator configuration

# Library mappings: SOURCE_PATH:STRM_PATH
export SLG_LIBRARIES=(
    "/volume1/Media/Movies:/volume1/Media/Movies_meta/POLISH/"
    "/volume1/Media/Movies:/volume1/Media/Movies_meta/ENGLISH/"
    "/volume1/Media/Movies:/volume1/Media/Movies_meta/GERMAN/"
)

# Video file extensions for which .strm files are created
export SLG_VIDEO_EXTENSIONS=("mkv" "mp4" "mov" "m4v" "avi")

# Subtitle file extensions to sync between source and STRM folders
export SLG_SUBTITLE_EXTENSIONS=("srt" "ass" "ssa" "sub" "idx" "vtt" "sup")

# Set to "true" to enable subtitle syncing between source and STRM folders
export SLG_SYNC_SUBS="true"

# Log files
export SLG_LOG_RUN_STRM_SYNC="/var/log/slg_run_strm_sync.log"
export SLG_LOG_WATCHER="/var/log/slg_watcher.log"
export SLG_LOG_RUN_SUB_SYNC="/var/log/slg_run_sub_sync.log"
