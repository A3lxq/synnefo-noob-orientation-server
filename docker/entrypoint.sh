#!/bin/bash
set -euo pipefail

: "${CTF_SECRET:?CTF_SECRET must be set (see start.sh / .env)}"

WEB=/var/www/html
FTP=/srv/ftp
JMILLER_PASSWORD="superman1"   # intentionally weak, present in common wordlists (e.g. rockyou.txt)
ZIP_PIN="1973"                 # matches the badge-memo.txt in-fiction hint

flag() { python3 /opt/generate_flags.py "$1"; }

# --- 1: index.html comment -------------------------------------------------
sed -i "s/FLAG1_PLACEHOLDER/$(flag 1)/" "$WEB/index.html"

# --- 2: robots.txt -> /welcome/ --------------------------------------------
sed -i "s/FLAG2_PLACEHOLDER/$(flag 2)/" "$WEB/welcome/index.html"

# --- 3: anonymous FTP file --------------------------------------------------
sed -i "s/FLAG3_PLACEHOLDER/$(flag 3)/" "$FTP/flag3.txt"

# --- 4: base64 in notes.txt -------------------------------------------------
F4_B64=$(flag 4 | base64 -w0)
sed -i "s/NOTES_B64_PLACEHOLDER/$F4_B64/" "$WEB/files/notes.txt"

# --- 5: ROT13 in cipher.txt -------------------------------------------------
python3 - "$(flag 5)" > "$WEB/files/cipher.txt" <<'PYEOF'
import sys, codecs
print(codecs.encode(sys.argv[1], "rot_13"))
PYEOF

# --- 6: password-protected zip ---------------------------------------------
WORKDIR=$(mktemp -d)
echo "$(flag 6)" > "$WORKDIR/flag6.txt"
( cd "$WORKDIR" && zip --password "$ZIP_PIN" -q "$WEB/files/secrets.zip" flag6.txt )
rm -rf "$WORKDIR"

# --- 7: md5 hash to crack -> password unlocks an openssl-encrypted file ---
PW_MD5=$(printf '%s' "$JMILLER_PASSWORD" | md5sum | cut -d' ' -f1)
sed -i "s/PASSWORD_MD5_PLACEHOLDER/$PW_MD5/" "$WEB/files/password_audit.txt"
WORKDIR2=$(mktemp -d)
flag 7 > "$WORKDIR2/flag7.txt"
openssl enc -aes-256-cbc -pbkdf2 -salt -k "$JMILLER_PASSWORD" \
    -in "$WORKDIR2/flag7.txt" -out "$WEB/files/handoff.enc"
rm -rf "$WORKDIR2"

# --- jmiller unix account: password + flag8/flag9, sudo misconfig ---------
echo "jmiller:$JMILLER_PASSWORD" | chpasswd
HOME_J=/home/jmiller
flag 8 > "$HOME_J/flag8.txt"
mkdir -p "$HOME_J/.config"
flag 9 > "$HOME_J/.config/.flag9"
cat > "$HOME_J/.bash_history" <<'HIST'
ls -la
cat flag8.txt
whoami
id
sudo -l
HIST
chown -R jmiller:jmiller "$HOME_J"
chmod 600 "$HOME_J/.bash_history"

# GTFOBins-style NOPASSWD misconfig -> root
echo "jmiller ALL=(root) NOPASSWD: /usr/bin/python3" > /etc/sudoers.d/jmiller
chmod 440 /etc/sudoers.d/jmiller

# --- 10: root flag ----------------------------------------------------------
flag 10 > /root/flag10.txt
chmod 600 /root/flag10.txt

# SSH host keys (generated fresh per container if missing)
ssh-keygen -A >/dev/null 2>&1 || true

echo "[entrypoint] Orientation Server ready."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/ctf.conf
