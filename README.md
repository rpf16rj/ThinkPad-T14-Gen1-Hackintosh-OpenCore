# Lenovo ThinkPad T14 Gen 1 (Intel) — OpenCore EFI para macOS Sonoma

EFI otimizada e documentada para **Lenovo ThinkPad T14 Gen 1** rodando **macOS Sonoma 14.7.2** com **OpenCore 1.0.8**.

> Trabalho realizado em 26/10/2026 com pesquisa spec-driven (4 sub-agentes) + validação no hardware real. Nada foi copiado cegamente — cada mudança tem justificativa documentada em `docs/`.

## Hardware

| Componente | Detalhe | Status |
|---|---|---|
| CPU | i7-10610U (Comet Lake, 4C/8T, 15W) | ✅ XCPM + CPUFriend EPP=0xC0 |
| iGPU | UHD 620 (`0x9B3E`, platform `0x3E9B0000`) | ✅ Metal 3, QuickSync H.264/HEVC |
| RAM | 40 GB | ✅ |
| Áudio | Realtek ALC257 | ✅ layout-id 86 (mic do jack funciona) |
| Wi-Fi/BT | Intel CNVi | ✅ AirportItlwm 2.3.0 + BT stack |
| Ethernet | Intel I219 | ✅ IntelMausi |
| Trackpad/TrackPoint | Synaptics RMI | ✅ VoodooRMI SMBus |
| Leitor SD | Realtek | ✅ forks Baio1977 (fix 14.4+) |
| Bateria | 50Wh | ✅ SMCBatteryManager + YogaSMC |
| Sleep/Hibernate | S3 + S4 real | ✅ hibernatemode 25, standby 5min |
| ⚠️ Mic interno | Intel SST | ❌ sem driver (usar headset) |
| ⚠️ DRM premium | iGPU-only | ❌ Netflix/Prime só via browser |

## Estrutura

```
EFI/                  ← EFI funcional ATUAL (copiar p/ partição EFI)
docs/
  ESTADO_ATUAL.md     ← auditoria inicial do hardware/config
  RESEARCH.md         ← pesquisa consolidada com fontes
  PLANO_OTIMIZACAO.md ← plano por tiers + log de aplicação
  config_dump.json    ← config original exportada
scripts/
  tier1_pmset.sh      ← ajustes de energia (Tier 1)
  tier3_pmset.sh      ← hibernação hibernatemode 25 (Tier 3)
backup_original/      ← config.plist + kexts originais (pré-otimização)
```

## Mudanças aplicadas (resumo)

**Tier 1** — pmset otimizado, `enable-hdmi20`/`agdpmod` removidos, backlight fix Sonoma (`-igfxblt`), `framebuffer-unifiedmem` 2048MB, ECEnabler 1.0.6, card reader forks Baio1977.

**Tier 2** — CPUFriend 1.3.0 + DataProvider custom (EPP 0x80→0xC0), áudio layout 97→**86** (mic do jack), con2 HDMI→DP (USB-C).

**Tier 3** — HibernationFixup 1.5.5 + RTCMemoryFixup 1.0.8 (`rtcfx_exclude=80-AB,B0-B4`), HibernateMode=NVRAM, DiscardHibernateMap, DisableRtcChecksum, ReservedMemory T490. ~~DisablePROCHOT.efi~~ removido (incompatível).

**Extras** — `igfxfw=2` removido (bug GuC), YogaSMCPane + YogaSMCNC instalados, HW accel VideoToolbox confirmado.

## Uso

1. Monte a ESP: `sudo diskutil mount diskXsY`
2. Copie `EFI/` para a raiz da ESP
3. Rode `scripts/tier1_pmset.sh` e `scripts/tier3_pmset.sh` com sudo
4. Reboot

## Avisos

- ⚠️ **`config.plist` contém SMBIOS serial (MBP16,2)** — se publicar este repo, regenere serials via [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) antes ou edite `PlatformInfo→Generic`.
- Regenerar `CPUFriendDataProvider` após update de macOS.
- SSD original (SSSTC CA5) reporta SMART degradado — recomendada troca + backup.
- Testado: boot, sleep S3→S4, áudio completo, QuickSync, Wi-Fi/BT. Pendente de teste físico: HDMI/USB-C externo.

## Créditos / Referências

- [5T33Z0/Thinkpad-T490-Hackintosh-OpenCore](https://github.com/5T33Z0/Thinkpad-T490-Hackintosh-OpenCore) — hibernação, framebuffer, ReYogaSMC
- [Baio1977/Lenovo-Thinkpad-T14](https://github.com/Baio1977/Lenovo-Thinkpad-T14) — card reader forks, T14 exato
- [acidanthera](https://github.com/acidanthera) — OpenCore, Lilu, WEG, AppleALC, CPUFriend, HBFX, RTCMemoryFixup
- [dortania](https://dortania.github.io) — guias base
