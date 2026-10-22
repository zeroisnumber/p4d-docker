#!/bin/sh
# Starts p4d in the foreground. Extra arguments are passed through to p4d.
#   P4ROOT    server root (db.* files)            default /p4/root
#   P4PORT    listen address                       default 1666
#   P4D_CASE  case handling for a NEW server only  0 = sensitive, 1 = insensitive
set -e

mkdir -p "$P4ROOT"
cd "$P4ROOT"

# Case handling can only be chosen when the database is first created.
if [ ! -f db.counters ] && [ -n "$P4D_CASE" ]; then
  set -- -C"$P4D_CASE" "$@"
fi

exec /opt/perforce/sbin/p4d -r "$P4ROOT" -p "$P4PORT" "$@"
