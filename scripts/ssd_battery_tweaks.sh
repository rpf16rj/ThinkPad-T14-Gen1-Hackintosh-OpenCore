#!/bin/bash
# SSD + bateria tweaks — rode: sudo ./ssd_battery_tweaks.sh
set -e

# 1) noatime no Data volume (corta write de atime a cada read)
cat > /Library/LaunchDaemons/local.noatime.plist << 'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.noatime</string>
<key>ProgramArguments</key><array><string>/sbin/mount</string><string>-vuwo</string><string>noatime</string><string>/System/Volumes/Data</string></array>
<key>RunAtLoad</key><true/>
</dict></plist>
PL
launchctl load -w /Library/LaunchDaemons/local.noatime.plist && mount -vuwo noatime /System/Volumes/Data
echo "[1] noatime ok"

# 2) logd: persist off (para de gravar ~500MB/dia de tracev3 no SSD)
log config --mode "persist:off" && echo "[2] log persist off"

# 3) ReportCrash off (cores/.ips no SSD)
launchctl unload -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist 2>/dev/null || true
launchctl unload -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist 2>/dev/null || true
ulimit -c 0 && echo "[3] reportcrash off"

# 4) snapshots locais do Time Machine (COW churn)
tmutil deletelocalsnapshots / 2>/dev/null; tmutil thinlocalsnapshots / 10000000000 4 2>/dev/null || true
echo "[4] snapshots purgados"

# 5) Spotlight OFF no volume de dados (mds_stores = top writer)
mdutil -i off /System/Volumes/Data && mdutil -E /System/Volumes/Data && echo "[5] spotlight off"

# 6) pmset extras
pmset -a womp 0 acwake 0
pmset -b lessbright 1
echo "[6] pmset extras"

# 7) sysctl daemon (latência TCP + fd limits)
cat > /Library/LaunchDaemons/local.sysctls.plist << 'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.sysctls</string>
<key>ProgramArguments</key><array>
<string>/bin/sh</string><string>-c</string>
<string>/usr/sbin/sysctl -w net.inet.tcp.delayed_ack=0 kern.maxfilesperproc=262144 kern.ipc.somaxconn=1024</string>
</array>
<key>RunAtLoad</key><true/>
</dict></plist>
PL
launchctl load -w /Library/LaunchDaemons/local.sysctls.plist
sysctl -w net.inet.tcp.delayed_ack=0 kern.maxfilesperproc=262144 kern.ipc.somaxconn=1024
echo "[7] sysctls ok"

# 8) RAM disk 1GB p/ caches de browser (cria no boot)
cat > /Library/LaunchDaemons/local.ramdisk.plist << 'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.ramdisk</string>
<key>ProgramArguments</key><array>
<string>/bin/sh</string><string>-c</string>
<string>/usr/sbin/diskutil erasevolume HFS+ RAMD `/usr/bin/hdiutil attach -nobrowse -nomount ram://2097152`</string>
</array>
<key>RunAtLoad</key><true/>
</dict></plist>
PL
launchctl load -w /Library/LaunchDaemons/local.ramdisk.plist
diskutil erasevolume HFS+ RAMD `hdiutil attach -nobrowse -nomount ram://2097152` >/dev/null
echo "[8] RAM disk /Volumes/RAMD criado"

echo ""
echo "PRONTO. Passos manuais opcionais:"
echo "- Chrome/Firefox: apontar cache pro /Volumes/RAMD (ou browser.cache.disk.enable=false no Firefox = RAM-only)"
echo "- tmutil: mantenha 'Back Up Automatically' OFF (senao volta a gerar snapshots)"

# --- ROUND 2 (final sweep) ---
# I/O throttle off p/ background tasks (TM/backups full speed)
cat > /Library/LaunchDaemons/local.nothrottle.plist << 'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.nothrottle</string>
<key>ProgramArguments</key><array>
<string>/bin/sh</string><string>-c</string>
<string>/usr/sbin/sysctl -w debug.lowpri_throttle_enabled=0 net.inet.tcp.sendspace=4194304 net.inet.tcp.recvspace=4194304 net.inet.tcp.win_scale_factor=8</string>
</array>
<key>RunAtLoad</key><true/>
</dict></plist>
PL
launchctl load -w /Library/LaunchDaemons/local.nothrottle.plist
sysctl -w debug.lowpri_throttle_enabled=0 net.inet.tcp.sendspace=4194304 net.inet.tcp.recvspace=4194304 net.inet.tcp.win_scale_factor=8
echo "[9] io-throttle off + tcp windows ok"
