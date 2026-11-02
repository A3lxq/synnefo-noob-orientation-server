#!/bin/bash
# Automated end-to-end solver, used only to prove the box is solvable before
# publishing it. Requires: curl, ftp (or curl with ftp://), python3, zip,
# unzip, openssl, sshpass, sudo-capable python3 inside the container via ssh.
#
# Run from the box's own root dir, with the stack already up (./start.sh)
# and CTF_SECRET exported from the same .env used to start it.
set -euo pipefail
cd "$(dirname "$0")/.."

HOST=localhost
WEB_PORT=8001
FTP_PORT=2101
SSH_PORT=2201
SSH_PASS="superman1"
ZIP_PIN="1973"

source .env
export CTF_SECRET

check() {
    local n="$1" got="$2"
    local want
    want=$(python3 docker/generate_flags.py "$n")
    if [ "$got" = "$want" ]; then
        echo "flag $n: OK ($got)"
    else
        echo "flag $n: MISMATCH got='$got' want='$want'" >&2
        exit 1
    fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# 1
F1=$(curl -s "http://$HOST:$WEB_PORT/" | grep -oE 'HLC\{[a-f0-9]{10}\}' | head -1)
check 1 "$F1"

# 2
F2=$(curl -s "http://$HOST:$WEB_PORT/welcome/" | grep -oE 'HLC\{[a-f0-9]{10}\}' | head -1)
check 2 "$F2"

# 3
F3=$(curl -s "ftp://anonymous:@$HOST:$FTP_PORT/flag3.txt")
check 3 "$F3"

# 4
curl -s "http://$HOST:$WEB_PORT/files/notes.txt" -o "$WORK/notes.txt"
B64=$(grep -oE '[A-Za-z0-9+/=]{20,}' "$WORK/notes.txt" | tail -1)
F4=$(echo "$B64" | base64 -d)
check 4 "$F4"

# 5
curl -s "http://$HOST:$WEB_PORT/files/cipher.txt" -o "$WORK/cipher.txt"
F5=$(python3 -c "import codecs;print(codecs.decode(open('$WORK/cipher.txt').read().strip(),'rot_13'))")
check 5 "$F5"

# 6
curl -s "http://$HOST:$WEB_PORT/files/secrets.zip" -o "$WORK/secrets.zip"
unzip -P "$ZIP_PIN" -o "$WORK/secrets.zip" -d "$WORK" >/dev/null
F6=$(cat "$WORK/flag6.txt")
check 6 "$F6"

# 7
curl -s "http://$HOST:$WEB_PORT/files/handoff.enc" -o "$WORK/handoff.enc"
F7=$(openssl enc -aes-256-cbc -pbkdf2 -d -k "$SSH_PASS" -in "$WORK/handoff.enc")
check 7 "$F7"

# 8, 9, 10 via ssh (requires sshpass)
F8=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" jmiller@"$HOST" "cat flag8.txt")
check 8 "$F8"

F9=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" jmiller@"$HOST" "cat .config/.flag9")
check 9 "$F9"

F10=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" jmiller@"$HOST" \
    "sudo /usr/bin/python3 -c \"print(open('/root/flag10.txt').read().strip())\"")
check 10 "$F10"

echo
echo "All 10 flags verified end-to-end."
