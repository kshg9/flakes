# Installer ISO (minimal, birdee-style)

Borrowed from BirdeeHub's `birdeeSystems` (`systems/installers/`, `scripts/isoInstaller`,
`.github/workflows/release.yml`). Builds the official NixOS **minimal graphical installer
ISO** with this flake's source baked in, so a fresh install is one command.

## The config (`nixos/hosts/installer/configuration.nix`)

- imports `"${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"`
  — birdee's exact choice: X server + gparted/firefox/vim/nano, **no desktop environment**.
  **No Calamares**: Calamares installs the static ISO image and knows nothing about
  disko/flakes — the real install is `urielOS`. (Birdee also dropped Calamares in their
  released `installer_mine`.)
- **Fullscreen terminal session, birdee-style**: lightdm autologin (`nixos` user) into a
  custom `desktopManager.session` that launches **kitty maximized running tmux**
  (`tmux new -A -s install`). Maximization is done by the vendored
  `packages/maximizer/` — birdee's tiny C program (`maximizer.c`, Xlib+XRandR) that finds
  a window by title substring and resizes it to fill the screen, since a raw X server has
  no window manager. Boot → big terminal, `urielOS <target>`.
- `image.baseName = lib.mkForce "flakes-installer"` → ISO named `flakes-installer.iso`
  (note: current nixpkgs uses `image.baseName`, the old `isoImage.isoBaseName` is gone).
- `isoImage.contents = [ { source = inputs.self; target = "/nixos"; } ]` — embeds the
  flake source on the ISO. In the live environment the ISO is mounted at `/iso`, so the
  flake lives at `/iso/nixos` — the alias uses this path. Installs need no git/ssh auth
  and install exactly the config the ISO was built from. (Birdee instead git-clones from
  GitHub in the alias; embedding is more robust for a private repo.)
- pinned `inputs.disko.packages.<sys>.disko` added to `systemPackages`, so the install
  alias uses the locked disko (not `nix run github:...` latest).
- `nixpkgs.hostPlatform` must be set — install-cd modules require it (uriel/sandbox get it
  from their `hardware-configuration.nix`; the installer has none).

## The one-shot install alias (`urielOS`)

Set as `environment.shellAliases.urielOS` (a `writeShellScript`). On the live ISO:

```bash
urielOS [target] [user]
#  target: config to install     (default uriel)
#  user:   password to set       (default kdj)
#
#  1. sudo disko --mode destroy,format,mount --flake /nixos#<target>
#  2. sudo nixos-install --flake /nixos#<target>
#  3. sudo passwd --root /mnt <user>       # set real password
#  4. copy /nixos → /mnt/home/<user>/flakes  # keep the config on the box
```

Each machine gets its own hardened disko config (`nixos/hosts/<target>/disko.nix`, disk
by-id hardcoded); the target name selects it — same pattern as birdee's `birdeeOS`.
`disko --flake /nixos#<target>` works because flake-parts exposes each
`diskoConfigurations.<target>` as a top-level flake output. No args, no overrides.

## Build

```bash
scripts/build-iso.sh            # → ./result/iso/flakes-installer.iso
# write to USB:
sudo dd if=result/iso/flakes-installer.iso of=/dev/sdX bs=1M status=progress
```

Big build (X + kernel). The fast gate is
`nix eval .#nixosConfigurations.installer.config.system.build.isoImage.drvPath`.

## Gotchas

- ISO embeds the git-tracked source (`inputs.self`). Dirty *untracked* files won't be in
  it — commit/stage first (`git add -A`) for a true "latest and greatest" ISO.
- `nixos-install --flake /nixos#uriel` builds uriel's full config at install time
  (impermanence/LUKS included) — network needed on the live system.
- Don't run `urielOS` on a machine whose disk you don't want wiped — `disko
  --mode destroy,format,mount` destroys partitions on the target device (per-machine
  `device` in `nixos/hosts/<target>/disko.nix`).
