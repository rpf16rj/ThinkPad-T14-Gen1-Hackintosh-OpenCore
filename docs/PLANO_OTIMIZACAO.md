# PLANO DE OTIMIZAÇÃO — T14 Gen 1 Hackintosh (Sonoma 14.7.2)

> Status: **PROPOSTA — nada aplicado ainda.** Cada item lista risco, esforço e rollback.
> Pré-requisito absoluto: **ver §0 — o SSD está morrendo.**

---

## §0. PRÉ-REQUISITO CRÍTICO (antes de qualquer tweak)

| # | Ação | Status |
|---|---|---|
| 0.1 | **Backup completo agora** (Time Machine ou clone CCC p/ externo) | ⚠️ **PENDENTE — faça hoje** |
| 0.2 | USB de boot com EFI | ✅ **FEITO 26/10** — pendrive `/dev/disk3`, partição EFI, 286 arquivos verificados |
| 0.3 | Planejar troca do SSD (M.2 2280 NVMe) | ⏳ pendente |

## ✅ TIER 1 — LOG DE APLICAÇÃO (26/10/2026)

**Aplicado na EFI (`disk0s3`):**
- [x] config.plist iGPU: removido `enable-hdmi20` (morto no 11+) e `agdpmod=pikera` (no-op)
- [x] config.plist iGPU: adicionado `enable-backlight-registers-alternative-fix=1` (fix backlight Sonoma / tela escura pós-wake)
- [x] config.plist iGPU: adicionado `framebuffer-unifiedmem=00000080` (VRAM → 2048MB)
- [x] ECEnabler 1.0.5 → **1.0.6**
- [x] RealtekCardReader 0.9.7 → **0.9.8 (fork Baio1977)**
- [x] RealtekCardReaderFriend 1.0.4 → **1.0.6 (fork Baio1977)** — fix do bug 14.4+
- [x] pmset — ✅ rodou: `displaysleep 5`, `sleep 15`, `tcpkeepalive 0`, `standby 0` (verificado após reboot)
- plutil -lint: OK · diff vs original confirmado · rollback = restaurar de `efi_snapshot/` ou bootar pelo USB

## ✅ TIER 2 — LOG DE APLICAÇÃO (26/10/2026)

**Aplicado na EFI (`disk0s3`):**
- [x] **CPUFriend.kext 1.3.0** + **CPUFriendDataProvider.kext** (custom, gerado via ResourceConverter):
  - Board: Mac-5F9802EFE386AA28 · LFM mantido 0x08 (800MHz, já ótimo) · **EPP 0x80→0xC0** (máx economia) · PerfBias 0x07
  - Inseridos na ordem correta: após YogaSMC, antes de WhateverGreen
  - ⚠️ Regenerar DataProvider após cada update do macOS (vetor muda por versão)
- [x] **boot-args += `alcid=86`** — teste do layout ALC257 (86 = recriado no AppleALC 1.9.8, mic do jack validado)
- [x] **framebuffer-con2-type: HDMI→DP** (`00080000`→`00040000`) — con2=port6/DDI-C=USB-C DP; con1=port5/DDI-B permanece HDMI p/ porta física
- [ ] ReYogaSMC — **pulado**: requer Xcode completo p/ compilar (só CLT instalado). YogaSMC 1.5.3 funciona.

**Após reboot, verificar:**
- [x] `kextstat | grep -i cpufriend` → ✅ CPUFriend 1.3.0 + provider carregados, EPP=0xC0 ativo
- [x] Áudio: speakers ✅ + fone ✅ + **mic do jack TRRS ✅** — alcid=86 validado pelo usuário
- [ ] HDMI físico: vídeo+áudio · USB-C→monitor/adaptador: vídeo — ⏳ usuário testará depois
- [x] Sleep/wake — ✅ confirmado pelo usuário
- [x] Consumo idle / bateria — EPP=0xC0 ativo

**Fix permanente aplicado (26/10):** `alcid=86` removido dos boot-args; `layout-id=86` gravado no DeviceProperties (Pci(0x1F,0x3)). Próximo boot mantém o layout correto sem flag temporária.

**Rollback rápido:** remover `alcid=86` dos boot-args (NVRAM no config) ou restaurar config do `efi_snapshot/`; USB de boot intacto com EFI original+Tier1.

## ✅ TIER 3 — LOG DE APLICAÇÃO (26/10/2026) — portado do EFI 5T33Z0/T490

