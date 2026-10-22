#!/bin/bash
# Daily checkpoint for a running p4d container. Run it on the Docker host,
# e.g. from cron or the Synology Task Scheduler (as root).
#   CONTAINER  container name                                default p4d
#   KEEP_DAYS  delete checkpoints/rotated journals older than default 30
#   CKP_DIR    where checkpoints land inside the container   default $P4ROOT
#   DOCKER     docker binary                                 default docker
set -euo pipefail

CONTAINER=${CONTAINER:-p4d}
KEEP_DAYS=${KEEP_DAYS:-30}
DOCKER=${DOCKER:-docker}

# p4d -jc works while the server is running (tables are locked briefly).
"$DOCKER" exec "$CONTAINER" sh -c '/opt/perforce/sbin/p4d -r "$P4ROOT" -jc -Z'

"$DOCKER" exec -e KEEP_DAYS="$KEEP_DAYS" -e CKP_DIR="${CKP_DIR:-}" "$CONTAINER" sh -c '
  find "${CKP_DIR:-$P4ROOT}" -maxdepth 1 -type f \
    \( -name "checkpoint.*" -o -name "journal.[0-9]*" -o -name "*.ckp.*" -o -name "*.jnl.*" \) \
    -mtime +"$KEEP_DAYS" -print -delete'
