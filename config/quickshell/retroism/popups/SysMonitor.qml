import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import ".."

// Terminal-style system monitor, styled like the Retroism screenshots.
// Backed by utils/sysmon.sh (one persistent process, ~1 line/sec).
PopupWindow {
    id: root

    property int menuWidth: 0
    property var closeCallback: function () {}
    anchor.window: taskbar
    anchor.rect.x: menuWidth
    anchor.rect.y: parentWindow.implicitHeight
    implicitWidth: 430
    implicitHeight: 330
    color: "transparent"

    property var coreUsage: []
    property int memPct: 0
    property int swapPct: 0
    property string loadAvg: "0.00"
    property string uptime: "00:00:00"

    Process {
        id: sysProc
        command: ["sh", "/home/tom/.config/quickshell/retroism/utils/sysmon.sh"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/);
                const kv = {};
                for (const p of parts) {
                    const i = p.indexOf("=");
                    if (i > 0) kv[p.slice(0, i)] = p.slice(i + 1);
                }
                if (kv.cores) root.coreUsage = kv.cores.split(",").map(x => parseInt(x));
                if (kv.mem) root.memPct = parseInt(kv.mem);
                if (kv.swap) root.swapPct = parseInt(kv.swap);
                if (kv.load) root.loadAvg = kv.load;
                if (kv.uptime) root.uptime = kv.uptime;
            }
        }
    }

    function pad(n, w) {
        n = "" + n;
        while (n.length < w) n = " " + n;
        return n;
    }
    function bar(pct, len) {
        const n = Math.max(0, Math.min(len, Math.round(pct / 100 * len)));
        let s = "";
        for (let i = 0; i < len; i++) s += (i < n ? "█" : "·");
        return s;
    }
    property string display: {
        const cu = root.coreUsage;
        const half = Math.ceil(cu.length / 2);
        let lines = [];
        for (let r = 0; r < half; r++) {
            let a = (cu[r] !== undefined) ? pad(r, 2) + "[" + bar(cu[r], 10) + "]" + pad(cu[r], 3) + "%" : "";
            let bi = r + half;
            let b = (cu[bi] !== undefined) ? pad(bi, 2) + "[" + bar(cu[bi], 10) + "]" + pad(cu[bi], 3) + "%" : "";
            lines.push(a + "   " + b);
        }
        lines.push("");
        lines.push("Mem[" + bar(root.memPct, 18) + "] " + pad(root.memPct, 3) + "%    Load: " + root.loadAvg);
        lines.push("Swp[" + bar(root.swapPct, 18) + "] " + pad(root.swapPct, 3) + "%    Up:   " + root.uptime);
        return lines.join("\n");
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        color: Config.colors.base
        layer.enabled: true

        property int topOffset: 20

        PopupWindowFrame {
            id: sysFrame
            windowTitle: "System Monitor"
            windowTitleIcon: "\ue30c"
            windowTitleDecorationWidth: 120

            Item {
                id: content
                anchors.fill: sysFrame
                anchors.margins: 16
                anchors.topMargin: frame.topOffset + 16
                clip: true

                Text {
                    anchors.fill: parent
                    text: root.display
                    color: Config.colors.text
                    font.family: fontMonaco.name
                    font.pixelSize: 12
                    lineHeight: 1.15
                    wrapMode: Text.NoWrap
                }
            }
        }
    }

    function toggle() {
        root.visible = !root.visible;
    }
}
