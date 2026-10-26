#!/bin/bash
# Tier 1 — Ajustes de energia (rodar com: sudo ./tier1_pmset.sh)
# Rollback manual está comentado no final.

echo "== ANTES =="
pmset -g

# Bateria (-b): sleep 15min, tela apaga em 5min, sem wake por rede
pmset -b sleep 15 displaysleep 5 tcpkeepalive 0

# Tomada (-c): nunca dorme, tela apaga em 15min, permite wake-on-lan
pmset -c sleep 0 displaysleep 15 tcpkeepalive 1

# Geral (-a): sem autopoweroff/standby/powernap/proximitywake, sem hibernação
pmset -a autopoweroff 0 standby 0 powernap 0 proximitywake 0 hibernatemode 0

echo "== DEPOIS =="
pmset -g

# ROLLBACK (restaurar como estava antes):
# sudo pmset -a sleep 1 displaysleep 0 disksleep 10 standby 1 \
#   standbydelaylow 10800 standbydelayhigh 86400 powernap 0 \
#   tcpkeepalive 1 proximitywake 0 hibernatemode 0
