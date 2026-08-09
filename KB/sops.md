# sops / sops-nix — declarative secrets

Setup captured 2026-08-09. sops-nix decrypts at boot (activation) directly to
`/run/secrets/<name>`. **TWO-KEY model** (README-informed, chosen because a
2nd host — nixos-vm/virt-manager, a GCP-ish cloud box — is coming):

- **Personal editing key** — kdj's key in `~/.config/sops/age/keys.txt`
  (sops' default location). The `sops` CLI edits with THIS key on any host.
- **Per-host BOOT key** — each host auto-generates its own
  `/var/lib/sops-nix/key.txt` (`sops.age.generateKey`). Only decrypts that
  host's secrets at boot, as root.

**Each host has its OWN secrets file** (`nixos/features/secrets/<host>.yaml`),
encrypted for kdj + that host, so no other host can decrypt it. kdj can edit
from any machine (present personal key); each host decrypts its own with its
own boot key. DON'T regress to one-key (a single shared `keyFile` gives the
CLI a host-specific key that can't edit other hosts' secrets — breaks the
moment host #2 appears) and DON'T nest all hosts' secrets in one file.

## What's in place

- `flake.nix` → `sops-nix` input (nixpkgs follows ours).
- `nixos/features/sops.nix` → `flake.nixosModules.sops` — the **generic**
  plumbing, imported by uriel AND sandbox:
  - `sops.age.keyFile = /var/lib/sops-nix/key.txt` + `generateKey = true`.
  - `environment.systemPackages` += `sops` + `age` (the CLI + age-keygen).
  - **NO `sops.secrets.*` here** — which secrets a host decrypts is gated
    PER-HOST, declared in that host's `configuration.nix`.
- `nixos/features/impermanence.nix` — `persistence.files` includes
  `/var/lib/sops-nix/key.txt` (uriel persists the boot key; sandbox has no
  impermanence).
- Per-host secret declarations (uriel):
  `sops.defaultSopsFile = ./../../features/secrets/uriel.yaml` +
  `sops.secrets.github_ssh_private_key` (kdj:users 0600) +
  `github_ssh_pubkey` (root:keys 0444) — in `hosts/uriel/configuration.nix`.
  Sandbox's declarations are commented (waiting for its boot key + secrets
  file, see below).
- `nixos/features/secrets/uriel.yaml` — uriel's secrets file, encrypted for
  `[kdj, uriel]`. `secrets/sandbox.yaml` doesn't exist yet.
- `.sops.yaml` (repo root) — sops gates edits by filename from repo root.
  `keys:` holds `&kdj` + `&uriel` **placeholders** (user fills in real
  pubkeys), and per-file `creation_rules` (`uriel\.yaml` → `[*kdj,*uriel]`,
  `sandbox\.yaml` → `[*kdj,*sandbox]`).
- `nixos/users/base.nix` — hjem `environment.sessionVariables`
  `SOPS_AGE_KEY_FILE = ~/.config/sops/age/keys.txt` so the `sops` CLI always
  uses the PERSONAL key (never the host boot key), wherever you are.

## The age keys

- **Personal (kdj):** `~/.config/sops/age/keys.txt`; pubkey via
  `age-keygen -y ~/.config/sops/age/keys.txt` → paste into `.sops.yaml` `&kdj`.
  The `sops` CLI then just works (default path + SOPS_AGE_KEY_FILE → it).
- **uriel boot key:** /var/lib/sops-nix/key.txt already generated + persisted.
  Get its pub with `sudo age-keygen -y /var/lib/sops-nix/key.txt` → paste into
  `.sops.yaml` `&uriel`.
- **sandbox boot key** (swap-and-reboot method, chosen by user): the VM is a
  disposable dev box. Generate a key YOU control — `age-keygen -o /tmp/...`,
  store the PRIVATE key in a secrets manager, and when the box needs secrets:
  1. put that key at `/var/lib/sops-nix/key.txt` in the VM
     (or let `generateKey` make one and harvest its pubkey),
  2. add the pubkey to `.sops.yaml` `&sandbox` + the sandbox creation rule,
  3. `sops`/`sops updatekeys` `secrets/sandbox.yaml` and set that file's
     declarations in `sandbox/configuration.nix`,
  4. reboot → `/run/secrets` appears. The `~/.config/sops/...` swap is NOT
     needed for consumption (only if you run the sops CLI inside the VM).

## SSH keys → age: NOT available here (verified 2026-08-08)

kdj's `~/.ssh/id_ed25519_gh` + `id_ed25519_termux` are **passphrase-protected**
(`ssh-keygen -y` fails; sops decrypts `failed to obtain passphrase... /dev/tty
not available`). sops-nix decrypts at boot as root without a terminal, so a
passphrase'd SSH key can NEVER be a boot key. SSH keys CAN still be added as
*sops recipients* (IDENTITY NOT) via `ssh-to-age` for multi-key setups — but
stick to dedicated generated age keys.

## kdj daily

```bash
# edit an existing secret
sops nixos/features/secrets/uriel.yaml
# add a new secret: same command, add `key: value`, save.
```

Each edit re-encrypts for every key in the matching `creation_rules` group
(kdj + all hosts). Commit the changed file — it's encrypted.

## Using a secret in a NixOS/hjem module

```nix
sops.secrets.mytoken = { };                    # → /run/secrets/mytoken at boot
# reference: config.sops.secrets.mytoken.path
#   e.g. service: EnvironmentFile = [ config.sops.secrets.mytoken.path ];
#   per-secret alt file: sops.secrets.mytoken.sopsFile = ./other.yaml;
```

`regularSecrets` decrypts via `sops-install-secrets` activation script; lands
in tmpfs `/run/secrets` each boot.

## Gotchas / traps

- `defaultSopsFile` is resolved relative to the DEFINING module — that's now
  each host's `configuration.nix` (`hosts/uriel/` → `../../features/secrets/…`),
  not the shared `sops.nix`.
- uriel's boot key survives only because it's in `persistence.files`,
  declared in `features/impermanence.nix`. Moving/deleting it breaks decrypts.
- Never commit an unencrypted secret.
- `sops.age.generateKey` won't overwrite an existing key.
- Adding a host later: import `self.nixosModules.sops` on it, persist its key
  (uriel: add to `persistence.files`; VM: swap-in method above), add its key
  to `.sops.yaml`, `sops updatekeys <host>.yaml` to re-encrypt for both.
- sops-nix only activates `generateKey`/decrypt once at least one
  `sops.secrets.*` is declared.