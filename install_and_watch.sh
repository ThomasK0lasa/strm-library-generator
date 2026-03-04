#!/bin/bash
# install_and_watch.sh — Installs and starts the watcher as a systemd service.
# Add to Synology Task Scheduler as a boot-triggered task.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/settings.sh"

LOG="${SLG_LOG_WATCHER:-/var/log/slg_watcher.log}"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

cp "$SCRIPT_DIR/slg_watcher.service" /etc/systemd/system/slg_watcher.service
systemctl daemon-reload
log "Service file installed."

if systemctl is-active --quiet slg_watcher; then
    log "Watcher service is already running, skipping."
else
    systemctl enable slg_watcher
    systemctl start slg_watcher
    log "Watcher service started."
fi
