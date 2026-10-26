#!/bin/bash
# Tier 3 — Hibernação real (S4). Rodar com: sudo ./tier3_pmset.sh
# Requer reboot com a nova EFI primeiro (HibernationFixup + RTCMemoryFixup + config).
# Receita portada do 5T33Z0/Thinkpad-T490 (mesmo platform Comet Lake).

echo "== ANTES =="
pmset -g | grep -iE "hibernate|standby|sleep|powernap|tcpkeep|womp"

# hibernatemode 25 = suspend to disk + RAM desligada (S4 real, consumo ~0)
# standby 1 + delays 900 = dorme em S3 por 15min, depois hiberna (resume rápido ou zero dreno)
pmset -a hibernatemode 25
pmset -a standby 1
pmset -a standbydelayhigh 300
pmset -a standbydelaylow 300

# anti-wake (reforço)
pmset -a powernap 0
pmset -a proximitywake 0
pmset -a ttyskeepawake 0
pmset -a womp 0
pmset -b tcpkeepalive 0
pmset -c tcpkeepalive 1

echo "== DEPOIS =="
pmset -g | grep -iE "hibernate|standby|sleep|powernap|tcpkeep|womp"

# ROLLBACK:
# sudo pmset -a hibernatemode 0 standby 0 standbydelayhigh 86400 standbydelaylow 10800
# sudo pmset -a womp 1 ttyskeepawake 1
