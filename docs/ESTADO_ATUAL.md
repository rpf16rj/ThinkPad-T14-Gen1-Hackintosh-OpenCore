# Estado Atual — Hackintosh Lenovo ThinkPad T14 Gen 1 (Intel)

> Auditoria realizada em **26/10/2026**, executada dentro do próprio sistema.
> Nenhuma alteração foi feita. Documento de referência antes de qualquer otimização.

---

## 1. Hardware (detectado via system_profiler / ioreg / smartctl)

| Componente | Detalhe |
|---|---|
| Modelo | Lenovo ThinkPad T14 Gen 1 (Intel) |
| CPU | Intel Core i7-10610U — Comet Lake, 4C/8T, base 1.8GHz / turbo 4.9GHz, 15W |
| iGPU | Intel UHD Graphics 620 — device-id `0x9B3E`, Metal 3, VRAM dinâmica 1536MB |
| RAM | 40 GB (provável 8GB soldado + 32GB SO-DIMM) |
| Display interno | 1920×1080 eDP @ 60Hz, 30-bit, backlight funcionando |
| Áudio | Realtek **ALC257** (`IOHDACodecVendorID = 0x10ec0257`) |
| Wi-Fi/BT | Intel CNVi (AX201-class) — drivers `ItlIwm`/`ItlIwn` ativos |
| Ethernet | Intel I219 — `en0` via IntelMausi |
| Trackpad/TrackPoint | Synaptics RMI SMBus (`TrackpointDevice`, `VoodooInputActuatorDevice` presentes no ioreg) |
| Leitor de cartão | Realtek PCIe (`RealtekPCICardReaderController` ativo) |
| Thunderbolt | Controladora presente (`AppleThunderboltNHIIntelPCI`, `pci8086,15bf`) — funcionando parcialmente |
| SSD | **SSSTC CA5-8D256-Q79 (Kioxia/Lite-On OEM) 256GB NVMe** |
| Bateria | FCC 3767 mAh, 153 ciclos, condição "Normal" |

## 2. ⚠️ ALERTA CRÍTICO — SSD em fim de vida

```
SMART overall-health self-assessment: FAILED!
Critical Warning:           0x04  (reliability degraded)
Percentage Used:            185%  ← excedeu 185% do endurance nominal
Data Units Written:         52.0 TB
Power On Hours:             7.954 h
Unsafe Shutdowns:           78
Media/Data Integrity Err:   0
Available Spare:            100%
```

O drive ainda não apresenta erros de mídia, mas **já ultrapassou em 85% o limite de escrita projetado**. A falha pode ocorrer sem aviso.

**Recomendação imediata (independente de otimização):**
1. Backup completo (Time Machine já, ou clone com Carbon Copy Cloner).
2. Planejar substituição do SSD — o slot M.2 2280 aceita qualquer NVMe moderno (ex.: WD SN770/SN580, Samsung 970 EVO Plus, Kingston KC3000).
3. Evitar `hibernatemode 3` (grava sleepimage em todo sleep) até trocar o SSD — o sistema já está corretamente em `hibernatemode 0`.

## 3. Software / Bootloader

| Item | Valor |
|---|---|
| macOS | Sonoma **14.7.2** (build 23H311) |
| Bootloader | **OpenCore 1.0.8** (REL-108-2026-09-27) |
| SMBIOS | **MacBookPro16,2** (adequado p/ Comet Lake U) |
| SIP | **Totalmente ativado** (`csr-active-config = 00000000`) |
| SecureBootModel | Disabled · Vault: Optional |
| Partição EFI ativa | `/Volumes/EFI` = `disk0s3` (999MB, "Microsoft Basic Data") — *atenção: existe outra EFI em `disk0s1` (209MB); confirmar qual o BIOS realmente boota* |
| boot-args | `-v debug=0x100 keepsyms=1 itlwm_he=1` |

### Drivers UEFI
`AudioDxe` (boot chime), `HfsPlus`, `OpenCanopy`, `OpenRuntime`, `ResetNvramEntry`, `ToggleSipEntry`

### ACPI
- `SSDT-T14Gen1.aml` (all-in-one) + renames: `_OSI→XOSI`, `GPRW→XPRW` (fix wake instantâneo), `PNLF→XNLF`

## 4. Kexts carregados (kextstat — versões reais em uso)

