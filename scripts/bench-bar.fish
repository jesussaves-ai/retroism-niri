#!/usr/bin/env fish
# bench-bar.fish <process-name>
# Total RSS (MB) of <process-name> plus every descendant, so we can compare the
# Eww stack against Waybar fairly (Waybar spawns no helper listeners).
#
#   fish ~/linuxexpert/bench-bar.fish eww
#   fish ~/linuxexpert/bench-bar.fish waybar

set -l root (pgrep -x $argv[1] | head -n 1)
if test -z "$root"
    echo "$argv[1]: not running"
    exit 1
end

# BFS over the process tree
set -l queue $root
set -l seen
while test (count $queue) -gt 0
    set -l p $queue[1]
    set -e queue[1]
    contains -- $p $seen; and continue
    set -a seen $p
    for c in (pgrep -P $p 2>/dev/null)
        set -a queue $c
    end
end

set -l sum 0
for p in $seen
    set -l r (ps -o rss= -p $p 2>/dev/null)
    test -n "$r"; and set sum (math $sum + $r)
end

printf '%-10s tree RSS: %6.1f MB   (%d process(es))\n' $argv[1] (math "$sum / 1024") (count $seen)
