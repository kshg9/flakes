#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "changepass: must be run as root (try: sudo changepass)" >&2
  exit 1
fi

root="/"
user=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      if [ $# -lt 2 ]; then
        echo "changepass: --root needs a path" >&2
        exit 1
      fi
      root="$2"
      shift 2
      ;;
    -h | --help)
      echo "usage: changepass [--root CHROOT_DIR] [user]"
      exit 0
      ;;
    *)
      user="$1"
      shift
      ;;
  esac
done

if [ -z "$user" ]; then
  user="${SUDO_USER:-$USER}"
fi
dir="$root/persist/passwords"
file="$dir/$user"

if [ ! -d "$root/persist" ]; then
  echo "changepass: $root/persist does not exist (no /persist on this machine?)" >&2
  exit 1
fi

read -s -r -p "New password: " pw1 && echo
read -s -r -p "Retype new password: " pw2 && echo
if [ "$pw1" != "$pw2" ]; then
  echo "changepass: passwords do not match" >&2
  exit 1
fi
if [ -z "$pw1" ]; then
  echo "changepass: empty passwords are not allowed" >&2
  exit 1
fi

hash="$(printf '%s\n' "$pw1" | mkpasswd -m sha-512 -s)"
pw1=""
pw2=""

umask 077
mkdir -p "$dir"
printf '%s\n' "$hash" > "$file"
chown root:root "$file"

if [ "$root" = "/" ]; then
  printf '%s:%s\n' "$user" "$hash" | chpasswd -e
else
  printf '%s:%s\n' "$user" "$hash" | chpasswd -e -R "$root"
fi

echo "changepass: password updated for $user ($file)"
