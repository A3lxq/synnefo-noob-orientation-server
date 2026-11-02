#!/usr/bin/env bash
# provision.sh — runs ON THE HOST. Copies this box's own repo into the
# VM, installs the systemd unit that starts it on every boot, brings
# it up now, and leaves the VM ready to verify (./scripts/verify.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="keys/ctfbuilder_ed25519"
PORT=2201
HOST="ctfbuilder@127.0.0.1"
SSH_OPTS=(-i "$KEY" -p "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10)

echo "== Waiting for SSH =="
for i in $(seq 1 60); do
  if ssh "${SSH_OPTS[@]}" "$HOST" 'echo ok' >/dev/null 2>&1; then
    echo "SSH is up."
    break
  fi
  sleep 5
  if [ "$i" -eq 60 ]; then
    echo "VM never came up over SSH after 5 minutes." >&2
    exit 1
  fi
done

echo "== Waiting for cloud-init to fully finish (package installs, etc.) =="
# SSH coming up only means the users/network stage is done -- package
# installation (docker.io) can still be running. Without this, docker
# isn't installed yet when we try to use it below.
ssh "${SSH_OPTS[@]}" "$HOST" 'sudo cloud-init status --wait'

echo "== Copying the box's own repo into the VM (/opt/box) =="
ssh "${SSH_OPTS[@]}" "$HOST" 'sudo mkdir -p /opt/box && sudo chown ctfbuilder:ctfbuilder /opt/box'
rsync -az -e "ssh ${SSH_OPTS[*]}" \
  --exclude ".git" --exclude "vm" --exclude ".env" \
  ../ "$HOST:/opt/box/"

echo "== Installing the boot-time systemd unit =="
scp -i "$KEY" -P "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null \
  ctf-box.service "$HOST:/tmp/ctf-box.service"
ssh "${SSH_OPTS[@]}" "$HOST" bash -s <<'REMOTE'
set -euo pipefail
sudo chmod +x /opt/box/*.sh
sudo mv /tmp/ctf-box.service /etc/systemd/system/ctf-box.service
sudo systemctl daemon-reload
sudo systemctl enable ctf-box.service
sudo systemctl restart ctf-box.service
sleep 3
sudo systemctl --no-pager --full status ctf-box.service | head -10
REMOTE

echo "Done. Next: ./scripts/verify.sh"
