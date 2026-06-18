set shell := ["bash", "-uc"]

disko:
    @echo "=== Running disko script ==="
    bash ./scripts/disko.sh

install:
    @echo "=== Running install script ==="
    bash ./scripts/install.sh

check:
    @echo "=== Dry-run: checking what will build vs fetch ==="
    bash ./scripts/check.sh

rebuild:
    @echo "=== Running rebuild script ==="
    bash ./scripts/rebuild.sh
