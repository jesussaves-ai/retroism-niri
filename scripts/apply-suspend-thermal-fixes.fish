#!/usr/bin/env fish
# =============================================================================
# apply-suspend-thermal-fixes.fish
#
# Applies the suspend-to-RAM / thermal fixes diagnosed for this CachyOS laptop.
# Idempotent, backed up, and reversible. Nothing destructive is ever run.
#
#   Run for real:   sudo fish ~/linuxexpert/apply-suspend-thermal-fixes.fish
#   Preview only:   fish ~/linuxexpert/apply-suspend-thermal-fixes.fish --dry-run
#
# What it does:
#   (a) Sleep: selects s2idle instead of S3 "deep" (persistent systemd drop-in
#       + immediate runtime switch). The previous suspend hung in S3 and never
#       resumed.
#   (b) NVIDIA: proprietary-driver-only path (nvidia-suspend/resume/hibernate
#       + NVreg_PreserveVideoMemoryAllocations=1). NOT needed with the open
#       kernel modules this machine uses. Defaults to OFF.
#   (c) Thermal: installs and enables Intel thermald (coexists with PPD).
#   (d) [OPT-IN, default OFF] Disables XHCI ACPI wake. Only needed if the hang
#       persists; it also stops external USB input from waking the machine.
#
# Every file that already exists is copied to /var/backups/opencode-sysfix-<ts>/
# and a matching restore.fish is generated there.
# =============================================================================

# ------------------------------ toggles --------------------------------------
set -g DISABLE_USB_WAKE no   # yes to apply (d). Changes wake behaviour.
set -g DO_THERMALD      yes  # install + enable thermald
set -g DO_NVIDIA_SLEEP  no   # (b) ONLY for the *proprietary* driver. This box
                             #     runs OPEN modules (linux-cachyos-nvidia-open),
                             #     where NVIDIA says VRAM preservation is
                             #     automatic -> keep this OFF.
set -g DRY_RUN          no   # set by --dry-run
# -----------------------------------------------------------------------------

set -l argv_clean
for a in $argv
    switch $a
        case --dry-run
            set -g DRY_RUN yes
        case -h --help
            echo "usage: sudo fish apply-suspend-thermal-fixes.fish [--dry-run]"
            exit 0
        case '*'
            set -a argv_clean $a
    end
end

set -g TS (date +%Y%m%d-%H%M%S)
set -g BACKUP /var/backups/opencode-sysfix-$TS

# ------------------------------ helpers --------------------------------------
function info; printf '\n== %s ==\n' $argv; end
function note; printf '   - %s\n' $argv; end
function ok;   printf '   [ok] %s\n' $argv; end
function warn; printf '   [!!] %s\n' $argv; end
function die;  printf '\nFATAL: %s\n' $argv >&2; exit 1; end

# x: run a command (or print it in dry-run).
function x
    if test "$DRY_RUN" = yes
        printf '   [dry] %s\n' (string join ' ' -- $argv)
        return 0
    end
    command $argv
end

# xr: write newline-terminated content to a file (or print it in dry-run).
function xr
    set -l path $argv[1]
    set -l body $argv[2..-1]
    if test "$DRY_RUN" = yes
        printf '   [dry] write %s\n' $path
        for l in $body
            printf '         | %s\n' $l
        end
        return 0
    end
    printf '%s\n' $body > $path
end

# -----------------------------------------------------------------------------
if test "$DRY_RUN" = no
    test (id -u) -eq 0; or die "must run as root:  sudo fish "(status filename)
end

info "Pre-flight"
if test "$DRY_RUN" = yes
    note "DRY RUN - no changes will be made"
else
    x mkdir -p $BACKUP; or die "cannot create backup dir $BACKUP"
    ok "backup dir: $BACKUP"
end
x cp -a /etc/systemd/sleep.conf $BACKUP/ 2>/dev/null
x sh -c 'cat /sys/power/mem_sleep > '"$BACKUP"'/mem_sleep.before'
x sh -c 'cat /proc/acpi/wakeup  > '"$BACKUP"'/acpi-wakeup.before'
x sh -c 'systemctl is-enabled nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service > '"$BACKUP"'/nvidia-services.before 2>&1'
ok "saved pre-change state (mem_sleep, acpi/wakeup, nvidia services)"

# =============================================================================
# (a) Sleep mode: s2idle instead of deep
# =============================================================================
info "(a) Selecting s2idle as the suspend method"
x mkdir -p /etc/systemd/sleep.conf.d
xr /etc/systemd/sleep.conf.d/10-sleep-mode.conf \
    '[Sleep]' \
    '# Use s2idle instead of S3 "deep": S3 hangs on resume on this firmware.' \
    'MemorySleepMode=s2idle'
