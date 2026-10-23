#!/usr/bin/env fish
# Switch the Qt widget style between:
#   kvantum  -> Platinum bevels (3D, slightly rounded corners)
#   fusion   -> sharp corners, flat (pure Fusion + Platinum colour scheme)
#
#   fish scripts/qt-style.fish kvantum
#   fish scripts/qt-style.fish fusion
#   fish scripts/qt-style.fish          # show current
#
# New Qt apps pick it up immediately; a running app must be restarted.

set -g CONF $HOME/.config/qt6ct/qt6ct.conf
set -g KV   $HOME/.config/Kvantum/kvantum.kvconfig
set -g mode $argv[1]

function current
    if test -f $CONF
        grep -q '^style=kvantum' $CONF; and echo kvantum; or echo fusion
    else
        echo "unset"
    end
end

switch "$mode"
    case kvantum fusion
        if not test -f $CONF
            echo "missing $CONF (is qt6ct installed?)"
            exit 1
        end
        sed -i -E "s/^style=.*/style=$mode/" $CONF
        if test "$mode" = kvantum
            printf '[General]\ntheme=Platinum\n' > $KV
            echo "Qt style: kvantum (Platinum bevels)"
        else
            echo "Qt style: fusion (sharp corners)"
        end
        echo "Restart Qt apps to see the change."
    case ''
        echo "current: "(current)
    case '*'
        echo "usage: fish scripts/qt-style.fish [kvantum|fusion]"
        exit 1
end
