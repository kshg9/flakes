# Deep Architectural Review & Improvement Plan

> A blueprint for making this NixOS config maximally maintainable, trivially
> extensible, and architecturally beautiful — without throwing away the things
> that already work well.

---

## What you've already got right

Before talking about changes, it's worth naming the things this config does
**better than most NixOS repos**:

| Strength | Why it matters |
|---|---|
| `importTree` auto-discovery | Zero-friction module registration — drop a `.nix` file, `git add`, done. Most repos have a manual import list that drifts. |
| `_`-prefix toggle | Disabling a feature module is a `git mv`, not a code change. Brilliant UX. |
| `extras.nix` cascading options | Machine-level heavy modules (`nvidia`, `vicinae`) gated by a single typed switch — not buried in an `if` somewhere. |
| `flake.userBase` factory pattern | Per-user profiles that compose cleanly (`kdj = base + extras`). Avoids the "single user global" trap that breaks multi-user hosts. |
| `hjem-ext` TOML renderer | Declarative program config without importing a full home-manager. Lightweight, focused. |
| Impermanence + persistent passwords | Root wipe on boot + `/persist` subvolumes = the gold standard of NixOS hygiene. |
| KB directory | Institutional memory that survives across sessions. Most repos lose their "why" within weeks. |

**The foundation is solid.** The plan below is about eliminating friction, not
rewriting from scratch.

---

## Part 1 — Structural Clarity

### 1.1 Collapse `nixos/base/` + `nixos/extra/` into one layer

**Current state:**
```
nixos/base/        → persistence.nix, overlay.nix, nixpkgs-config.nix, theme.nix
nixos/extra/       → impermanence.nix (the ONLY file)
```

The `extra/` directory holds a single file (`impermanence.nix`) that is just the
implementation backing `base/persistence.nix`'s options. Having two directories
for what is logically one concern (persistence) makes it hard to reason about:

- "Where do I add a new persist path?" → `features/impermanence.nix`
- "Where are the options defined?" → `base/persistence.nix`
- "Where is the actual impermanence module imported?" → `extra/impermanence.nix`

Three files across three directories for one concept.

> [!TIP]
> **Proposed:** Merge `extra/impermanence.nix` into `base/persistence.nix` as
> one self-contained module (options + implementation in a single file, gated
> by `lib.mkIf cfg.enable`). Delete `nixos/extra/` entirely.

This makes `nixos/base/` the **"plumbing layer"** — things every host must
import to function — and eliminates the orphaned `extra/` directory that
serves no taxonomy purpose.

---

### 1.2 Rename `nixos/features/` → `nixos/modules/`

`features/` is serviceable, but it conflates three distinct things:

| Current file | Actual role |
|---|---|
| `desktop.nix`, `pipewire.nix`, `keyd.nix` | **Hardware/desktop stack** — what kind of machine this is |
| `extras.nix`, `nvidia.nix`, `vicinae.nix` | **Optional heavy components** — gated by the extras switch |
| `sops.nix`, `nixtools.nix`, `cachix.nix` | **Infra/tooling** — nix daemon tuning, caches, secrets |
| `general.nix` | **Glue** — hjem wiring + system packages |
| `lanzaboote.nix`, `impermanence.nix` | **Boot/storage** concerns |
| `guest-wipe.nix` | **User management** concern |

The word "feature" doesn't distinguish any of these roles. Since every `.nix`
file is already auto-imported (and the host picks what it wants via
`self.nixosModules.*`), the directory name is really just for **human
navigation**.

> [!TIP]
> Two options, pick your preference:
>
> **Option A — Flat rename:** `features/` → `modules/`. Honest and simple.
> Every NixOS module lives in `nixos/modules/`. The files are small (10–60
> lines each), so subdirectories are premature.
>
> **Option B — Semantic subdirs:**
> ```
> nixos/modules/
> ├── desktop/         # desktop.nix, pipewire.nix, noctalia.nix
> ├── hardware/        # keyd.nix, nvidia.nix, printer.nix, _kanata.nix
> ├── infra/           # nixtools.nix, cachix.nix, sops.nix, lanzaboote.nix
> └── system/          # general.nix, extras.nix, vicinae.nix, impermanence.nix, guest-wipe.nix
> ```

