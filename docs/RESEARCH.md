# RESEARCH — Otimização Hackintosh T14 Gen 1 (i7-10610U / UHD 620 / Sonoma 14.7.2)

> Pesquisa consolidada de 4 sub-agentes (web) + verificação local. 26/10/2026.
> Fontes citadas ao final de cada seção.

---

## A. GPU / Vídeo (UHD 620, ig-platform 0x3E9B0000)

### A.1 Platform ID — ✅ já correto
`0x3E9B0000` é o valor recomendado para UHD 620 em laptops Comet Lake (dortania/OC-Little-Translated). `0x3EA50009` é alternativa válida (UHD 630) apenas se houvesse problemas de porta. `device-id 0x9B3E` (spoof CFL) é a prática padrão.

### A.2 Propriedades atuais — análise item a item

| Propriedade | Status | Veredito |
|---|---|---|
| `framebuffer-patch-enable=1` | ✅ presente | Necessário p/ patches de conector — correto |
| `force-online=1` (`igfxonln`) | ✅ | Necessário desde 10.15.4 p/ HDMI |
| `complete-modeset=1` (`igfxfcms`) | ✅ | Fix tela preta HDMI após wake |
| `enable-hdmi-dividers-fix=1` | ✅ | Fix loop em pixel clocks altos (CFL driver) |
| `rps-control=1` (`igfxrpsc`) | ✅ | **Benéfico** — melhora scaling de freq da iGPU |
| `igfxfw=2` | ⚠️ | GuC firmware tem bug documentado: GPU pode travar em freq máxima até sleep/reboot. Testar sem. |
| `agdpmod=pikera` | ⚪ | No-op sem dGPU — inofensivo, pode remover |
| `enable-hdmi20=1` | ❌ | **Código morto no macOS 11+** (WEG README) — remover |
| `AAPL,GfxYTile=1` | ✅ | Fix glitches HiDPI |
| `hda-gfx=onboard-1` | ✅ confirmado no IOReg (IGPU + HDEF) | Áudio HDMI/DP funcionando |

### A.3 Ausentes / recomendados

1. **`enable-backlight-registers-alternative-fix=1` (`-igfxblt`)** — IMPORTANTE no Sonoma: desde 13.4 a Apple inlineou R/W de registradores no driver CFL → o fix clássico de backlight e o smoother pararam de funcionar silenciosamente; pode causar "tela escura por ~3min" após boot/wake. Requer WEG ≥1.6.6 (temos 1.7.1 ✅).
   - Fonte: github.com/acidanthera/WhateverGreen PR #113/#116
2. **`enable-backlight-smoother=1` (`-igfxbls`)** — transições suaves de brilho; só funciona com o item acima.
3. **`framebuffer-unifiedmem=00000080`** → VRAM reportada 2048MB (vs 1536MB atual). Seguro; benefício real em 4K/multimonitor, cosmético em 1080p. ⚠️ NUNCA combinar com `framebuffer-stolenmem`.
4. **Conectores:** atualmente con1 E con2 estão como HDMI (`type=0008`). Melhor prática: via Hackintool identificar qual índice é o HDMI físico e manter só ele como HDMI; deixar o USB-C/TB3 como DP (`0004`) para não quebrar monitores DP puros.
5. `agdpmod=pikera` — remover (no-op).
6. Situacional: `-igfxmlr` (link rate fix) e `-igfxmpc` (pixel clock override — fix de tela interna preta em CML no Sonoma).

### A.4 Limites físicos
- HDMI do T14 Gen1 é **1.4b → máx 4K@24-30Hz**. 4K@60 só via USB-C/TB3 (DP 1.2) — confirmado funcionando em EFIs T14.
- DVMT: BIOS do T14 não expõe DVMT Pre-Allocated; o atual já é suficiente (boot com aceleração total). Não tentar `setup_var` (risco de brick).

