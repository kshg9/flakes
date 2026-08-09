# sops / sops-nix — declarative secrets

Setup captured 2026-08-09. sops-nix decrypts at boot (activation) directly to
`/run/secrets/<name>`. **TWO-KEY model** — proves out before a 2nd real host
(virt-manager, GCP-ish) lands. A sandbox VM POC validated the machinery, then
was reverted (sandbox needs no secrets) — the runbooks below are the lasting
takeaway.

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
  plumbing, currently imported by uriel only:
  - `sops.age.keyFile = /var/lib/sops-nix/key.txt` + `generateKey = true`.
  - `environment.systemPackages` += `sops` + `age` (the CLI + age-keygen).
  - **NO `sops.secrets.*` here** — which secrets a host decrypts is gated
    PER-HOST, declared in that host's `configuration.nix`.
- `nixos/features/impermanence.nix` — `persistence.files` includes
  `/var/lib/sops-nix/key.txt` (uriel persists the boot key).
- Per-host secret declarations (uriel):
  `sops.defaultSopsFile = ./../../features/secrets/uriel.yaml` +
  `sops.secrets.github_ssh_private_key` (kdj:users 0600) +
  `github_ssh_pubkey` (root:keys 0444) — in `hosts/uriel/configuration.nix`.
- `nixos/features/secrets/uriel.yaml` — uriel's secrets, encrypted for
  `[kdj, uriel]`.
- `.sops.yaml` (repo root) — sops gates edits by filename from repo root.
  `keys:` holds real pubkeys `&kdj` (personal) + `&uriel` (uriel boot), and the
  per-file `creation_rules` (`uriel\.yaml` → `[*kdj,*uriel]`). A creation_rule
  can only reference a key that's DEFINED above — a rule referencing an
  undefined/comment-out `&name` breaks `sops` config loading for all files.
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
- **Future host boot key:** same pattern — its own key, its own secrets file.
  A VM that's disposable can get a key you control via a shared dir
  (`virtualisation.sharedDirectories`) + swap-and-reboot, but there's no live
  sops usage on the sandbox today.

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
sops set --value-file nixos/features/secrets/uriel.yaml \
  '["github_ssh_private_key"]' /tmp/gh_key.json

jaq -Rs . ~/.ssh/id_ed25519_gh.pub > /tmp/gh_pub.json
sops set --value-file nixos/features/secrets/uriel.yaml \
  '["github_ssh_pubkey"]' /tmp/gh_pub.json

# verify + stage (fileset trap: the new/edited .yaml must be git add-ed)
sops -d nixos/features/secrets/uriel.yaml
git add nixos/features/secrets/uriel.yaml
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
   passphrase-protected here → never usable, see below). Persist it per the
   host's setup: bare metal via `persistence.files`
   (`features/impermanence.nix`); a disposable VM can swap in a key you control
   through a `virtualisation.sharedDirectories` mount + reboot.
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