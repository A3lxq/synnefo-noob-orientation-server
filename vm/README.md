# VM / OVA — Case File 1 (Noob) -- Orientation Server

This box ships as "Docker-in-a-VM": the exact same `docker-compose.yml`
from the repo root, running inside a standalone Ubuntu Server 24.04 VM,
so the whole thing is one importable OVA with no host Docker needed.

The box starts itself automatically on every boot (a systemd unit runs
`start.sh`) and generates its own fresh `CTF_SECRET` the first time it
runs — same behavior as a Docker player running `./start.sh` by hand.

## Rebuilding this VM from source

1. Get the base image: Ubuntu Server 24.04 LTS cloud image
   (`ubuntu-24.04-server-cloudimg-amd64.img`) into `vm/images/`.
2. `cd vm && ./scripts/create-disk.sh`
3. `./scripts/boot-vm.sh` (wait a minute or two for first boot)
4. `./scripts/provision.sh`
5. `./scripts/verify.sh` — runs this box's own `tests/solve.sh` inside
   the VM, proving all 10 flags are reachable.
6. `./scripts/export-vm.sh` — resets to a never-played state (fresh
   secret on next boot) and flattens to a standalone qcow2.
7. `./scripts/export-ova.sh` — packages that into a standard OVA.

## Using the pre-built OVA

Download the `.ova` from this repo's Releases page, then File > Import
Appliance in VirtualBox (or Open in VMware Workstation/Fusion). Power
it on, wait for boot + first-run setup (a minute or so), then check
what IP it got (bridged/host-only network, your choice at import) and
browse to the box's published port(s) — see the repo's own README for
which ones.

**This is an intentionally vulnerable machine. Import it only on an
isolated network.**
