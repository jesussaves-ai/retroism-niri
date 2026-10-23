#!/usr/bin/env fish
# Disk cleanup for Arch/CachyOS — run with sudo.
#
#   sudo fish scripts/cleanup-disk.fish            # report only (safe)
#   sudo fish scripts/cleanup-disk.fish --apply    # actually clean
#
# Keeps the 2 most recent versions of every package in the cache.

set -g APPLY no
for a in $argv
    switch $a
        case --apply
            set -g APPLY yes
        case -h --help
            echo "usage: sudo fish scripts/cleanup-disk.fish [--apply]"
            exit 0
    end
end

test (id -u) -eq 0; or begin
    echo "run with sudo: sudo fish "(status filename)
    exit 1
end

function section; printf '\n== %s ==\n' $argv; end

section "before"
df -h / | tail -1
echo "pacman cache: "(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
echo "journal:      "(journalctl --disk-usage 2>/dev/null | string replace 'Archived and active journals take up ' '')

section "pacman cache (keep 2 versions)"
if test "$APPLY" = yes
    paccache -rk2
    paccache -ruk0
else
    echo "[dry] paccache -rk2 ; paccache -ruk0"
    paccache -dk2 | tail -3
end

section "orphaned packages"
set -l orphans (pacman -Qtdq 2>/dev/null)
if test (count $orphans) -eq 0
    echo "none"
else
    printf '  %s\n' $orphans
    if test "$APPLY" = yes
        echo $orphans | pacman -Rns --noconfirm -
    else
        echo "[dry] pacman -Rns "(count $orphans)" orphan(s)"
    end
end

section "journal (keep 2 weeks / 500M max)"
if test "$APPLY" = yes
    journalctl --vacuum-time=2weeks
    journalctl --vacuum-size=500M
else
    echo "[dry] journalctl --vacuum-time=2weeks --vacuum-size=500M"
end

section "after"
df -h / | tail -1
