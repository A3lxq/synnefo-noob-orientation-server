# Organizer manifest — Orientation Server (Noob)

Keep this file (and this whole `organizer/` directory) off any player-facing
host. Flag *values* are never written here — they're re-derived from the
deployment's `CTF_SECRET` via `generate_flags.py` / `verify.py`.

| # | Difficulty | Concept taught | Primary tool(s) | Where it lives |
|---|---|---|---|---|
| 1 | Easy | Reading page source for hidden data | Browser view-source / curl | HTML comment on `/` |
| 2 | Easy | robots.txt as a recon source | curl, browser | `/welcome/` (disallowed, not protected) |
| 3 | Easy | Anonymous FTP enumeration | ftp / lftp | `flag3.txt` on anonymous FTP |
| 4 | Medium | Base64 decoding | `base64 -d`, CyberChef | `files/notes.txt` |
| 5 | Medium | Classical substitution cipher (ROT13) | CyberChef, `tr`, `codecs.decode` | `files/cipher.txt` |
| 6 | Medium | Cracking a weak zip password | `fcrackzip`, `zip2john`+`john` | `files/secrets.zip` (PIN `1973`, hinted via badge-memo.txt) |
| 7 | Hard | Hash cracking, then using the cracked secret as a decryption key | `hashcat`/`john` + rockyou, `openssl enc -d` | `files/password_audit.txt` (md5) unlocks `files/handoff.enc` |
| 8 | Hard | Credential reuse to pivot from hash-crack to shell access | `ssh` | jmiller's home directory, password = cracked value |
| 9 | Hard | Hidden dotfiles / thorough enumeration | `ls -la`, `find -name ".*"` | `~/.config/.flag9` |
| 10 | Hardest | Sudo misconfiguration -> GTFOBins privilege escalation | `sudo -l`, GTFOBins lookup for `python3` | `/root/flag10.txt` |

## Honeypots (never flag-shaped, cost time only)
- `/admin/` login panel — static, always rejects, no backend.
- `files/flag_fake.txt` — explicitly says "not this one".
- `ftp/old_creds.txt` — plausible-looking but inert credential list.
- `.bash_history` seeded with benign-looking commands only (no fake creds
  that could be mistaken for working ones).

## Fixed design constants (intentional, not secret-derived)
- jmiller's SSH/openssl password: `superman1` (present in common wordlists).
- Zip PIN: `1973` (narratively hinted in `badge-memo.txt`).
- Sudo misconfig: `jmiller ALL=(root) NOPASSWD: /usr/bin/python3`.

These are deliberately weak by design (the vulnerability being taught), not
box secrets — only the 10 flag *values* are per-deployment secret-derived.
