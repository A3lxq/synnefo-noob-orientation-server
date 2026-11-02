#!/usr/bin/env bash
# remote-provision.sh — runs INSIDE the guest (invoked by provision.sh
# over SSH as ctfbuilder, with sudo). Native build: real nginx, vsftpd,
# openssh-server, no Docker anywhere. Idempotent.
#
# Flags are STATIC (same convention as The Forgotten Administrator's
# own VM): derived once from a fixed release secret at provisioning
# time, baked into this image. Not per-deployment-secret like a Docker
# build would be -- this IS the shipped artifact.
set -euo pipefail

: "${RELEASE_SECRET:?RELEASE_SECRET must be passed in (never hardcode it here -- this script is public)}"
JMILLER_PASSWORD="superman1"   # intentionally weak, present in common wordlists

flag() {
    python3 -c "
import hmac, hashlib
secret = '$RELEASE_SECRET'
d = hmac.new(secret.encode(), f'noob-orientation-server:$1'.encode(), hashlib.sha256).hexdigest()
print(f'HLC{{{d[:10]}}}')
"
}

echo "== Laying out web content (nginx) =="
sudo mkdir -p /var/www/html/welcome /var/www/html/admin /var/www/html/files
sudo tee /var/www/html/index.html >/dev/null <<EOF
<!DOCTYPE html>
<html>
<head><title>Halcyon Dynamics — Contractor Orientation</title></head>
<body>
<!-- jmiller, if you lock yourself out again, the flag below is just so IT can
     confirm you reached this page during setup. It's not the interesting one. -->
<!-- $(flag 1) -->
<h1>Welcome to Halcyon Dynamics</h1>
<p>This is the temporary onboarding server for new contractors. IT has not
finished locking this down yet — ticket IT-4417 is still open. Please check
back once the portal is finalized.</p>
<p>In the meantime, see the <a href="/files/">shared files</a> directory for
your starter materials, or ask your sponsor for the badge office link.</p>
</body>
</html>
EOF

sudo tee /var/www/html/robots.txt >/dev/null <<'EOF'
User-agent: *
Disallow: /welcome/
Disallow: /admin/
EOF

sudo tee /var/www/html/welcome/index.html >/dev/null <<EOF
<!DOCTYPE html>
<html>
<head><title>Welcome Packet</title></head>
<body>
<h1>Welcome Packet (Draft)</h1>
<p>Nobody has disabled directory listing or linked this page anywhere public
on purpose — it's just not finished. Congratulations on checking robots.txt
like Priya always said you should.</p>
<p>$(flag 2)</p>
<p>Your starter materials are in <a href="/files/">/files/</a>. Good luck —
some of it is more organized than the rest.</p>
</body>
</html>
EOF

sudo tee /var/www/html/admin/index.html >/dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Staff Login</title></head>
<body>
<h2>Halcyon Staff Portal</h2>
<form onsubmit="document.getElementById('r').innerText='Access denied. This incident has been logged. — IT Security'; return false;">
  <input type="text" placeholder="username"><br>
  <input type="password" placeholder="password"><br>
  <button type="submit">Log in</button>
</form>
<p id="r"></p>
<p><small>This panel has no backend. It never granted access to anyone,
including Priya. There is nothing behind it to find.</small></p>
</body>
</html>
EOF

sudo tee /var/www/html/files/index.html >/dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Shared Files</title></head>
<body>
<h1>Starter Materials</h1>
<ul>
<li><a href="notes.txt">notes.txt</a> — sponsor's handoff notes</li>
<li><a href="badge-memo.txt">badge-memo.txt</a> — badge office memo</li>
<li><a href="secrets.zip">secrets.zip</a> — "do not open before day 2" (zip is password-protected; the badge memo next to it explains how badge PINs at this site are chosen)</li>
<li><a href="password_audit.txt">password_audit.txt</a> — leftover from an old audit; looks like it has a hash and a username in it</li>
<li><a href="flag_fake.txt">flag_fake.txt</a> — ignore this one</li>
</ul>
</body>
</html>
EOF

sudo tee /var/www/html/files/flag_fake.txt >/dev/null <<'EOF'
Not this one. Keep numbering, the way I taught you. — P.O.R.
EOF

sudo tee /var/www/html/files/badge-memo.txt >/dev/null <<'EOF'
MEMO — Badge Office
To: All site coordinators
Re: Temporary badge PINs

Until the new system is live, temporary badge PINs for this site are set to
the year this building opened: a 4-digit year. Nothing clever, we know. Tell
new contractors not to reuse it anywhere important.

(Building opened 1973 — see the plaque in the lobby if you forget.)
EOF

NOTES_B64=$(flag 4 | base64 -w0)
sudo tee /var/www/html/files/notes.txt >/dev/null <<EOF
Hey — sponsor here. Sorry for the mess, IT hasn't cleaned this box up yet.

Couple things before your first day:
- The line below looks like gibberish, it's just base64. Decode it.
- cipher.txt in this same folder isn't base64, it's the classic rotate-by-13
  trick people call ROT13. Same alphabet, just walked forward.
- Don't bother with the admin panel link anywhere on this site. It's never
  worked, not even for Priya.

$NOTES_B64
EOF

python3 -c "
import codecs
print(codecs.encode('$(flag 5)', 'rot_13'))
" | sudo tee /var/www/html/files/cipher.txt >/dev/null

