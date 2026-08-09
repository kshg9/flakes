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
- Per-host secret declarations (sandbox, POC verified 2026-08-09):
  `sops.defaultSopsFile = ./../../features/secrets/sandbox.yaml` +
  `sops.secrets.github_ssh_private_key` (biyoo:users 0600) +
  `github_ssh_pubkey` (root:keys 0444) — in `hosts/sandbox/configuration.nix`.
  The VM gets the boot key via a virtiofs shared dir
  (`virtualisation.sharedDirectories`: `~/Downloads` → `/mnt/host`, swap-and-reboot).
- `nixos/features/secrets/uriel.yaml` — uriel's secrets, encrypted for
  `[kdj, uriel]`. `nixos/features/secrets/sandbox.yaml` — sandbox's, encrypted
  for `[kdj, sandbox]`.
- `.sops.yaml` (repo root) — sops gates edits by filename from repo root.
  `keys:` holds real pubkeys `&kdj` (personal), `&uriel` (uriel boot),
  `&sandbox` (sandbox boot), and per-file `creation_rules` (`uriel\.yaml` →
  `[*kdj,*uriel]`, `sandbox\.yaml` → `[*kdj,*sandbox]`). A creation_rule can
  only reference a key that's DEFINED above — defining `&sandbox` after the
  rule (or leaving it commented) makes `sops` fail to load its config.
- `nixos/users/base.nix` — hjem `environment.sessionVariables`
  `SOPS_AGE_KEY_FILE = ~/.config/sops/age/keys.txt` so the `sops` CLI always
  uses the PERSONAL key (never the host boot key), wherever you are.
- `nixos/users/base.nix` — hjem `environment.sessionVariables`
  `SOPS_AGE_KEY_FILE = ~/.config/sops/age/keys.txt` so the `sops` CLI always
  uses the PERSONAL key (never the host boot key), wherever you are.

## The age keys

- **Personal (kdj):** `~/.config/sops/age/keys.txt`; pubkey via
  `age-keygen -y ~/.config/sops/age/keys.txt` → paste into `.sops.yaml` `&kdj`.
  The `sops` CLI then just works (default path + SOPS_AGE_KEY_FILE → it).
  `&kdj` in `.sops.yaml` is filled with this pubkey.
- **uriel boot key:** `/var/lib/sops-nix/key.txt` generated + persisted.
  `&uriel` in `.sops.yaml` matches `sudo age-keygen -y /var/lib/sops-nix/key.txt`.
- **sandbox boot key** (swap-and-reboot method, POC-tested): VM is a disposable
  dev box, so kdj makes a key he controls (`age-keygen -o ~/hello.txt`), stores
  the PRIVATE key in a secrets manager, and hands it to the box when needed:
  1. build + boot the VM (`virtualisation.sharedDirectories` exposes
     `~/Downloads` → `/mnt/host`),
  2. inside the VM: `sudo cp /mnt/host/hello.txt /var/lib/sops-nix/key.txt`
     (first boot's `generateKey` made a random key — overwrite it),
  3. `sudo reboot` → `/run/secrets` decrypts with the known key.
  Consumption needs NO `~/.config/sops/...` swap in the VM (that's only for
  running the sops CLI there).

## kdj daily — editing / adding secrets non-interactively (jaq style)

Verified on real files 2026-08-09. `sops set` is the non-interactive route.
**Correct forms** (the help text is misleading):

```bash
# 📌 `jaq -Rs .` (NO `-a` — jaq has no such flag; `-Rsa` errors: unknown flag)
# 📌 `sops set` has NO `-a` flag. `--value-file` is a BOOL; the value-path is
#    the 3rd POSITIONAL arg:  sops set --value-file FILE INDEX VALUE_PATH
#    (FILE + INDEX + VALUE = 3 positionals; omitting the 3rd → `Invalid set index format`)

# add a single secret from a file (e.g. ssh key — strips nothing, raw JSON string)
jaq -Rs . ~/.ssh/id_ed25519_gh > /tmp/gh_key.json
sops set --value-file nixos/features/secrets/sandbox.yaml \
  '["github_ssh_private_key"]' /tmp/gh_key.json

jaq -Rs . ~/.ssh/id_ed25519_gh.pub > /tmp/gh_pub.json
sops set --value-file nixos/features/secrets/sandbox.yaml \
  '["github_ssh_pubkey"]' /tmp/gh_pub.json

# verify + stage (fileset trap: the new/edited .yaml must be git add-ed)
sops -d nixos/features/secrets/sandbox.yaml
git add nixos/features/secrets/sandbox.yaml
```

Each edit re-encrypts for every recipient in the file's metadata (kdj + that
host). The `|` block respresentation is fine; `sops set` merges, so the
`hello:` demo key survives.

