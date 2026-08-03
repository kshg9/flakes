# qylock — star-rail SDDM theme + Quickshell lockscreen (upstream flake input)

Used from upstream `Darkkal44/qylock` (https://github.com/Darkkal44/qylock) as a
plain flake input, **not vendored**. The login screen (SDDM) and the session
lockscreen (`qylock-lock`) both get the `star-rail` theme: a video background
(`bg.mp4`), DIN-style font, Star Rail gold/blue palette.

## Why a plain input (not vendored)

The upstream repo is **~1.2 GB** (video assets for many themes). Vendoring only
the bits we wanted was attempted first (`packages/qylock/` with star-rail
theme + SddmShim shims) but the upstream flake module does it all already:

```nix
inputs.qylock.url = "github:Darkkal44/qylock";
# ... qylock.nixosModules.default, then:
programs.qylock = {
  enable = true;
  theme = "star-rail";      # any directory name under themes/
  # sddm.enable = true;     # installs + activates an SDDM theme (default)
  # quickshell.enable = true; # adds `qylock-lock` to PATH (default)
  themeOptions = { ... };   # replaces interactive prompts per-theme
};
```

The earlier ISO-size worry is a non-issue: our installer already fetches flake
inputs at install time (`urielOS` = disko + `nixos-install --flake /nixos#uriel`),
so a big input doesn't bloat the ISO.

## Module

- `nixos/features/qylock.nix` — thin wrapper: imports
  `inputs.qylock.nixosModules.default`, sets
  `programs.qylock = { enable = true; theme = lib.mkDefault "star-rail"; }`
  (both `sddm.enable` and `quickshell.enable` stay at upstream's recommended
  defaults = true). Toggle by renaming to `_qylock.nix` (`_`-toggle convention).
  Hosts import it conditionally:
  `lib.optional (self ? nixosModules.qylock) self.nixosModules.qylock`.
- **Per-desktop themes**: hosts override `programs.qylock.theme`
  (`uriel` = star-rail, `sandbox` = nier-automata). The theme applies to both
  the SDDM greeter and the session lockscreen.
- OFF = plain SDDM (default breeze greeter), `qylock-lock` gone from PATH; the
  niri `Mod+Shift+Q` bind stays declared and silently spawns nothing.

## Login flow (SDDM + niri)

- `desktop.nix`: `services.xserver.enable = true` + `services.displayManager.sddm.enable = true`
  + `services.displayManager.sessionPackages = [ selfpkgs.niri ]` +
  `systemd.packages = [ selfpkgs.niri ]`. qylock's `sddm.enable` installs the
  theme under SDDM's theme dir and activates it — no manual
  `services.displayManager.sddm.theme` needed.
- An earlier detour replaced SDDM with getty autologin (niri exec'd from the
  login shell) — reverted, SDDM is the recommended qylock pairing.

## Lock keybind

- niri `"Mod+Shift+Q".spawn = "qylock-lock"` (`wrappedPrograms/niri.nix`).

## Available themes (themes/ in upstream)

clockwork, dog-samurai, enfield, field, forest, Genshin, girl-coffee,
girl-pillow, last-of-us, man-bicycle, material-you, minecraft, nier-automata,
ninesols, ninja_gaiden, nothing, osu, osumania, pixel-coffee, pixel-cyberpunk,
pixel-dusk-city, pixel-emerald, pixel-hollowknight, pixel-munchlax,
pixel-night-city, pixel-rainyroom, pixel-sakura, pixel-skyscrapers,
pixel-waterfall, R1999_1, R1999_2, star-rail, sword, terraria, windows_7,
winter, women-umbrella, wuwa.

## Gotchas

- `.gitignore` is an allowlist — no new source extensions were needed since
  nothing is vendored anymore (`.qml`/`.mp4`/etc. rules were removed again).
- First eval/build fetches the ~1.2 GB input; allow a long timeout.
- The old vendored approach (`packages/qylock/`, `packages.qylock-sddm`/
  `packages.qylock-lock`, SddmShim, `themes_link`, qtmultimedia QT_PLUGIN_PATH
  env) is deleted — do not resurrect it. Same for the getty-autologin detour:
  keep SDDM (it's the recommended qylock pairing).

## Reference

- Upstream repo: `https://github.com/Darkkal44/qylock` (README example used verbatim).
- Shallow clone for inspection: `/tmp/opencode/qylock`.
