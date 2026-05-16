#!/bin/sh
printf '\033c\033]0;%s\a' netcodeRemake
base_path="$(dirname "$(realpath "$0")")"
"$base_path/netcodeRemakeLinux.x86_64" "$@"