## Adding a NEW host (runbook)

1. **Import the module** — add `self.nixosModules.sops` to the host's
   `imports` in `nixos/hosts/<host>/configuration.nix`.
2. **Declare its secrets** there (NOT in `sops.nix`, it's generic):
   ```nix
   sops.defaultSopsFile = ./../../features/secrets/<host>.yaml;
   sops.secrets.github_ssh_private_key = { owner = "<user>"; mode = "0600"; };
   ```
   Give the user the `keys` group (e.g. `extraGroups = [ "keys" ]`) so they can
   traverse `/run/secrets` (the dir itself is root:keys 750).
3. **Make a boot key** for the host (dedicated age key; SSH keys are
   passphrase-protected here → never usable, see below). VM: reuse the
   swap-and-reboot virtiofs path. Bare metal: give it `persistence.files`
   (`features/impermanence.nix`) for the key.
4. **`.sops.yaml`**: add `&<host> "<pubkey>"` (from
   `sudo age-keygen -y /var/lib/sops-nix/key.txt`) + a per-file
   `creation_rules` entry `[*kdj, *<host>]`. ⚠️ define the key ABOVE the rule.
5. **Create the host's secrets file** with the jaq/sops commands above
   (recipient metadata comes from the creation_rule).
6. **`git add`** the new `<host>.yaml` — the fileset trap hides it from the
   flake otherwise. Eval-gate: `nix eval .#nixosConfigurations.<host>...drvPath`.

## SSH keys → age: NOT available here (verified 2026-08-08)

kdj's `~/.ssh/id_ed25519_gh` + `id_ed25519_termux` are **passphrase-protected**
(`ssh-keygen -y` fails; sops decrypts `failed to obtain passphrase... /dev/tty
not available`). sops-nix decrypts at boot as root without a terminal, so a
passphrase'd SSH key can NEVER be a boot key. SSH keys CAN still be added as
*sops recipients* (IDENTITY NOT) via `ssh-to-age` for multi-key setups — but
stick to dedicated generated age keys.

## kdj daily

```bash
# interactive edit of an existing secret (opens $EDITOR)
sops nixos/features/secrets/uriel.yaml
# non-interactive (jaq + sops set) — see "editing / adding secrets" above
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

- Define the `.sops.yaml` creation_rule ONLY when its key anchor exists —
  a rule referencing an undefined `&name` (or a commented-out key) breaks
  `sops` **config loading** for ALL files (`unknown anchor '…' referenced`).
- `sops set --value-file` needs THREE positional args (`FILE INDEX VALUE_PATH`);
  `--value-file` is a bare boolean flag, not a value-taking one. Missing the
  3rd arg → `Invalid set index format`.
- `jaq` has NO `-a` flag (`jaq -Rsa .` → `unknown flag: -a`); use `jaq -Rs .`.
  `-Rs` keeps the trailing newline in the stored value (harmless for PEM/pubkeys).
- `defaultSopsFile` is resolved relative to the DEFINING module — that's now
  each host's `configuration.nix` (`hosts/uriel/` → `../../features/secrets/…`),
  not the shared `sops.nix`.
- uriel's boot key survives only because it's in `persistence.files`,
  declared in `features/impermanence.nix`. Moving/deleting it breaks decrypts.
- Never commit an unencrypted secret.
- `sops.age.generateKey` won't overwrite an existing key.
- sops-nix only activates `generateKey`/decrypt once at least one
  `sops.secrets.*` is declared.