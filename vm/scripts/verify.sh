#!/usr/bin/env bash
# verify.sh — proves all 10 flags are reachable, run from the host but
# exercising the guest's own loopback (via SSH) for every step, so FTP
# passive-mode/NAT quirks of this particular qemu test rig never matter
# -- what's tested is the same thing a real player would reach once
# this is exported and imported with real (bridged/host-only) networking.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="keys/ctfbuilder_ed25519"
PORT=2201
HOST="ctfbuilder@127.0.0.1"
SSH_OPTS=(-i "$KEY" -p "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10)
RELEASE_SECRET=$(cat ../organizer/release-secret.txt)
JMILLER_PASS="superman1"

SSH() { ssh "${SSH_OPTS[@]}" "$HOST" "$@"; }

check() {
    local n="$1" got="$2"
    local want
    want=$(python3 -c "
import hmac, hashlib
d = hmac.new('$RELEASE_SECRET'.encode(), f'noob-orientation-server:$n'.encode(), hashlib.sha256).hexdigest()
print(f'HLC{{{d[:10]}}}')")
    if [ "$got" = "$want" ]; then
        echo "flag $n: OK ($got)"
    else
        echo "flag $n: MISMATCH got='$got' want='$want'" >&2
        exit 1
    fi
}

F1=$(SSH "curl -s http://localhost/ | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 1 "$F1"

F2=$(SSH "curl -s http://localhost/welcome/ | grep -oE 'HLC\{[a-f0-9]{10}\}'")
check 2 "$F2"

F3=$(SSH "curl -s ftp://anonymous:@localhost/flag3.txt")
check 3 "$F3"

F4=$(SSH "curl -s http://localhost/files/notes.txt | grep -oE '[A-Za-z0-9+/=]{20,}' | tail -1 | base64 -d")
check 4 "$F4"

F5=$(SSH "curl -s http://localhost/files/cipher.txt | python3 -c \"import sys,codecs;print(codecs.decode(sys.stdin.read().strip(),'rot_13'))\"")
check 5 "$F5"

SSH "curl -s http://localhost/files/secrets.zip -o /tmp/secrets.zip && unzip -P 1973 -o /tmp/secrets.zip -d /tmp >/dev/null"
F6=$(SSH "cat /tmp/flag6.txt")
check 6 "$F6"

F7=$(SSH "curl -s http://localhost/files/handoff.enc -o /tmp/handoff.enc && openssl enc -aes-256-cbc -pbkdf2 -d -k $JMILLER_PASS -in /tmp/handoff.enc")
check 7 "$F7"

F8=$(SSH "sshpass -p $JMILLER_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jmiller@localhost cat flag8.txt" 2>&1 | tail -1) || true
if [ -z "${F8:-}" ]; then
    # sshpass may not be installed on the guest -- fall back to a
    # direct password login via expect-free trick isn't available, so
    # install sshpass on the guest first (one-time, harmless).
    SSH "sudo apt-get install -y -qq sshpass >/dev/null 2>&1"
    F8=$(SSH "sshpass -p $JMILLER_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jmiller@localhost cat flag8.txt")
fi
check 8 "$F8"

F9=$(SSH "sshpass -p $JMILLER_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jmiller@localhost cat .config/.flag9")
check 9 "$F9"

# Base64-wrapped end to end so none of the several layers of quoting
# between here and the guest's sudo python3 collide with each other.
INNER_CMD_B64=$(printf '%s' 'cat /root/flag10.txt' | base64 -w0)
F10=$(SSH "sshpass -p $JMILLER_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null jmiller@localhost \"sudo python3 -c 'import subprocess,base64; print(subprocess.run(base64.b64decode(\\\"$INNER_CMD_B64\\\").decode(), shell=True, capture_output=True, text=True).stdout.strip())'\"")
check 10 "$F10"

echo
echo "All 10 flags verified end-to-end."
