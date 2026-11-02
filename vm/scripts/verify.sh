#!/usr/bin/env bash
# verify.sh — runs this box's own tests/solve.sh INSIDE the VM (over
# SSH), proving the OVA is solvable end to end before it's exported.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="keys/ctfbuilder_ed25519"
PORT=2201
HOST="ctfbuilder@127.0.0.1"
SSH_OPTS=(-i "$KEY" -p "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10)

ssh "${SSH_OPTS[@]}" "$HOST" 'cd /opt/box && bash tests/solve.sh'