**Aplicado na EFI (`disk0s3`):**
- [x] **HibernationFixup.kext 1.5.5** (build do release T490 OC_109.6)
- [x] **RTCMemoryFixup.kext 1.0.8** + boot-arg `rtcfx_exclude=80-AB,B0-B4` (ranges do T490)
- [x] ~~**DisablePROCHOT.efi**~~ → ❌ **REVERTIDO**: entry point retorna `EFI_NOT_FOUND` no T14 (mecanismo BD-PROCHOT do T490 incompatível) → halt no boot com HaltLevel=0x80000000. Removido do config e do disco. Fix de throttle fica pendente (alternativa: YogaSMC/DYTC).
- [x] `Misc→Boot→HibernateMode = NVRAM`, `HibernateSkipsPicker = True`
- [x] `Booter→Quirks→DiscardHibernateMap = True` (fix tela preta no 2º hibernate)
- [x] `Kernel→Quirks→DisableRtcChecksum = True` (fix panic RTC checksum 0x1F no wake)
- [x] `UEFI→ReservedMemory` += {Address 569344, Size 4096, RuntimeCode} — fix tela preta wake p/ ThinkPad
- [x] `UEFI→Drivers` += DisablePROCHOT.efi
- [ ] pmset hibernação — **aguardando `sudo ./tier3_pmset.sh`** (hibernatemode 25 + standby 1 + delays 900)

**Decisões de design:**
- `RebuildAppleMemoryMap` mantido **True** (nosso valor funcional; T490 usa False — rever se hibernate falhar)
- Sem `hbfx-ahbm` (5T33Z0 também não usa; o standby delay controla a transição S3→S4)
- **ReYogaSMC não instalado** — conflita com CPUFriend (5T33Z0 mediu -800pts multicore juntos); também exigiria SSDTs-THINK/ECRW custom do T490 + app companion. YogaSMC 1.5.3 segue.

**Após reboot + pmset, verificar:**
- [x] `kextstat | grep -iE "hibern|rtc"` → ✅ HBFX 1.5.5 + RTCMemoryFixup 1.0.8 carregados
- [x] Sleep normal continua ok
- [x] **Hibernação funcional**: log confirma `Wake from Standby, hibmode=25` — 40min desligado, 0% de bateria consumida
- [x] Sem RTC checksum / tela preta fatal
- ⚠️ **Resume lento (~5min, tela azul+cursor)** no 1º teste — `rd=174ms` (imagem ok); suspeito: re-init de IGPU/TB ou leitura no SSD degradado. Re-testar; se persistir, avaliar `hbfx-patch-pci=` ou voltar p/ `hibernatemode 3`
- ⚠️ Sleepimage ~40GB (tamanho da RAM) gravado por ciclo de hibernação — desgaste extra no SSD já degradado
- ❌ DisablePROCHOT.efi removido (incompatível) — fix de throttle pendente

## ✅ EXTRAS (26/10/2026)
- [x] **USB EFI sincronizado** com config atual (CPUFriend, hibernação, layout 86, unifiedmem)
- [x] **YogaSMCPane** instalado (`~/Library/PreferencePanes`) + **YogaSMCNC.app** (`/Applications`) — charge thresholds, DYTC, fan, hotkeys
- [x] **`igfxfw=2` removido** do config (GuC tem bug de freq travada; efeito no próximo reboot)
- [x] HW accel verificado: **VideoToolbox H.264/HEVC decode+encode ativos** (QuickSync OK)
- [ ] Firefox HW decode — instruções entregues ao usuário (about:config + enhanced-h264ify)
- [ ] BIOS tweaks — instruções entregues (desligar WWAN/fingerprint/SGX/TPM)
- [ ] YogaSMCPane: usuário configura charge threshold (75/80) e modo DYTC

---

## Tier 1 — Aplicar primeiro (risco zero/baixo, ganho real imediato)

### 1.1 pmset — maior ganho de bateria da lista ⭐
```bash
sudo pmset -b sleep 15 displaysleep 5 tcpkeepalive 0
sudo pmset -c sleep 0 displaysleep 15 tcpkeepalive 1
sudo pmset -a autopoweroff 0 standby 0 powernap 0 proximitywake 0 hibernatemode 0
```
- `displaysleep 0` atual = tela nunca desliga → dreno #1.
- `tcpkeepalive 0` na bateria corta os wakes por Wi-Fi vistos nos logs.
- Rollback: `sudo pmset -a restoredefaults`? (ou redefinir manualmente).
- Risco: nenhum.