### A.5 DRM — limitação permanente
Sem dGPU, iGPU-only no macOS 11+: **Apple TV+ ❌, iTunes filmes ❌, Netflix/Prime no Safari ❌**. Funciona: Netflix/Prime/Disney+ em Chrome/Firefox via Widevine L3 (~720p-1080p). Não existe fix — Shiki/shikigva foi removido do WEG.
   - Fonte: WhateverGreen FAQ.Chart

### A.6 macOS-side (grátis)
- Acessibilidade → **Reduzir Transparência + Reduzir Movimento**
- Wallpaper estático (aerial/screensavers animados pesam na iGPU)
- Evitar Stage Manager e resoluções scaled pesadas em monitores externos

---

## B. Áudio (ALC257, layout-id 97, AppleALC 1.9.8)

### B.1 Layouts disponíveis p/ ALC257 (8 no total)
| ID | Alvo | Nota |
|---|---|---|
| 11 | T480 (MacPeet) | Auto-switch speaker↔fone OK; mic do jack funciona em testes T14 |
| 18 | Legion Y540 | Não-ThinkPad |
| **86** | T480 (armenio) | **Melhor mantido** — recriado do zero no AppleALC 1.9.8 (PR #954) com roteamento validado contra spec Intel HDA |
| 96 | L390 | Reportado "nada funciona" no T14 |
| **97** | **T490** | O atual — speakers OK, mas num teste real em T14 o mic do jack NÃO funcionou |
| 99/100/101 | Ideapads | Irrelevante |

### B.2 ⚠️ Mic interno — provavelmente impossível
O array de mic do T14 Gen1 usa **Intel SST (DSP)**, não o codec ALC257 — não existe driver macOS p/ SST. 3 fontes independentes confirmam. O "Built-in Microphone" que aparece pode ser **fantasma** (entrada de layout que não capta nada).
→ **Ação de verificação manual:** selecionar Internal Microphone, desconectar fones, dar tap no grill do mic olhando o medidor de input.
→ Mic do jack TRRS funciona (layouts 11/86). Alternativa experimental: LatSOFAudio (driver SOF/SST — arriscado).
- Fontes: wjxwang T14 EFI, osxlatitude T14 thread, dortania macos-limits

### B.3 Ferramentas auxiliares
- `alc-verbs=1` já presente ✅ — pré-requisito p/ **ALCPlugFix-Swift** (daemon que reenvia verbs em plug/unplug/wake) caso jack-sense falhe.
- **CodecCommander: NÃO instalar** — abandonado, quebra no 12.3+ sem hack de plist; WakeConfigData do AppleALC moderno já cobre pós-sleep.
- Verbs da init Lenovo (amp Class-D 2W, JD1 jack detect) documentados no coreboot T480 — utilizáveis via `alc-verb` se volume baixo.

### B.4 Miscelâneo
- `alcid=` boot-arg sobrescreve tudo → usar p/ testar layouts (ex.: `alcid=86`) sem editar DP.
- AudioDxe/PlayChime: custo zero em runtime; **mas quebra áudio do Windows se bootado pelo picker do OC**. Cosmético — manter ou remover por gosto.
- Áudio HDMI: confirmado funcionando (hda-gfx presente, conectores HDMI-typed, AppleALC).

---

## C. CPU / Energia / Térmico

### C.1 CPUFriend — situação real (mais sutil que o esperado)
- O vetor de frequência do **MacBookPro16,2 já vem com LFM=800MHz** — o ganho clássico "1.3→0.8GHz idle" NÃO se aplica.
- O único knob útil é **EPP (Energy Performance Preference)**: estoque ~0x90; **0xC0** = máx economia (escala mais devagar sob carga). Ganho modesto (~0.5-1h em uso leve).
- Veredito acidanthera: "CPUFriend provavelmente NÃO é necessário". Opcional. Se usar: gerar via **CPUFriendFriend** (corpnewt), LFM 0x08, EPP 0xC0. ⚠️ Regenerar após cada update de macOS (vetor velho → panic de wake).
- ✅ Verificado: `X86PlatformPlugin` attached, XCPM ativo, faixa 0.4-4.9GHz, HWP engatado automaticamente (SMBIOS compatível).

### C.2 pmset — maiores ganhos reais, custo zero

| Setting | Atual | Recomendado | Impacto |
|---|---|---|---|
| `displaysleep` | **0 (nunca apaga)** | `-b 5` / `-c 15` | 🔴 **Maior dreno de bateria do sistema** |
| `sleep` | 1 | `-b 15` / `-c 0` | sleep em 1min é irritante/debug leftover |
| `tcpkeepalive` | 1 | `-b 0` | Causa wakes por Wi-Fi (confirmado nos logs: `systemWokenByWiFi`, issue itlwm #781) |
| `standby` | 1 | 0 | Inerte com hibernatemode 0, mas alinhar c/ dortania |
| `powernap` | 0 | 0 | ✅ |
| `proximitywake` | 0 | 0 | ✅ |
| `hibernatemode` | 0 | 0 | ✅ manter (e ideal p/ SSD degradado — ver ALERTA) |
| `autopoweroff` | — | 0 | dortania |

Bloco sugerido:
```bash
sudo pmset -b sleep 15 displaysleep 5 tcpkeepalive 0
sudo pmset -c sleep 0 displaysleep 15 tcpkeepalive 1
sudo pmset -a autopoweroff 0 standby 0 powernap 0 proximitywake 0 hibernatemode 0
```

### C.3 YogaSMC / térmico
- **YogaSMCPane** (prefpane): charge thresholds (`setCMstart/setCMstop` — ex. 75/80 se vive na tomada), fan RPM, conservation mode. Recomendado instalar.
- ⚠️ YogaSMC 1.5.3 está **abandonado** (2022). Fork mantido: **ReYogaSMC** (hoaug-tran) — usado pelo EFI 5T33Z0/T490. Requer compilar. Prioridade média.
- Turbo Boost off na bateria: Turbo Boost Switcher ou VoltageShift (PL1/PL2 — funciona mesmo com voltagem travada). Ganho térmico real em carga sustentada. Requer SIP parcial p/ kext unsigned.
- **Undervolting: pular** — Overclocking Lock travado no BIOS; unlock via setup_var risco de brick, ganho ~nulo em 15W.

### C.4 Hibernação (S4) — alto esforço, opcional
Para hibernatemode 3/25 funcionar direito no OC: HibernationFixup.kext + RTCMemoryFixup/rtc-blacklist + `HibernateMode=NVRAM` + ReservedMemory + talvez DiscardHibernateMap. Referência funcional: 5T33Z0/T490. **Não recomendado agora** — com o SSD em 185% de desgaste, evitar writes de sleepimage.

---

## D. Kexts / EFI de referência / Pontos conhecidos

### D.1 Tabela de versões (instalado vs. último oficial)

| Componente | Instalado | Último | Ação |
|---|---|---|---|
| OpenCore | 1.0.8 | 1.0.8 | ✅ atual |
| Lilu | 1.7.2 | 1.7.2 | ✅ |
| VirtualSMC +plugins | 1.3.8 | 1.3.8 | ✅ |
| WhateverGreen | 1.7.1 | 1.7.1 | ✅ |
| AppleALC | 1.9.8 | 1.9.8 | ✅ (1.9.8 recriou layout 86 p/ ALC257) |
| AirportItlwm Sonoma | 2.3.0 | 2.3.0 | ✅ (verificar se é build **Sonoma14.4**) |
| IntelBT* | 2.5.0 | 2.4.0 oficial / CI mais novo | ✅ manter (CI > oficial) |
| BlueToolFixup | 2.7.2 | 2.7.2 | ✅ (NVRAM vars BT verificadas ✅) |
| NVMeFix | 1.1.3 | 1.1.3 | ✅ |
| RestrictEvents | 1.1.6 | 1.1.6 | ✅ (1.1.7 nightly é irrelevante — fix pré-AVX) |
| BrightnessKeys | 1.0.3 | 1.0.3 | ✅ |
| **ECEnabler** | **1.0.5** | **1.0.6** | 🟡 update menor (só MaxKernel Tahoe) |
| YogaSMC | 1.5.3 | abandonado | 🟡 avaliar ReYogaSMC |
| VoodooPS2 | 2.3.7 | 2.3.7 | ✅ |
| VoodooRMI stack | 1.4.3 | 1.4.3 | ✅ |
| IntelMausi | 1.0.8 | 1.0.8 | ✅ |
| **RealtekCardReaderFriend** | **1.0.4** | ⚠️ **quebrado no 14.4+** | 🔴 substituir por fork Baio1977 ou desabilitar |
| RealtekCardReader | 0.9.7 | upstream morto | 🟡 fork Baio1977 mantido |

### D.2 EFIs de referência (mesmo hardware)
1. **5T33Z0/Thinkpad-T490-Hackintosh-OpenCore** — 204★, mantido até jun/2026, mesmo platform (Comet Lake U, UHD620, ALC257-family). Contém: hibernação 3/25 funcional, patch de framebuffer otimizado p/ HDMI, clamshell em AC, **disable BDPROCHOT** (fix de throttle pós-wake), ReYogaSMC.
2. **Baio1977/Lenovo-Thinkpad-T14** — T14 Gen1 exato, HDMI vídeo+áudio verificados, forks mantidos do card reader, ioreg/USB map do próprio chassis.
3. maxpicelli T14 Gen1, wjxwang T14 (notas detalhadas de upgrade p/ Sequoia) — referência secundária.

### D.3 Pontos conhecidos da comunidade T14
- **Mic interno impossível** (SST) — ver B.2
- **PM981/PM981a não é compatível** (nosso SSD é SSSTC CA5 — OK, mas está morrendo)
- Sleep/wake: mapa USB com portas internas BT marcadas `255`, GPRW patch (temos), tcpkeepalive 0
- iServices: AirportItlwm como NIC primária pode quebrar iMessage/FaceTime (en0=Ethernet ajuda)
- Card reader: panics raros + Friend quebrado no 14.4+ → atualizar ou desabilitar
- BT: vars NVRAM necessárias desde BrcmPatchRAM 2.7.0 — ✅ presentes no nosso sistema

---

## E. Verificações locais pós-pesquisa

| Item | Resultado |
|---|---|
| `framebuffer-patch-enable` | ✅ presente |
| `hda-gfx=onboard-1` IGPU+HDEF | ✅ presente no IOReg |
| `X86PlatformPlugin` / XCPM | ✅ ativo, 0.4–4.9GHz |
| BT NVRAM vars | ✅ presentes |
| `unifiedmem`/`stolenmem` | ausentes (OK — DVMT suficiente) |
| SSD SMART | 🔴 FAILED — 185% usado (ver ESTADO_ATUAL.md §2) |

## Fontes principais
- acidanthera/WhateverGreen (README, FAQ.Chart, PR #113/#116, Manual)
- acidanthera/AppleALC (Resources/ALC257, PR #954)
- acidanthera/CPUFriend Instructions; corpnewt/CPUFriendFriend
- acidanthera/HibernationFixup
- dortania OpenCore Post-Install (sleep, pm, gpu-patching, audio, macos-limits)
- 5T33Z0/OC-Little-Translated; 5T33Z0/Thinkpad-T490
- Baio1977/Lenovo-Thinkpad-T14; wjxwang T14; lucasjsr2 T14; askwakhid T14
- zhen-zen/YogaSMC; hoaug-tran/ReYogaSMC
- OpenIntelWireless/itlwm (#781); osxlatitude/insanelymac/tonymacx86 threads
