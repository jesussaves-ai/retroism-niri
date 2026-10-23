#!/bin/sh
# Continuous system stats for the Retroism "System Monitor" overlay.
# One long-lived process; emits one line per second (no per-tick process forks
# except a single `sleep`, which awk invokes via system()).
#
# Line format (space separated):
#   cores=5,3,7,... mem=42 swap=0 load=0.94 uptime=05:23:16
exec awk '
  function sample(   line, a, n, idx, tot, idl) {
    while ((getline line < "/proc/stat") > 0) {
      if (line ~ /^cpu[0-9]/) {
        n = split(line, a, " ")
        idx = substr(a[1], 4) + 0
        tot = a[2]+a[3]+a[4]+a[5]+a[6]+a[7]+a[8]+a[9]
        idl = a[5]+a[6]
        curT[idx] = tot; curI[idx] = idl
        if (idx + 1 > ncpu) ncpu = idx + 1
      }
    }
    close("/proc/stat")
  }
  BEGIN {
    sample()
    for (c = 0; c < ncpu; c++) { prevT[c] = curT[c]; prevI[c] = curI[c] }
    while (1) {
      system("sleep 1")
      sample()
      out = ""
      for (i = 0; i < ncpu; i++) {
        dt = curT[i] - prevT[i]; di = curI[i] - prevI[i]
        u = (dt > 0) ? int(100*(dt-di)/dt) : 0
        if (u < 0) u = 0; if (u > 100) u = 100
        out = out (i > 0 ? "," : "") u
        prevT[i] = curT[i]; prevI[i] = curI[i]
      }
      mt = 0; ma = 0; st = 0; sf = 0
      while ((getline l < "/proc/meminfo") > 0) {
        split(l, f, /[ \t]+/)
        if (l ~ /^MemTotal:/) mt = f[2]
        else if (l ~ /^MemAvailable:/) ma = f[2]
        else if (l ~ /^SwapTotal:/) st = f[2]
        else if (l ~ /^SwapFree:/) sf = f[2]
      }
      close("/proc/meminfo")
      mem = (mt > 0) ? int(100*(mt-ma)/mt) : 0
      swp = (st > 0) ? int(100*(st-sf)/st) : 0
      getline ll < "/proc/loadavg"; close("/proc/loadavg")
      split(ll, la, " ")
      getline up < "/proc/uptime"; close("/proc/uptime")
      up = int(up); h = int(up/3600); m = int((up%3600)/60); s = up%60
      printf "cores=%s mem=%d swap=%d load=%s uptime=%02d:%02d:%02d\n", out, mem, swp, la[1], h, m, s
      fflush()
    }
  }
'
