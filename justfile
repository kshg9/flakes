set shell := ["bash", "-uc"]

disko:
    @echo "=== Running disko script ==="
    bash ./scripts/disko.sh

install:
    @echo "=== Running install script ==="
    bash ./scripts/install.sh

rebuild:
    @echo "=== Running rebuild script ==="
    bash ./scripts/rebuild.sh