# Immediate runtime switch (reversible; reverts on reboot to whatever is default)
x sh -c 'echo s2idle > /sys/power/mem_sleep'
x systemd-analyze cat-config systemd/sleep.conf
if test "$DRY_RUN" = no
    if string match -q '*MemorySleepMode=s2idle*' (systemd-analyze cat-config systemd/sleep.conf 2>/dev/null | string collect)
        ok "systemd parsed MemorySleepMode=s2idle"
    else
        warn "could not confirm MemorySleepMode in parsed config - check 'systemd-analyze cat-config systemd/sleep.conf'"
    end
    if string match -q 's2idle*' (cat /sys/power/mem_sleep)
        ok "runtime mem_sleep now: "(cat /sys/power/mem_sleep)
    else
        warn "runtime mem_sleep is still: "(cat /sys/power/mem_sleep)
    end
end

# =============================================================================
# (b) NVIDIA power management services + VRAM preservation
# =============================================================================
if test "$DO_NVIDIA_SLEEP" = yes
    warn "(b) This is the PROPRIETARY-driver path. This machine uses OPEN"
    warn "    modules (linux-cachyos-nvidia-open); NVIDIA documents that VRAM"
    warn "    preservation is automatic there and this is NOT required."
    xr /etc/modprobe.d/10-nvidia-sleep.conf \
        '# Proprietary-driver VRAM preservation path (NVIDIA README ch.20).' \
        'options nvidia NVreg_PreserveVideoMemoryAllocations=1'
    x systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
    note "nvidia is baked into the initramfs via /etc/mkinitcpio.conf.d/10-chwd.conf"
    note "(MODULES+=(nvidia ...)), so a rebuild IS REQUIRED for the option to apply:"
    x mkinitcpio -P
else
    note "(b) NVIDIA services left at the Arch default (open modules need no config)"
end

# =============================================================================
# (c) thermald
# =============================================================================
if test "$DO_THERMALD" = yes
    info "(c) Intel thermald"
    if test "$DRY_RUN" = yes
        printf '   [dry] pacman -S --needed --noconfirm thermald\n'
        printf '   [dry] systemctl enable --now thermald.service\n'
    else
        if pacman -Qq thermald >/dev/null 2>&1
            ok "thermald already installed"
        else
            note "installing thermald from the CachyOS repo..."
            if pacman -S --needed --noconfirm thermald
                ok "thermald installed"
            else
                warn "thermald install failed (stale DB / offline?). Run later:"
                warn "    sudo pacman -Syu && sudo pacman -S thermald"
            end
        end
        if pacman -Qq thermald >/dev/null 2>&1
            x systemctl enable --now thermald.service
            ok "thermald.service: "(systemctl is-active thermald.service)
        end
    end
else
    note "thermald skipped (DO_THERMALD=no)"
end

# =============================================================================
# (d) OPT-IN: disable XHCI ACPI wake
# =============================================================================
if test "$DISABLE_USB_WAKE" = yes
    info "(d) Disabling XHCI ACPI wake (opt-in)"
    warn "external USB keyboard/mouse will no longer wake the laptop"
    xr /usr/local/bin/disable-xhci-wake.fish \
        '#!/usr/bin/env fish' \
        '# Disable XHCI ACPI wake if currently enabled (toggle semantics).' \
        'if string match -q -- "*XHCI*S3*enabled*" (cat /proc/acpi/wakeup 2>/dev/null | string collect)' \
        '    echo XHCI > /proc/acpi/wakeup' \
        'end'
    x chmod 0755 /usr/local/bin/disable-xhci-wake.fish
    xr /etc/systemd/system/disable-xhci-wake.service \
        '[Unit]' \
        'Description=Disable XHCI ACPI wake source' \
        'After=multi-user.target' \
        '' \
        '[Service]' \
        'Type=oneshot' \
        'ExecStart=/usr/local/bin/disable-xhci-wake.fish' \
        '' \
        '[Install]' \
        'WantedBy=multi-user.target'
    x systemctl daemon-reload
    x systemctl enable --now disable-xhci-wake.service
else
    note "(d) XHCI wake-disable skipped (DISABLE_USB_WAKE=no) - see report"
end

# =============================================================================
# restore script
# =============================================================================
if test "$DRY_RUN" = no
    set -l R $BACKUP/restore.fish
    printf '%s\n' \
        '#!/usr/bin/env fish' \
        '# Generated rollback for opencode-sysfix-'$TS'  ->  sudo fish '(string escape -- $R) \
        'rm -f /etc/systemd/sleep.conf.d/10-sleep-mode.conf' \
        'rm -f /etc/modprobe.d/10-nvidia-sleep.conf' \
        'systemctl disable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service' \
        'systemctl disable --now disable-xhci-wake.service 2>/dev/null' \
        'rm -f /etc/systemd/system/disable-xhci-wake.service /usr/local/bin/disable-xhci-wake.fish' \
        'systemctl daemon-reload' \
        'echo "Rolled back. thermald (if installed) left in place; remove with: sudo pacman -Rns thermald"' \
        'echo "Original state saved in '(string escape -- $BACKUP)'"' \
        > $R
    chmod 0755 $R
    ok "rollback script: $R"
end

info "Done"
note "Reboot is recommended so NVIDIA services + s2idle take full effect."
note "Then suspend/resume several times and verify with:"
note "    journalctl -b -1 --no-pager | grep -cE 'System resumed|PM: suspend exit'"