### 1.2 config.plist — limpeza de DeviceProperties iGPU
- **Remover** `enable-hdmi20` (código morto no macOS 11+)
- **Remover** `agdpmod=pikera` (no-op sem dGPU)
- **Adicionar** `enable-backlight-registers-alternative-fix = 01000000` (fix backlight Sonoma, previne tela escura pós-wake)
- **Adicionar** `framebuffer-unifiedmem = 00000080` (VRAM 1536→2048MB; opcional, ganho leve)
- Risco: baixo. Rollback: restaurar `Config.plist.original` do snapshot.
- Validação: `ocvalidate` + boot normal + teste de sleep/wake + brilho.

### 1.3 Card reader — consertar o quebrado
- `RealtekCardReaderFriend 1.0.4` está **quebrado no macOS 14.4+** (issue #12 upstream). Provável erro "error loading card reader information" no System Report.
- Opções: (a) trocar ambos por forks Baio1977, (b) desabilitar os 2 kexts se o leitor não é usado (remove fonte de panics raros).
- Risco: baixo.

### 1.4 ECEnabler 1.0.5 → 1.0.6 — update trivial.

### 1.5 macOS-side (não-EFI)
- Acessibilidade → Reduzir Transparência / Reduzir Movimento; wallpaper estático.
- Instalar **YogaSMCPane**; setar charge threshold 75/80 se usa dockado (prolonga vida da bateria).
- BIOS: desligar WWAN/fingerprint/SGX/TPM se não usa (economia + menos wake issues).

---

## Tier 2 — Médio valor/esforço

### 2.1 Testar layout de áudio 86 (mic do jack)
- Boot-arg temporário `alcid=86` → testar speakers/fone/mic do jack. Se melhor que 97, persistir no DP. Se pior, `alcid=11`.
- **Verificar antes se o "Internal Microphone" atual é real** (tap test). Se fantasma → esperado, SST não tem driver.

### 2.2 CPUFriend (opcional, ganho modesto)
- Gerar `CPUFriendDataProvider` via CPUFriendFriend: LFM manter 0x08, **EPP=0xC0**.
- ⚠️ Regenerar após cada update macOS. Ganho: ~0.5-1h bateria em uso leve.
- Rollback: deletar 2 kexts.

### 2.3 iGPU — refinamentos
- Mapear conectores via Hackintool: só o HDMI físico como `type=0008`; USB-C volta p/ DP.
- Testar boot **sem** `igfxfw=2` (bug de freq travada documentado) — comparar GFX freq com Intel Power Gadget.
- Opcional: `enable-backlight-smoother=1`.

### 2.4 YogaSMC → ReYogaSMC
- Fork mantido p/ Sonoma+. Requer compilar o kext. Só se quiser suporte continuado (DYTC, fan control, thresholds).

---

## Tier 3 — Alto esforço/risco — avaliar se vale

### 3.1 Hibernação real (hibernatemode 3/25)
- HibernationFixup + RTCMemoryFixup + ReservedMemory + `HibernateMode=NVRAM`.
- ⚠️ Esperar a troca do SSD (sleepimage grava GBs por ciclo).
- Referência: 5T33Z0/T490 (mesmo platform, funcionando).

### 3.2 Portar melhorias do EFI 5T33Z0/T490
- Disable BDPROCHOT (fix throttle pós-wake), patch framebuffer otimizado HDMI, clamshell em AC, `_OSI` limpo.

### 3.3 ❌ NÃO FAZER
- Undervolting via setup_var/Smokeless_UMAF → risco de brick, ganho irrisório em 15W.
- CodecCommander → abandonado, quebra no 12.3+.
- "Atualizar" IntelBT p/ 2.4.0 oficial → nosso 2.5.0 CI é mais novo.
- RestrictEvents 1.1.7 nightly → fix pré-AVX, inútil no Comet Lake.
- AirportItlwm-Tahoe no Sonoma → MinKernel já isola ✅, manter como está.

---

## Ordem de execução sugerida

```
0. Backup + USB EFI fallback                     [hoje, antes de tudo]
1. pmset (1.1)                                    [5 min, testável na hora]
2. Limpeza DP iGPU (1.2) + reboot test            [~15 min]
3. Card reader fix (1.3) + ECEnabler (1.4)        [~15 min]
4. Verificação mic interno + teste alcid=86 (2.1) [~20 min]
5. YogaSMCPane + BIOS tweaks (1.5)                [~15 min]
6. CPUFriend (2.2) — opcional                     [~30 min]
7. Conector HDMI mapping + igfxfw test (2.3)      [~30 min]
8. Troca do SSD quando chegar + reavaliar hibernação
```

## Checklist de validação pós-mudança (cada etapa)
- [ ] Boot limpo sem verbose errors novos
- [ ] Sleep → wake → sem tela preta (testar 2×)
- [ ] Brilho ajustável, transições ok
- [ ] Áudio speakers + jack + HDMI
- [ ] Wi-Fi/BT funcionais
- [ ] `pmset -g log | grep -i wake` sem wake-loop
- [ ] Temperatura/ruído ocioso (Stats/iStat)

---
*Pesquisa completa em RESEARCH.md · Estado documentado em ESTADO_ATUAL.md · EFI original em efi_snapshot/*

## ✅ TESTE DE DISPLAY EXTERNO (26/10/2026)

- **HDMI nativo (con1/port5)**: imagem com tom rosado (monitor Acer VG240Y V) — negociação **YCbCr** mal resolvida pelo EDID. Override de EDID forçando RGB não carregou (macOS ignorou `/Library/Displays/.../Overrides`).
- **USB-C → HDMI/DP (con2/port6, DP nativo)**: ✅ **cores perfeitas** — sinal RGB puro, sem workaround.
- **Workaround recomendado**: usar adaptador USB-C→HDMI/DP para monitores. Alternativa futura: patch `framebuffer-con1-flags` ou SwitchResX.
- Override removível: `sudo rm -rf /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-472` (instalado mas sem efeito — arquivo em `display_overrides/` mantido no repo p/ referência)

## ✅ BUG-HUNT SPEC-DRIVEN (27/10/2026)

**Aplicado na EFI:**
- [x] `pci-aspm-default=0` em `PciRoot(0x0)/Pci(0x14,0x3)` (CNVW/AX201) — fix Wi-Fi morto pós-sleep (ASPM L1 reativado no wake; itlwm issues #746/#519/#236)
- [x] **RestrictEvents.kext desabilitado** — no-op sem `revpatch=` boot-arg
- [x] **SMCLightSensor.kext desabilitado** — sem hardware ALS no T14
- [x] **YogaSMC.kext desabilitado (teste)** — suspeito #1 do spike de CPU ao plugar carregador (contenção de EC c/ SMCBatteryManager+ECEnabler; issue ECEnabler#24, YogaSMC#211/#44) + conflito documentado com CPUFriend. YogaSMCNC/Pane deixam de funcionar; thresholds de bateria ficam no BIOS.

**Diagnóstico pendente (usuário):** plugar carregador após reboot → se CPU normal = YogaSMC era o culpado. Se spike persistir → próximo teste é `-eceoff`/desabilitar ECEnabler (issue #24 idêntica).

**Confirmado OK pela pesquisa:** AppleALC 1.9.8+layout86, WEG 1.7.1+rps-control/unifiedmem, NVMeFix, IntelMausi, VoodooPS2+RMI stack, AirportItlwm build 14.4, rtcfx ranges, HibernateMode=NVRAM. `RebuildAppleMemoryMap=True` mantido (diverge do T490 mas hibernação funciona).

## ✅ BUG-HUNT pt.2 (27/10) — GPU/storage
- [x] **`rps-control` removido** — causa documentada de iGPU presa em freq máxima → calor (WEG 1.4.2 o desabilitou por padrão)
- [x] **RealtekCardReader + Friend desabilitados** — timeout de 180s em power-state callback (issue #55) + panics no 14.7.2 (#58) = provável causa do resume de ~5min. Re-ativar se usar leitor SD, com `-rtsxnopm`
- Confirmado: SSD SSSTC CA5 (não é PM981 problemático), RestrictEvents/SMCLightSensor corretamente desabilitados, force-online/unifiedmem mantidos

## ✅ VALIDAÇÃO FINAL (27/10) — todos os bugs corrigidos
- [x] Wi-Fi pós-sleep: **resolvido** (pci-aspm-default=0 + portas internas USB corretas)
- [x] CPU spike ao plugar AC: **resolvido** (YogaSMC era o culpado — validado)
- [x] Resume ~5min: **resolvido** (card reader off + rps-control removido → resume rápido)
- [x] Bluetooth morto + webcam: **resolvido** (USBPorts model MBP15,4→16,2)
- [x] FeatureUnlock 1.1.8 ativo
- Pendente: ReYogaSMC (thresholds/DYTC) como teste futuro; backup do sistema
