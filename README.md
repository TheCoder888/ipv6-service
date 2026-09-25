# IPv6 change service

A small systemd service for Pop!_OS that checks the current outbound IPv6
address every five minutes, runs a command when it changes, and saves the new
address after the command succeeds.

## Install

```bash
chmod +x install.sh
sudo ./install.sh
```

The installer installs the No-IP updater at
`/usr/local/libexec/noip-ipv6-update` and configures it as the service command.
You only need to edit `/etc/default/noip-ipv6` with your No-IP credentials.
The updater receives the current IPv6 as `CURRENT_IPV6` from the checker.

For the No-IP updater included in this project, configure its credentials and
hostname first:

```bash
sudo nano /etc/default/noip-ipv6
sudo chmod 0600 /etc/default/noip-ipv6
```

It sends both the IPv4 address from `IPV4_INTERFACE` (default `eno1`) and the
current IPv6 address to No-IP. To select another IPv4 interface:

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