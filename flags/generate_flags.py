#!/usr/bin/env python3
"""
Deterministic per-deployment flag generator.

Flags are HMAC-SHA256(secret, "<box_id>:<flag_number>"), truncated to 10 hex
chars, wrapped as HLC{...}. The secret lives only in the deployment's
generated .env (git-ignored) or is passed as CTF_SECRET at container start,
so the public repo never contains a working flag value.

Used both inside the running container (to place real flags) and by the
organizer-side verify.py script (to check a submitted flag without storing
plaintext answers anywhere in the repo).
"""
import hmac
import hashlib
import os
import sys

BOX_ID = "noob-orientation-server"


def flag_for(n: int, secret: str) -> str:
    digest = hmac.new(secret.encode(), f"{BOX_ID}:{n}".encode(), hashlib.sha256).hexdigest()
    return f"HLC{{{digest[:10]}}}"


def all_flags(secret: str) -> dict:
    return {n: flag_for(n, secret) for n in range(1, 11)}


if __name__ == "__main__":
    secret = os.environ.get("CTF_SECRET")
    if not secret:
        print("CTF_SECRET not set", file=sys.stderr)
        sys.exit(1)
    if len(sys.argv) > 1 and sys.argv[1] == "all":
        for n, f in all_flags(secret).items():
            print(f"{n}\t{f}")
    elif len(sys.argv) > 1:
        print(flag_for(int(sys.argv[1]), secret))
    else:
        print("usage: generate_flags.py all | generate_flags.py <n>", file=sys.stderr)
        sys.exit(1)