Option A is my recommendation. 39 files at ≤135 lines each doesn't need
subdirectories — a flat `modules/` with descriptive names is faster to grep
and scan. Subdirectories can come later if the count exceeds ~25 modules.

---

### 1.3 Move `hjem-ext.nix` under `nixos/base/`

[hjem-ext.nix](file:///home/kdj/flakes/nixos/hjem-ext.nix) sits alone at
`nixos/hjem-ext.nix` — the only file directly under `nixos/`. It defines
`flake.nixosModules.hjemExt`, which is foundational plumbing (it wires the
theme into hjem + provides the `ext.programs` option for every user).

It belongs in `nixos/base/` alongside `theme.nix` and `overlay.nix` — the
other plumbing modules that every host implicitly depends on.

---

### 1.4 Proposed final tree

```
flakes/
├── flake.nix
├── flake.lock
├── justfile
├── .sops.yaml
├── .gitignore
├── AGENTS.md
├── README.md
│
├── KB/                              # knowledge base (docs)
│
├── nixos/
│   ├── base/                        # plumbing: every host needs these
│   │   ├── hjem-ext.nix             # (moved from nixos/)
│   │   ├── nixpkgs-config.nix
│   │   ├── overlay.nix
│   │   ├── persistence.nix          # (merged: options + implementation)
│   │   └── theme.nix
│   │
│   ├── modules/                     # NixOS feature modules (was features/)
│   │   ├── _kanata.nix
│   │   ├── cachix.nix
│   │   ├── desktop.nix
│   │   ├── extras.nix
│   │   ├── general.nix
│   │   ├── guest-wipe.nix
│   │   ├── impermanence.nix
│   │   ├── keyd.nix
│   │   ├── lanzaboote.nix
│   │   ├── nixtools.nix
│   │   ├── noctalia.nix
│   │   ├── nvidia.nix
│   │   ├── pipewire.nix
│   │   ├── printer.nix
│   │   ├── secrets/uriel.yaml
│   │   ├── sops.nix
│   │   └── vicinae.nix
│   │
│   ├── hosts/                       # per-machine configurations
│   │   ├── installer/
│   │   ├── sandbox/
│   │   └── uriel/
│   │
│   └── users/                       # per-user hjem profiles + dotfiles
│       ├── base.nix
│       ├── biyoo.nix
│       ├── kdj.nix
│       ├── yjh.nix
│       └── files/
│           ├── helix/
│           ├── kitty/
│           ├── niri/
│           └── yazi/
│
├── packages/                        # standalone derivations
│   ├── changepass.nix / .sh
│   └── maximizer/
│
├── wrappedPrograms/                  # nix-wrapper-modules wrappers
│   ├── environment.nix
│   ├── fish.nix
│   ├── qalc.nix
│   └── starship.nix
│
├── scripts/                         # operational scripts
└── assets/                          # user avatars (.face icons)
```

**Net change:** 1 directory deleted (`extra/`), 1 renamed (`features/` →
`modules/`), 1 file moved (`hjem-ext.nix` → `base/`). Everything else stays
put.

---

## Part 2 — Maintainability Improvements

### 2.1 Decouple `impermanence.nix` from a hardcoded user

[impermanence.nix](file:///home/kdj/flakes/nixos/features/impermanence.nix#L21)
has `persistence.user = "kdj"` hardcoded. This is fine for a single-user setup,
but it means:

- Adding a second persistent user requires editing this file.
- The sandbox can't reuse the impermanence module (it doesn't have `kdj`).

> [!TIP]
> **Proposed:** Make `persistence.user` a **list** (`persistence.users`) and
> let each *user module* declare its own persistence needs. kdj.nix would set
> `persistence.users = [ "kdj" ]`, yjh.nix would not. The extra/impermanence
> implementation iterates over the list.

This aligns with the existing philosophy: **each user module owns its own
concerns**.

---

### 2.2 Centralize the `specialArgs` boilerplate

Every host repeats the same `specialArgs` block:

```nix
# uriel/configuration.nix
specialArgs = { ctp = config.flake.ctpPalette; };

# sandbox/configuration.nix
specialArgs = { ctp = config.flake.ctpPalette; };

# installer/configuration.nix
specialArgs = { ctp = config.flake.ctpPalette; };
```

This is a DRY violation that will bite when you add more specialArgs (e.g. a
`hostName` or `isDesktop` flag).

> [!TIP]
> **Proposed:** Create a helper in `flake.nix` (or `base/lib.nix`):
> ```nix
> mkHost = { name, modules, extraSpecialArgs ? {} }:
>   inputs.nixpkgs.lib.nixosSystem {
>     modules = [ self.nixosModules."host${name}" ] ++ modules;
>     specialArgs = {
>       ctp = config.flake.ctpPalette;
>     } // extraSpecialArgs;
>   };
> ```
> Each host calls `mkHost { name = "Uriel"; modules = []; }` — one line, no
> copy-paste.

---

### 2.3 Extract `desktop.nix`'s concerns

[desktop.nix](file:///home/kdj/flakes/nixos/features/desktop.nix) is the
largest module (108 lines) and mixes 5 distinct concerns:

1. **SDDM** display manager configuration (lines 11–24)
2. **Niri** compositor registration + XDG portals (lines 27–105)
3. **Fonts** (lines 55–65)
4. **Locale/timezone** (lines 67–80)
5. **Hardware** (bluetooth, firmware) + upower/polkit (lines 82–89)

Locale and hardware have nothing to do with the "desktop" concept. If you ever
want a headless host (a server, a CI box), you'd want locale/hardware without
SDDM/niri.

> [!TIP]
> **Proposed:** Split into:
> - `desktop.nix` → SDDM + niri + portals + fonts (the "graphical session")
> - Move locale/timezone/hardware/polkit into `general.nix` (or a new
>   `locale.nix`) since they're system-level, not desktop-level.

---

### 2.4 Make `guest-wipe.nix` configurable

[guest-wipe.nix](file:///home/kdj/flakes/nixos/features/guest-wipe.nix)
hardcodes `guest = "yjh"`. If you ever add a second guest, or want to change
the wipe schedule, you edit the module itself.

> [!TIP]
> **Proposed:** Accept an option (`guestWipe.users`, `guestWipe.schedule`)
> and let the host config set it:
> ```nix
> guestWipe.users = [ "yjh" ];
> guestWipe.schedule = "weekly";
> ```

---

## Part 3 — Experiment Velocity

### 3.1 Make sandbox a genuine "experimentation harness"

The sandbox is great for testing apps, but **adding a new experiment** requires
editing `biyoo.nix` or `sandbox/configuration.nix`. What if adding an
experiment were just dropping a file?

> [!TIP]
> **Proposed:** Create a `nixos/hosts/sandbox/experiments/` directory. Each
> `.nix` file in it is a standalone NixOS module that the sandbox host
> auto-imports:
> ```nix
> # sandbox/configuration.nix
> imports = [
>   ...
> ] ++ (import ./experiments);   # or use the same importTree pattern
> ```
> To try hyprland: create `experiments/hyprland.nix`. To stop: rename to
> `_hyprland.nix`. The `_`-toggle convention works here too.

---

### 3.2 Add a `just test <app>` recipe

The justfile has `rebuild`, `check`, `disko`, `install` — but the most common
task during development is *"try this app in the sandbox"*. That's currently a
multi-step process:

```bash
# add the package to biyoo.nix, then:
nixos-rebuild build-vm --flake .#sandbox && ./result/bin/run-vm-sandbox
```

> [!TIP]
> **Proposed:** Add a `just vm` (or `just sandbox`) recipe:
> ```just
> vm:
>     nixos-rebuild build-vm --flake .#sandbox && ./result/bin/run-vm-sandbox
> ```
> One command. The edit-to-experiment cycle becomes: edit `biyoo.nix` (or an
> experiment file) → `just vm`.

---

### 3.3 A `just eval` fast-gate recipe

The eval check is the fastest way to validate syntax but requires remembering a
long nix command:

> [!TIP]
> ```just
> eval target="uriel":
>     nix --extra-experimental-features 'nix-command flakes' \
>         eval '.#nixosConfigurations.{{target}}.config.system.build.toplevel.drvPath'
> ```

---

## Part 4 — Wrapper Module Rationalization

### 4.1 The `selfpkgs` vs `pkgs` split is a historical artifact

The overlay (`base/overlay.nix`) already merges `self.packages` into `pkgs` for
NixOS modules. But `wrappedPrograms/` still uses `selfpkgs` for cross-references
(fish → starship, environment → yazi/qalc) because the overlay can't be applied
to the `perSystem` pkgs that *build* the wrappers (cycle).

This is documented and correct — but it means there are two idioms for getting
a package: `pkgs.foo` in NixOS modules, `selfpkgs.foo` in wrappers. New
contributors (or future-you) will get confused.

> [!TIP]
> **Proposed:** Add a one-line comment at the top of each wrapper file:
> ```nix
> # NOTE: use `selfpkgs.X` here (not pkgs.X) — see AGENTS.md "Cycle guard".
> ```
> And link to a KB entry. This isn't a code change; it's a maintenance
> investment.

---

### 4.2 Consider migrating remaining wrappers to hjem

You've already migrated kitty, yazi, niri, and helix from wrappers to hjem
dotfiles. The remaining wrappers are:

| Wrapper | What it does | Hjem candidate? |
|---|---|---|
| `environment.nix` | Fish shell + CLI tools bundled as login shell | **No** — this is the one legitimate use of wrapper-modules (bundled `$PATH` in a single derivation as `users.users.*.shell`). Keep it. |
| `fish.nix` | Fish config (zoxide, starship init, yazi function) | **Maybe** — could be a dotfile at `files/fish/config.fish`, but the `selfpkgs.starship` init complicates it. Keep as wrapper for now. |
| `starship.nix` | Starship prompt config | **Maybe** — small TOML config, could go via `ext.programs.starship`. But it's consumed by `fish.nix` via the wrapper chain, so keep it. |
| `qalc.nix` | Qalc flags wrapper | **No** — pure CLI flag injection, wrapper-modules' sweet spot. |

> [!IMPORTANT]
> **Verdict:** The remaining wrappers are the *right* things to keep as
> wrappers. Don't migrate them. But document this decision so future-you
> doesn't re-ask the question.

---

## Part 5 — Code Hygiene

### 5.1 `persistence.nix` options lack types

[base/persistence.nix](file:///home/kdj/flakes/nixos/base/persistence.nix)
defines `directories`, `files`, `data.directories`, etc. with just
`default = []` and no `type`:

```nix
directories = lib.mkOption {
  default = [ ];
  description = "directories to persist";
};
```

This means Nix won't catch a typo like `persistence.directories = "foo"` (a
string instead of a list) until deep in evaluation.

> [!TIP]
> **Proposed:** Add types:
> ```nix
> directories = lib.mkOption {
>   type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
>   default = [ ];
>   description = "System directories to bind-mount from /persist.";
> };
> ```

---

### 5.2 `NIXOS_OZONE_WL` is set in two places

- [base.nix](file:///home/kdj/flakes/nixos/users/base.nix#L74): `environment.sessionVariables.NIXOS_OZONE_WL = "1"`
- [nvidia.nix](file:///home/kdj/flakes/nixos/features/nvidia.nix#L51): `environment.sessionVariables.NIXOS_OZONE_WL = "1"`

The base already sets it for every user. The nvidia module re-declares it.
NixOS merges strings with `mkMerge` so it works, but it's confusing.

> [!TIP]
> Remove the one in `nvidia.nix` — it's already covered by the base.

---

### 5.3 The `lockscreen.nix` / SilentSDDM reference in AGENTS.md is stale

AGENTS.md mentions `features/lockscreen.nix` with `silentSDDM`, but no such
file exists in the repo. Desktop.nix uses a plain SDDM config. Clean up the
AGENTS.md "Current state" section to match reality.

---

## Part 6 — Future-Proofing

### 6.1 A `mkUser` helper (like `mkHost`)

The user modules (`kdj.nix`, `yjh.nix`, `biyoo.nix`) all follow the same
pattern:

```nix
flake.nixosModules.userFoo = { pkgs, ... }:
  let user = "foo"; in {
    imports = [ (self.userBase user) ];
    users.users.${user} = { ... };
    hjem.users.${user} = { ... };
  };
```

This is clean, but the boilerplate (module name, `let user =`, import pattern)
could be extracted:

> [!TIP]
> **Proposed (optional, lower priority):** A `mkUser` helper in `base.nix`:
> ```nix
> flake.mkUser = name: extraConfig:
>   { pkgs, ... }: {
>     imports = [ (self.userBase name) ];
>   } // (extraConfig { inherit pkgs name; });
> ```
> Then kdj.nix becomes:
> ```nix
> flake.nixosModules.userKdj = self.mkUser "kdj" ({ pkgs, name }: { ... });
> ```
> This is a taste call. The current approach is explicit and readable. Only
> do this if you're adding more users regularly.

---

### 6.2 Per-host secrets directory

Currently secrets live at `nixos/features/secrets/uriel.yaml`. When you add a
second host, you'll have `secrets/uriel.yaml` and `secrets/otherhost.yaml`
inside a `features/` directory — semantically wrong (secrets aren't features).

> [!TIP]
> **Proposed:** Move to `secrets/` at the repo root:
> ```
> secrets/
> ├── uriel.yaml
> └── .sops.yaml      # (move from repo root — keeps crypto config with crypto data)
> ```
> Or keep `.sops.yaml` at root (sops expects it there by default) and just
> move the encrypted files to `secrets/`.

---

## Summary: Priority-Ordered Action Items

| Priority | Change | Effort | Impact |
|---|---|---|---|
| 🔴 High | Merge `extra/` into `base/persistence.nix`, delete `extra/` | ~30 min | Eliminates the confusing 3-directory persistence split |
| 🔴 High | Move `hjem-ext.nix` into `base/` | ~5 min | Completes the "plumbing layer" concept |
| 🟡 Medium | Add types to `persistence.nix` options | ~15 min | Catches config errors at eval time |
| 🟡 Medium | Remove duplicate `NIXOS_OZONE_WL` from nvidia.nix | ~2 min | DRY |
| 🟡 Medium | Add `just vm` and `just eval` recipes | ~5 min | Faster experiment cycle |
| 🟡 Medium | Centralize `specialArgs` via `mkHost` helper | ~20 min | DRY, future-proof for new hosts |
| 🟢 Low | Rename `features/` → `modules/` | ~10 min | Semantic accuracy |
| 🟢 Low | Split locale/hardware out of `desktop.nix` | ~15 min | Enables headless hosts |
| 🟢 Low | Make `guest-wipe.nix` configurable | ~15 min | Avoids hardcoded usernames |
| 🟢 Low | Move secrets to `secrets/` directory | ~5 min | Cleaner taxonomy |
| 🟢 Low | Sandbox experiments directory | ~10 min | Drop-in experiment files |
| 🟢 Low | Clean up stale AGENTS.md references | ~10 min | Documentation accuracy |
| ⚪ Optional | `mkUser` helper | ~20 min | DRY for 4+ users |

---

> [!NOTE]
> **Philosophy:** This config is already in the top tier of NixOS repos
> I've seen. The changes above are refinements, not rewrites. The biggest
> wins are structural (collapsing `extra/`, moving `hjem-ext.nix`) because
> they reduce the number of places you have to look when debugging. The
> code itself is well-written and well-documented.
