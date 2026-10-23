import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

/* Terminal-style system monitor, styled like the Retroism screenshots.
 *
 * Fork-free: reads /proc directly through Quickshell FileView (reload() +
 * text()) on a 1 s timer. The previous implementation ran sysmon.sh, which
 * forked `sh -c sleep 1` twice every second forever.
 */
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

    FileView { id: statFile; path: "/proc/stat"; blockLoading: true; printErrors: false }
    FileView { id: memFile; path: "/proc/meminfo"; blockLoading: true; printErrors: false }
    FileView { id: loadFile; path: "/proc/loadavg"; blockLoading: true; printErrors: false }
    FileView { id: upFile; path: "/proc/uptime"; blockLoading: true; printErrors: false }

    property var prevTotal: []
    property var prevIdle: []

    function sample() {
        statFile.reload();
        memFile.reload();
        loadFile.reload();
        upFile.reload();

        // ── CPU per core ────────────────────────────────────────────────
        const st = statFile.text() || "";
        const totals = [];
        const idles = [];
        for (const line of st.split("\n")) {
            const m = /^cpu([0-9]+)\s+(.+)$/.exec(line);
            if (!m)
                continue;
            const idx = parseInt(m[1]);
            const f = m[2].trim().split(/\s+/).map(Number);
            totals[idx] = 0;
            for (let i = 0; i < 8; i++)
                totals[idx] += (f[i] || 0);
            idles[idx] = (f[3] || 0) + (f[4] || 0);
        }

        const usage = [];
        for (let i = 0; i < totals.length; i++) {
            if (prevTotal[i] === undefined) {
                usage[i] = 0;
            } else {
                const dt = totals[i] - prevTotal[i];
                const di = idles[i] - prevIdle[i];
                usage[i] = dt > 0 ? Math.max(0, Math.min(100, Math.round(100 * (dt - di) / dt))) : 0;
            }
        }
        prevTotal = totals;
        prevIdle = idles;
        coreUsage = usage;

        // ── Memory / swap ───────────────────────────────────────────────
        const mi = memFile.text() || "";
        let mt = 0, ma = 0, stt = 0, sf = 0;
        for (const line of mi.split("\n")) {
            const f = line.split(/\s+/);
            if (line.startsWith("MemTotal:")) mt = parseInt(f[1]) || 0;
            else if (line.startsWith("MemAvailable:")) ma = parseInt(f[1]) || 0;
            else if (line.startsWith("SwapTotal:")) stt = parseInt(f[1]) || 0;
            else if (line.startsWith("SwapFree:")) sf = parseInt(f[1]) || 0;
        }
        memPct = mt > 0 ? Math.round(100 * (mt - ma) / mt) : 0;
        swapPct = stt > 0 ? Math.round(100 * (stt - sf) / stt) : 0;

        // ── Load / uptime ───────────────────────────────────────────────
        const la = (loadFile.text() || "").trim().split(/\s+/);
        loadAvg = la[0] || "0.00";

        const up = Math.floor(parseFloat(upFile.text() || "0"));
        const h = Math.floor(up / 3600);
        const m = Math.floor((up % 3600) / 60);
        const s = up % 60;
        uptime = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.sample()
    }

    function pad(n, w) {
        n = "" + n;
        while (n.length < w)
            n = " " + n;
        return n;
    }

    function bar(pct, len) {
        const n = Math.max(0, Math.min(len, Math.round(pct / 100 * len)));
        let s = "";
        for (let i = 0; i < len; i++)
            s += (i < n ? "█" : "·");
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
