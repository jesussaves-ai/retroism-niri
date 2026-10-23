#!/bin/sh
# Emits the niri workspace list as one compact JSON array per change.
# Replaces the Quickshell.Niri module (not present in upstream Quickshell),
# so the shell works with the stock `quickshell` package.
#
# Output: [{"idx":1,"output":"eDP-1","focused":true,"active":true,"urgent":false},...]
emit() {
    niri msg --json workspaces 2>/dev/null \
        | jq -c 'sort_by(.idx) | map({idx: .idx, output: .output, focused: .is_focused, active: .is_active, urgent: .is_urgent})' \
        || echo '[]'
}

emit

niri msg --json event-stream 2>/dev/null | while IFS= read -r line; do
    case "$line" in
    *WorkspacesChanged* | *WorkspaceActivated* | *WorkspaceUrgencyChanged*)
        emit
        ;;
    esac
done