echo "== Password-protected zip (flag 6) =="
WORKDIR=$(mktemp -d)
flag 6 > "$WORKDIR/flag6.txt"
( cd "$WORKDIR" && zip --password 1973 -q secrets.zip flag6.txt )
sudo mv "$WORKDIR/secrets.zip" /var/www/html/files/secrets.zip
rm -rf "$WORKDIR"

echo "== MD5 hash to crack -> openssl-encrypted handoff (flag 7) =="
PW_MD5=$(printf '%s' "$JMILLER_PASSWORD" | md5sum | cut -d' ' -f1)
sudo tee /var/www/html/files/password_audit.txt >/dev/null <<EOF
Internal note — leftover from last quarter's password audit. The account
below should have been reset after the audit; it looks like IT forgot to do
it. handoff.enc in this folder was locked with that account's password as
the openssl key, same convention we always use (aes-256-cbc, pbkdf2).

user: jmiller
md5:  $PW_MD5
EOF
WORKDIR2=$(mktemp -d)
flag 7 > "$WORKDIR2/flag7.txt"
openssl enc -aes-256-cbc -pbkdf2 -salt -k "$JMILLER_PASSWORD" \
    -in "$WORKDIR2/flag7.txt" -out "$WORKDIR2/handoff.enc"
sudo mv "$WORKDIR2/handoff.enc" /var/www/html/files/handoff.enc
rm -rf "$WORKDIR2"

echo "== Honeypots (web) =="
sudo tee /var/www/html/robots.txt >/dev/null <<'EOF'
User-agent: *
Disallow: /welcome/
Disallow: /admin/
EOF

sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type f -exec chmod 644 {} +
sudo find /var/www/html -type d -exec chmod 755 {} +

echo "== Anonymous FTP content (vsftpd) =="
sudo mkdir -p /srv/ftp
sudo tee /srv/ftp/README.txt >/dev/null <<'EOF'
Anonymous FTP — temporary drop for new contractors while the portal is
being finished. Don't put anything here you wouldn't want IT to see.
EOF
flag 3 | sudo tee /srv/ftp/flag3.txt >/dev/null
sudo tee /srv/ftp/old_creds.txt >/dev/null <<'EOF'
from: helpdesk
these were rotated out last year, don't bother trying them anywhere —
admin / Password123!
guest / guest
jmiller / Welcome2024

(if any of these still worked we'd have bigger problems than a CTF box)
EOF
sudo chown root:root /srv/ftp
sudo chmod 755 /srv/ftp
sudo find /srv/ftp -type f -exec chmod 644 {} +

sudo tee /etc/vsftpd.conf >/dev/null <<'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=NO
write_enable=NO
anon_root=/srv/ftp
anon_mkdir_write_enable=NO
anon_upload_enable=NO
no_anon_password=YES
hide_ids=YES
pasv_enable=YES
pasv_min_port=20000
pasv_max_port=20010
seccomp_sandbox=NO
EOF
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd

echo "== jmiller account (flags 8, 9) =="
sudo id -u jmiller >/dev/null 2>&1 || sudo useradd -m -s /bin/bash jmiller
echo "jmiller:$JMILLER_PASSWORD" | sudo chpasswd
flag 8 | sudo -u jmiller tee /home/jmiller/flag8.txt >/dev/null
sudo -u jmiller mkdir -p /home/jmiller/.config
flag 9 | sudo -u jmiller tee /home/jmiller/.config/.flag9 >/dev/null
sudo tee /home/jmiller/.bash_history >/dev/null <<'EOF'
ls -la
cat flag8.txt
whoami
id
sudo -l
EOF
sudo chown -R jmiller:jmiller /home/jmiller
sudo chmod 600 /home/jmiller/.bash_history

echo "== Enabling SSH password auth for jmiller only (everyone else stays key-only) =="
sudo tee /etc/ssh/sshd_config.d/90-jmiller-password-auth.conf >/dev/null <<'EOF'
Match User jmiller
    PasswordAuthentication yes
EOF
sudo chmod 644 /etc/ssh/sshd_config.d/90-jmiller-password-auth.conf
sudo sshd -t
# Ubuntu's openssh-server here is socket-activated (ssh.socket) -- each
# new connection forks a fresh sshd that re-reads sshd_config, so no
# reload is actually required; `systemctl reload ssh` can report "not
# active" under socket activation even though it's working fine.
sudo systemctl reload ssh 2>/dev/null || true

echo "== Sudo misconfiguration -> root (flag 10) =="
echo "jmiller ALL=(root) NOPASSWD: /usr/bin/python3" | sudo tee /etc/sudoers.d/jmiller >/dev/null
sudo chmod 440 /etc/sudoers.d/jmiller
flag 10 | sudo tee /root/flag10.txt >/dev/null
sudo chmod 600 /root/flag10.txt

echo "== Restarting services =="
sudo systemctl restart nginx
sudo systemctl enable nginx

# `systemctl restart ssh` on this image can leave the PREVIOUS run's
# standalone sshd listener process orphaned instead of killed, so two
# listeners end up racing on port 22 -- whichever accepts a given
# connection "wins", meaning roughly half of all SSH attempts can be
# served by a stale listener running an OLD sshd_config (e.g. missing
# a Match User override added since). Hit this exact bug (intermittent
# "Permission denied" for a Match-gated account) while building this
# box -- kill any stray listeners explicitly before restarting.
sudo pkill -9 -f 'sshd: /usr/sbin/sshd -D \[listener\]' 2>/dev/null || true
sleep 1
sudo systemctl restart ssh
sudo systemctl enable ssh

echo "Done."
