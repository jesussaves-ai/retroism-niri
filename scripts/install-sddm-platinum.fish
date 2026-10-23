#!/usr/bin/env fish
# Install the Retroism Platinum SDDM theme and make it current.
# Reversible: the previous /etc/sddm.conf.d/10-theme.conf is backed up.
#
#   sudo fish ~/linuxexpert/install-sddm-platinum.fish

set -l SRC /home/tom/linuxexpert/sddm-platinum
set -l DST /usr/share/sddm/themes/sddm-platinum

test (id -u) -eq 0; or begin
    echo "run with: sudo fish "(status filename)
    exit 1
end
test -d $SRC; or begin
    echo "missing source $SRC"
    exit 1
end

# World-readable so the greeter (sddm user) can load it
chmod -R a+rX $SRC

mkdir -p /etc/sddm.conf.d
if test -f /etc/sddm.conf.d/10-theme.conf
    set -l bak /etc/sddm.conf.d/10-theme.conf.bak.(date +%Y%m%d-%H%M%S)
    cp -a /etc/sddm.conf.d/10-theme.conf $bak
    echo "backed up existing theme config -> $bak"
end

rm -rf $DST
cp -r $SRC $DST
chown -R root:root $DST
chmod -R a+rX $DST
echo "installed theme -> $DST"

printf '[Theme]\nCurrent=sddm-platinum\n' > /etc/sddm.conf.d/10-theme.conf
echo "set Current=sddm-platinum in /etc/sddm.conf.d/10-theme.conf"
echo
echo "Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme $DST"
echo
echo "Takes effect on the next logout/reboot."
echo "Rollback:  sudo rm /etc/sddm.conf.d/10-theme.conf"
echo "        or restore the .bak file listed above."
