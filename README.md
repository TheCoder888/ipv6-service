# IPv6 change service

A small systemd service for Pop!_OS that checks the current outbound IPv6
address every five minutes, runs a command when it changes, and saves the new
address after the command succeeds.

## Install

```bash
chmod +x install.sh
sudo ./install.sh
```

Edit `/etc/default/ipv6-check` and set `CHANGE_COMMAND`. The command can use
the `CURRENT_IPV6` and `OLD_IPV6` environment variables.

## Configuration examples

### Run a local script

Pass both addresses to a script that updates your DNS provider, firewall, or
another machine:

```bash
CHANGE_COMMAND='/usr/local/bin/update-dns "$CURRENT_IPV6" "$OLD_IPV6"'
```

The called script receives the new address as its first argument and the old
address as its second argument. A minimal example script is:

```bash
#!/usr/bin/env bash
set -euo pipefail

new_ipv6=$1
old_ipv6=${2:-}

printf 'IPv6 changed from %s to %s\n' "${old_ipv6:-<none>}" "$new_ipv6"
# Add the DNS provider or deployment command here.
```

Install it with:

```bash
sudo install -m 0755 update-dns /usr/local/bin/update-dns
```

### Update DuckDNS

Replace `my-hostname` and `YOUR_DUCKDNS_TOKEN` with your DuckDNS details:

```bash
CHANGE_COMMAND='curl --fail --silent --show-error "https://www.duckdns.org/update?domains=my-hostname&token=YOUR_DUCKDNS_TOKEN&ipv6=$CURRENT_IPV6"'
```

Because this example contains a token, restrict access to the configuration:

```bash
sudo chmod 0600 /etc/default/ipv6-check
```

### Send an ntfy notification

Replace the topic with a private, hard-to-guess topic name:

```bash
CHANGE_COMMAND='curl --fail --silent --show-error -d "IPv6 changed from ${OLD_IPV6:-none} to $CURRENT_IPV6" https://ntfy.sh/my-private-topic'
```

### Select a network interface

If the machine has multiple interfaces, list them and configure the one used
for the IPv6 route:

```bash
ip -brief link
```

Then set it in `/etc/default/ipv6-check`:

```bash
INTERFACE=enp3s0
```

Leave `INTERFACE` empty to let the kernel select the outbound route. The first
run counts as a change because no address has been saved yet.

After changing the configuration, trigger a check immediately:

```bash
sudo systemctl start ipv6-check.service
```

For example, confirm the address that the service will detect without sending
any network traffic:

```bash
ip -6 route get 2606:4700:4700::1111
```

## Check status

```bash
systemctl status ipv6-check.timer
systemctl list-timers ipv6-check.timer
sudo journalctl -u ipv6-check.service
cat /var/lib/ipv6-check/current-ipv6
```

Follow new service logs in real time:

```bash
sudo journalctl -fu ipv6-check.service
```

The timer retries on its next run if the route lookup or change command fails.

## Test

```bash
./test.sh
```