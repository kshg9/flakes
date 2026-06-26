# Acknowledgements

This configuration is the result of learning from many excellent people in the Nix community. While most of the configuration has been rewritten and adapted to suit my own workflow, these projects, articles, and repositories greatly influenced both my understanding and the final design.

## Major Inspirations

### NotAShelf — *Impermanence*

The article on impermanence was one of the most helpful resources for understanding persistent state on an otherwise ephemeral system.

* https://notashelf.dev/posts/impermanence

### Goxore — `nixconf`

I loved this config, I find it most readable and easily navigatable.

* https://github.com/Goxore/nixconf

### pluiedev — `flake`

An excellent repository that helped shape my understanding of Nix expressions, overlays, patching packages, and many practical aspects of building a maintainable flake. It also introduced me to several useful setup patterns including fonts, `deploy-rs`, and various deployment techniques.

* https://codeberg.org/pluiedev/flake

### Lunarnovaa — `lunix`

This repository served as my introduction to **Hjem**, and helped me understand how it can replace parts of Home Manager while keeping configurations clean and modular. *[[ Still WIP ]]*

* https://github.com/Lunarnovaa/lunix

---

## Repositories I Learned From

Each of these repositories contains ideas, patterns, or implementation details that influenced parts of this configuration.

* https://github.com/Ruixi-rebirth/flakes
* https://github.com/GetPsyched/homeless-shelter
* https://github.com/BirdeeHub/birdeeSystems
* https://github.com/mic92/dotfiles
* https://github.com/EmergentMind/nix-config ( I highly recommend his videos, I found nixos-anywhere most intreguing which lead me to going on full nix, and hence exposed to me to many different techniques. )
* https://github.com/ryan4yin/nix-config

They demonstrated different ways of structuring a NixOS configuration, I'm yet to finish reading all-of them completely though.

---
Thank you to everyone who publishes their configurations, writes blog posts, answers questions, and contributes to the Nix ecosystem.
