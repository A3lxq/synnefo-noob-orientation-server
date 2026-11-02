# Hints (progressive — try to only read as far as you need)

**Flag 1** — View the page source of the web root. Comments don't render.

**Flag 2** — Check `/robots.txt`. A `Disallow` entry is a request, not a lock.

**Flag 3** — Most FTP servers that allow it will take `anonymous` as the
username and anything (even blank) as the password.

**Flag 4** — `/files/` is listable. One file contains a long string of
letters, numbers, `+`, `/` and `=` — that alphabet is a strong hint about the
encoding.

**Flag 5** — Another file in the same folder isn't base64. It's a shift
cipher. notes.txt already tells you which shift.

**Flag 6** — The zip's password is a 4-digit number. Somewhere else in the
same folder is a document that tells you exactly how that number is chosen
at this site.

**Flag 7** — `password_audit.txt` has an MD5 hash and a username. Crack it
with a common wordlist (it's a well-known weak password, not a custom one).
Once you have the plaintext, look at what else in that folder is encrypted
and with what tool's default convention.

**Flag 8** — The password you just cracked belongs to a real account on
this box, reachable over a service you already scanned.

**Flag 9** — `ls` alone won't show everything in a home directory. Check
what flag starts with a dot.

**Flag 10** — Check what you're allowed to run as another user without a
password. If it's a well-known interpreter or editor, GTFOBins almost
certainly has an entry for turning that into a root shell.
