# Case File 1 (Noob) — Orientation Server

Part of **The Halcyon Protocol** CTF series. This box stands alone — you do
not need any other box in the series to play it.

> "Priya numbered every file she opened. We've kept her numbering. Flags 1–3
> are the ones she found in an afternoon. The rest took her weeks." — see
> [`STORY.md`](STORY.md) for the full case file.

## What this is

A single deliberately-vulnerable Linux host (web + anonymous FTP + SSH)
aimed at players who are brand new to CTFs. 10 flags, no decoys. The first
three are easy; difficulty then climbs.

**This machine is intentionally vulnerable. Run it only on an isolated
network** (the provided `docker-compose.yml` uses its own bridge network and
only needs to publish ports to your own lab host — do not expose it to the
internet).

## Requirements

- Docker + Docker Compose — **or** a hypervisor (VirtualBox / VMware)
  if you'd rather import the pre-built VM appliance (see below)
- A player machine with `nmap`, `curl`, `ftp`/`lftp`, a web browser,
  `base64`, a hex/cipher tool (e.g. CyberChef), `fcrackzip` or `john`,
  `hashcat` or `john` + a wordlist (e.g. `rockyou.txt`), `openssl`, `ssh`

## Option B: pre-built VM (OVA)

Don't want to run Docker yourself? Download the `.ova` from this repo's
[Releases](../../releases) page and import it into VirtualBox (File >
Import Appliance) or VMware Workstation/Fusion (File > Open). It boots,
sets itself up, and generates its own fresh flags automatically —
nothing to configure. See [`vm/README.md`](vm/README.md) for details
and for rebuilding it from source. Same rule applies: isolated network only.

## Starting the box

```
./start.sh
```
This generates a fresh `.env` with a random per-deployment secret (if you
don't already have one) and brings the stack up. Flags are unique to your
deployment and are not stored anywhere in this repository.

- Web: http://localhost:8001
- Anonymous FTP: `ftp://localhost:2101`
- SSH: `ssh -p 2201 jmiller@localhost` (you need to find the password)

## Flag format

`HLC{xxxxxxxxxx}` — submit exactly as found.

## Rules

- No decoy flags: everything matching the flag format is real and counts.
- Some things in this box are honeypots — red herrings that cost you time,
  not flags. Nothing shaped like a flag is fake.
- Don't attack this box over a shared or public network.

## More

- [`STORY.md`](STORY.md) — the in-universe case file
- [`docs/hints.md`](docs/hints.md) — progressive hints, spoiler-light
- [`docs/tools.md`](docs/tools.md) — what each tool in the requirements list is for
- [`docs/writeup/WRITEUP.md`](docs/writeup/WRITEUP.md) — full spoiler walkthrough
