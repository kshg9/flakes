# ruixi-rebirth — reference config inspiration & TODOs

Reference inspiration captured from `ruixi-rebirth`'s NixOS / dotfiles configuration.

## Todo & Ideas to Explore

1. **Emanote** (Note taking / PKM)
   - Site: https://emanote.srid.ca/start
   - Haskell-based static site generator for Markdown/Org notes with live preview.
   - Plan: Package or add flake input / hjem profile for note rendering.

2. **MPV with Anime4K Shaders**
   - High quality Anime4K GLSL shaders integrated into `mpv` dotfiles.
   - Configure via `hjem` in `~/.config/mpv/scripts` & `~/.config/mpv/mpv.conf`.

3. **Ruixi-rebirth style Search / Launcher**
   - Custom launcher / search interface setup (rofi / wofi / custom launcher scripts).
   - Evaluate alongside Noctalia launcher / Niri keybindings.

4. **Separate SSH & Zoxide Configs**
   - Move `ssh` (`~/.ssh/config` or `programs.ssh`) and `zoxide` configurations into standalone modular files (via `hjem` per-user dotfiles or wrappers).
   - Keep shell configuration minimal and modular.

5. **Android Setup**
   - Android development & utility suite (`adb`, `scrcpy`, `android-tools`, udev rules for android devices, android-studio / SDK setup).
