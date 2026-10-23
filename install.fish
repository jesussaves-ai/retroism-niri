#!/usr/bin/env fish
# =============================================================================
# Retroism dotfiles installer (niri + Quickshell + GTK/Qt retrowave)
#
#   fish install.fish              # install (backs up anything it replaces)
#   fish install.fish --dry-run    # show what would happen
#   fish install.fish --nemo       # also load Nemo preferences via dconf
#   sudo fish scripts/install-sddm-platinum.fish   # login screen (separate)
#
# Config directories are SYMLINKED into ~/.config, so edits made live are
# already in the repo. Anything it replaces is moved to
# ~/.config-backup-<timestamp>/.
# =============================================================================

set -g REPO (realpath (status dirname))
set -g CFG $HOME/.config
set -g STAMP (date +%Y%m%d-%H%M%S)
set -g BACKUP $HOME/.config-backup-$STAMP
set -g DRY no
set -g DO_NEMO no

for a in $argv
    switch $a
        case --dry-run
            set -g DRY yes
        case --nemo
            set -g DO_NEMO yes
        case -h --help
            echo "usage: fish install.fish [--dry-run] [--nemo]"
            exit 0
    end
end

function say; printf '  %s\n' $argv; end
function run
    if test "$DRY" = yes
        printf '  [dry] %s\n' (string join ' ' -- $argv)
    else
        command $argv
    end
end

# config-relative-name -> repo path
set -l pairs \
    niri:config/niri \
    ghostty:config/ghostty \
    gtk-3.0:config/gtk-3.0 \
    gtk-4.0:config/gtk-4.0 \
    quickshell/retroism:config/quickshell/retroism

echo "== Retroism installer =="
test "$DRY" = yes; and echo "   (dry run - nothing will be changed)"

for pair in $pairs
    set -l parts (string split ':' $pair)
    set -l name $parts[1]
    set -l rel $parts[2]
    set -l src $REPO/$rel
    set -l dst $CFG/$name

    if not test -e $src
        say "skip $name (missing $rel)"
        continue
    end

    if test -L $dst
        say "relink $name"
        run ln -sfn $src $dst
    else if test -e $dst
        say "backup $name -> $BACKUP/$name"
        run mkdir -p $BACKUP/(dirname $name)
        run mv $dst $BACKUP/$name
        run ln -sfn $src $dst
    else
        say "link $name"
        run mkdir -p (dirname $dst)
        run ln -sfn $src $dst
    end
end

echo "== fonts =="
run mkdir -p $HOME/.local/share/fonts
for f in $REPO/assets/fonts/*.ttf
    test -f $f; or continue
    say "install "(basename $f)
    run cp -n $f $HOME/.local/share/fonts/
end
run fc-cache -f

echo "== Qt / KDE (Dolphin & co) =="
run mkdir -p $HOME/.local/share/color-schemes
run cp $REPO/desktop/Platinum.colors $HOME/.local/share/color-schemes/
if test -e $CFG/kdeglobals
    say "backup kdeglobals -> $BACKUP/kdeglobals"
    run mkdir -p $BACKUP
    run cp $CFG/kdeglobals $BACKUP/kdeglobals
end
run cp $REPO/config/kde/kdeglobals $CFG/kdeglobals
say "Platinum colour scheme + Fusion + Charcoal + RetroismIcons"

# Kvantum theme (optional; needs kvantum + qt6ct installed)
if test -d $HOME/.config/Kvantum
    run mkdir -p $CFG/Kvantum/Platinum
    run cp $REPO/config/Kvantum/kvantum.kvconfig $CFG/Kvantum/
    run cp $REPO/config/Kvantum/Platinum/Platinum.kvconfig $CFG/Kvantum/Platinum/
    run cp $REPO/config/Kvantum/Platinum/Platinum.svg $CFG/Kvantum/Platinum/
    run mkdir -p $CFG/qt6ct/colors
    run cp $REPO/config/qt6ct/qt6ct.conf $CFG/qt6ct/qt6ct.conf
    run cp $REPO/config/qt6ct/colors/Platinum.conf $CFG/qt6ct/colors/Platinum.conf
    say "Kvantum 'Platinum' theme + qt6ct config"
else
    say "Kvantum not installed - skipped (pacman -S kvantum qt6ct)"
end

echo "== LibreWolf chrome =="
set -l lwroot $HOME/.config/librewolf/librewolf
if test -d $lwroot
    # pick the profile that actually has state (prefs.js), not the empty stub
    set -l prof ""
    for d in $lwroot/*.default*
        if test -f $d/prefs.js
            set prof $d
            break
        end
    end
    if test -n "$prof"
        say "profile: "(basename $prof)
        run mkdir -p $prof/chrome
        run cp $REPO/config/librewolf/userChrome.css $prof/chrome/
        run cp $REPO/config/librewolf/userContent.css $prof/chrome/
        if test "$DRY" = no
            grep -q 'legacyUserProfileCustomizations' $prof/user.js 2>/dev/null
            or printf 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n' >> $prof/user.js
            say "user.js ensures stylesheets are enabled"
        else
            say "[dry] enable toolkit.legacyUserProfileCustomizations.stylesheets"
        end
    else
        say "no LibreWolf profile with prefs.js found - skipped"
    end
else
    say "LibreWolf not installed - skipped"
end

if test "$DO_NEMO" = yes
    echo "== Nemo preferences =="
    if test -f $REPO/desktop/nemo.dconf
        if test "$DRY" = yes
            say "[dry] dconf load /org/nemo/"
        else
            dconf load /org/nemo/ < $REPO/desktop/nemo.dconf
            say "loaded desktop/nemo.dconf"
        end
    end
end

echo
echo "Done."
test "$DRY" = no -a -d $BACKUP; and echo "Backups: $BACKUP"
echo "Next:"
echo "  sudo fish $REPO/scripts/install-sddm-platinum.fish   # login screen"
echo "  log out and back in (or 'qs -c retroism' / 'niri msg action quit')"