| Kext | Versão | Função |
|---|---|---|
| Lilu | 1.7.2 | Engine de patch (base de tudo) |
| VirtualSMC | 1.3.8 | Emulador SMC |
| SMCProcessor / SMCSuperIO / SMCBatteryManager / SMCLightSensor | 1.3.8 | Sensores + bateria |
| WhateverGreen | 1.7.1 | Patches de GPU |
| AppleALC | 1.9.8 | Áudio (layout-id **97**) |
| ECEnabler | 1.0.5 | Leitura EC >8-bit (bateria) |
| BlueToolFixup | 2.7.2 | BT no Monterey+ |
| IntelBTPatcher + IntelBluetoothFirmware | 2.5.0 | Bluetooth Intel |
| AirportItlwm | 2.3.0 | Wi-Fi Intel (build Sonoma; EFI também tem itlwm p/ Sequoia e AirportItlwm-Tahoe v2.4.0) |
| NVMeFix | 1.1.3 | Power management do NVMe |
| RestrictEvents | 1.1.6 | Patches de restrições |
| BrightnessKeys | 1.0.3 | Teclas de brilho |
| YogaSMC | 1.5.3 | Integração ThinkPad (fan, hotkeys, conservation mode) |
| VoodooPS2Controller (+Keyboard/Trackpad/Mouse) | 2.3.7 | PS/2 fallback |
| VoodooRMI + RMISMBus + VoodooInput | 1.4.3 / 1.0 / 1.1.7 | Trackpad SMBus nativo |
| VoodooSMBus | 3.0 | SMBus |
| IntelMausi | 1.0.8 | Ethernet |
| RealtekCardReader + Friend | 0.9.7 / 1.0.4 | Leitor SD |
| USBPorts | — | Mapa de USB (data-only) ✅ presente |

### Kexts ausentes (gaps identificados)
- ❌ **CPUFriend + CPUFriendDataProvider** — power management roda com vetor padrão do MBP16,2; gap principal de eficiência energética.
- ❌ **FeatureUnlock** — necessário para Sidecar/Universal Control/AirPlay-to-Mac em SMBIOS patchável.
- ❌ **HibernationFixup** — só necessário se ativar `hibernatemode 3` (não recomendado agora por causa do SSD).

## 5. DeviceProperties (iGPU `PciRoot(0x0)/Pci(0x2,0x0)`)

```
AAPL,ig-platform-id            = 00009B3E   (0x3E9B0000 — Coffee Lake laptop)
device-id                      = 9B3E0000
framebuffer-patch-enable       = 1
framebuffer-con1/con2          = tipo HDMI (0x0800), busid 01/02
enable-hdmi20                  = 1
enable-hdmi-dividers-fix       = 1
force-online + force-online-fb = 1
complete-modeset (+fb)         = 1
igfxfw                         = 2   (firmware GUC)
rps-control                    = 1   (RPS p/ melhor DVFS na iGPU)
agdpmod                        = pikera
AAPL,GfxYTile                  = 1
```

Obs.: framebuffer `IOFBMemorySize` reporta 512MB e VRAM dinâmica 1536MB — não há patch `framebuffer-unifiedmem` (aumento de VRAM) aplicado.

## 6. Áudio (`PciRoot(0x0)/Pci(0x1F,0x3)`)

- `layout-id = 97`, `alc-verbs = 1`, speakers + mic interno funcionando.
- UEFI Audio habilitado (boot chime via AudioDxe).

## 7. Energia / térmico (pmset + sysctl)

```
XCPM: ativo (machdep.xcpm.mode=1)
Faixa de frequência XCPM: 0.4 – 4.9 GHz (plimits 4–49 × 100MHz)

pmset:  sleep=1min  displaysleep=0(?)  disksleep=10  standby=1
        hibernatemode=0  powernap=0  proximitywake=0
        tcpkeepalive=1  lidwake=1  lowpowermode=0
```

Observações:
- `tcpkeepalive=1` causa wakes de rede (logs mostram `systemWokenByWiFi` — wakes por Wi-Fi acontecem).
- `sleep=1` é muito agressivo; `displaysleep=0` = tela nunca apaga sozinha (consumo).
- Sem CPUFriend → idle floor provavelmente ~1.3GHz em vez de ~0.8–1.0GHz (mais consumo em repouso).

## 8. Quirks relevantes (config.plist)

Ativos: `AppleXcpmCfgLock`, `CustomSMBIOSGuid`, `DisableIoMapper` + `DisableIoMapperMapping` (VT-d off), `PanicNoKextDump`, `PowerTimeoutKernelPanic`, `DisableLinkeditJettison`, `EnableVectorAcceleration`, `ReleaseUsbOwnership`, `RequestBootVarRouting`, `ProvideCustomSlide`, `DevirtualiseMmio`, `RebuildAppleMemoryMap`, `SyncRuntimePermissions`.

Inativos/notáveis: `XhciPortLimit=false` ✅ (mapa USB existe), `ProvideCurrentCpuInfo=false` (OK p/ CML), `ForceSecureBootScheme=false`.

## 9. Resumo dos gaps e oportunidades

| Área | Situação | Oportunidade |
|---|---|---|
| SSD | 🔴 SMART FAILING (185% usado) | Backup + troca — prioridade máxima |
| CPU PM | 🟡 Sem CPUFriend | Gerar CPUFriendDataProvider p/ idle mais baixo |
| Sleep/wake | 🟡 tcpkeepalive=1, wakes por Wi-Fi | Desligar tcpkeepalive na bateria |
| GPU | 🟢 funcional | Avaliar `framebuffer-unifiedmem`, `igfxonln=1`, backlight smooth |
| Áudio | 🟢 funcional (layout 97) | Validar se layout é o ideal p/ ALC257 no T14 |
| Sidecar/Continuity | 🟡 sem FeatureUnlock | Adicionar se quiser Sidecar/UC |
| Kexts | 🟡 versões de meados de 2025 | Conferir updates (ver RESEARCH.md) |

---
*Gerado por Devin — auditoria pré-otimização. Nada foi modificado.*
