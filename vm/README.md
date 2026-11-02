# VM / OVA — Orientation Server

Guest OS: **Ubuntu Server 24.04 LTS** (official cloud image), via
QEMU/KVM + cloud-init (NoCloud). Native build — real nginx, vsftpd, and
openssh-server on the guest, no Docker anywhere, same pattern as The
Forgotten Administrator's own VM.

Flags are **static**, baked in once at provisioning time from a fixed
release secret (not a per-deployment secret) — every copy of the
exported OVA has the same flags. The release secret itself is never
committed; `organizer/release-secret.txt` (gitignored) holds it, and
`organizer/verify.py` uses it to check submissions.

## Layout

```
vm/
    images/            base cloud image (downloaded, gitignored, large)
    cloud-init/        user-data.yaml, meta-data.yaml, network-config.yaml
                       (committed — this IS the reproducible setup)
    seed/              generated cloud-init seed.img (gitignored)
    disks/             the VM's writable qcow2 disk (gitignored, large)
    keys/              build-only SSH keypair (gitignored — never shared
                       with players; regenerate your own if rebuilding)
    scripts/
        create-disk.sh       build the disk + seed from the base image
        boot-vm.sh            start the VM (host-only networking)
        stop-vm.sh            clean shutdown
        provision.sh          (host) deploy the challenge via SSH
        remote-provision.sh   (runs inside the VM) actual setup logic
        verify.sh             proves all 10 flags work, over SSH
        export-vm.sh          snapshot + flatten to a standalone qcow2
        export-ova.sh         package that into a standard OVA
```

## Build from source

```
cd vm
# put ubuntu-24.04-server-cloudimg-amd64.img in images/ first
# put your own ed25519 keypair in keys/ctfbuilder_ed25519[.pub],
# and reference the .pub in cloud-init/user-data.yaml
# generate a release secret: openssl rand -hex 32 > ../organizer/release-secret.txt
./scripts/create-disk.sh
./scripts/boot-vm.sh      # wait a few minutes for first boot + cloud-init
./scripts/provision.sh
./scripts/verify.sh       # proves all 10 flags before you export anything
./scripts/export-vm.sh
./scripts/export-ova.sh
```

## Using the pre-built OVA

Download the `.ova` from this repo's Releases page, then File > Import
Appliance in VirtualBox (or Open in VMware Workstation/Fusion). Power
it on and wait for boot (a minute or so) — everything is already set
up, nothing to configure. Find its IP (depends on your chosen
networking mode) and browse to port 80 / FTP 21 / SSH 22.

**This is an intentionally vulnerable machine. Import it only on an
isolated network.**
