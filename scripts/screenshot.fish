#!/usr/bin/env fish
# Screenshot helper for niri + grim.
#
#   screenshot.fish            # region (needs slurp) or full screen if absent
#   screenshot.fish full
#   screenshot.fish region
#
# Saves to ~/Pictures/Screenshots and copies to the clipboard.

set -l dir $HOME/Pictures/Screenshots
mkdir -p $dir
set -l file $dir/(date +%Y-%m-%d_%H-%M-%S).png
set -l mode (test -n "$argv[1]"; and echo $argv[1]; or echo region)

switch $mode
    case full
        grim $file
    case region
        if command -q slurp
            set -l geom (slurp)
            or begin
                echo "cancelled"
                exit 0
            end
            grim -g "$geom" $file
        else
            grim $file
        end
    case '*'
        echo "usage: screenshot.fish [full|region]"
        exit 1
end

test -f $file; or begin
    echo "screenshot failed"
    exit 1
end

if command -q wl-copy
    wl-copy < $file
end
if command -q notify-send
    notify-send "Screenshot" "Saved "(path basename $file)" and copied to clipboard"
end
echo $file
