#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"
cat >"$test_dir/bin/ip" <<'EOF'
#!/usr/bin/env bash
printf '2001:db8::/64 dev eth0 src %s metric 100\n' "$STUB_IPV6"
EOF
chmod +x "$test_dir/bin/ip"

export PATH="$test_dir/bin:$PATH"
export STATE_FILE="$test_dir/state/current-ipv6"
export CHANGE_COMMAND='printf "%s,%s\n" "$OLD_IPV6" "$CURRENT_IPV6" >> "$CHANGE_LOG"'
export CHANGE_LOG="$test_dir/changes"

export STUB_IPV6=2001:db8::1
bash "$project_dir/ipv6-check"
[[ $(<"$STATE_FILE") == 2001:db8::1 ]]
[[ $(wc -l <"$CHANGE_LOG") -eq 1 ]]

bash "$project_dir/ipv6-check"
[[ $(wc -l <"$CHANGE_LOG") -eq 1 ]]

export STUB_IPV6=2001:db8::2
bash "$project_dir/ipv6-check"
[[ $(<"$STATE_FILE") == 2001:db8::2 ]]
[[ $(wc -l <"$CHANGE_LOG") -eq 2 ]]

export STUB_IPV6=2001:db8::3
export CHANGE_COMMAND=false
if bash "$project_dir/ipv6-check"; then
    echo "Expected a failing change command to fail the check" >&2
    exit 1
fi
[[ $(<"$STATE_FILE") == 2001:db8::2 ]]

echo "All tests passed"
