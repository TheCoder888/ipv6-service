#!/usr/bin/env bash

set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
    echo "Run this installer as root: sudo ./install.sh" >&2
    exit 1
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

install -D -m 0755 "$source_dir/ipv6-check" /usr/local/libexec/ipv6-check
install -D -m 0755 "$source_dir/noip-ipv6-update" /usr/local/libexec/noip-ipv6-update
install -D -m 0644 "$source_dir/ipv6-check.service" /etc/systemd/system/ipv6-check.service
install -D -m 0644 "$source_dir/ipv6-check.timer" /etc/systemd/system/ipv6-check.timer

if [[ ! -e /etc/default/ipv6-check ]]; then
    install -m 0644 "$source_dir/ipv6-check.default" /etc/default/ipv6-check
fi
if [[ ! -e /etc/default/noip-ipv6 ]]; then
    install -m 0600 "$source_dir/noip-ipv6.default" /etc/default/noip-ipv6
fi

systemctl daemon-reload
systemctl enable --now ipv6-check.timer

echo "Installed. Configure /etc/default/noip-ipv6, then run:"
echo "  sudo systemctl start ipv6-check.service"
