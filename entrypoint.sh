#!/bin/sh
set -eu

# dsh rejects wildcard binds, so bind the container's own address.
bind_ip="${DSH_BIND_IP:-$(hostname -i | awk '{print $1}')}"

exec dsh web --no-open --host "$bind_ip" --port "${DSH_PORT:-3080}" "$@"
