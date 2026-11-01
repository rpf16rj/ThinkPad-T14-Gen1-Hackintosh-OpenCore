# Lenovo ThinkPad T14 Gen 1 (Intel) — OpenCore EFI for macOS Sonoma

Optimized, documented EFI for the **Lenovo ThinkPad T14 Gen 1** running **macOS Sonoma 14.7.2** with **OpenCore 1.0.8**.

> Built through spec-driven research + on-hardware validation. Every change is justified and logged in `docs/`.

## Hardware

| Component | Detail | Status |
|---|---|---|
| CPU | i7-10610U (Comet Lake, 4C/8T, 15W) | ✅ XCPM + CPUFriend EPP=0xC0 |
| iGPU | UHD 620 (`0x9B3E`, platform `0x3E9B0000`) | ✅ Metal 3, QuickSync H.264/HEVC |
| RAM | 40 GB | ✅ |
| Audio | Realtek ALC257 | ✅ layout-id 86 (headset jack mic works) |
| Wi-Fi | Intel CNVi AX201 | ✅ **itlwm 2.3.0 + HeliPort** (ethernet-spoof — no airportd scans) |
| Bluetooth | Intel AX201 | ✅ works (USB map fix) |
| Webcam | AzureWave (USB internal) | ✅ works (USB map fix) |
| Ethernet | Intel I219 | ✅ IntelMausi |
| Trackpad/TrackPoint | Synaptics RMI | ✅ VoodooRMI SMBus (TrackPoint 2×, palm-reject fixed) |
| SD reader | Realtek RTS522A | ⛔ kext disabled (180s sleep-timeout bug, issue #55) |
| Battery | 50Wh | ✅ SMCBatteryManager (YogaSMC disabled — EC contention on AC plug) |
| Sleep/Hibernate | S3 + real S4 | ✅ hibernatemode 25, `hbfx-ahbm=15` (S4 only on battery+lid) |
| External display | USB-C (DP alt-mode) | ✅ perfect color output |
| Feature unlocks | Sidecar/AirPlay/Night Shift | ✅ FeatureUnlock 1.1.8 (AWDL absent — Sidecar is wired-only) |
| ⚠️ Native HDMI port | EDID negotiates YCbCr on some monitors | ⚠️ use USB-C adapter instead |
| ❌ Internal mic | Intel SST/cAVS DSP (not ALC257) | ❌ no macOS driver exists — use headset/USB mic |
| ⚠️ Premium DRM | iGPU-only | ❌ Netflix/Prime only via browser |

## Structure

```
EFI/                  ← current WORKING EFI (copy to ESP)
docs/
  ESTADO_ATUAL.md     ← initial hardware/config audit (PT)
  RESEARCH.md         ← consolidated research with sources (PT)
  PLANO_OTIMIZACAO.md ← tiered plan + application log (PT)
  config_dump.json    ← original exported config
scripts/
  tier1_pmset.sh      ← power settings (Tier 1)
  tier3_pmset.sh      ← hibernation hibernatemode 25 (Tier 3)
backup_original/      ← original config.plist + kexts (pre-optimization)
display_overrides/    ← RGB-forced EDID override attempt (reference)
scripts/ssd_battery_tweaks.sh ← noatime/logd/spotlight/RAM-disk (SSD-wear + battery)
```

## Applied changes (summary)

**Tier 1** — pmset tuned, removed `enable-hdmi20`/`agdpmod`, Sonoma backlight fix (`-igfxblt` property), `framebuffer-unifiedmem` 2048MB, ECEnabler 1.0.6, Baio1977 card reader forks.

**Tier 2** — CPUFriend 1.3.0 + custom DataProvider (EPP 0x80→0xC0), audio layout 97→**86** (jack mic), con2 HDMI→DP (USB-C).

**Tier 3** — HibernationFixup 1.5.5 + RTCMemoryFixup 1.0.8 (`rtcfx_exclude=80-AB,B0-B4`), HibernateMode=NVRAM, DiscardHibernateMap, DisableRtcChecksum, T490 ReservedMemory entry. ~~DisablePROCHOT.efi~~ removed (incompatible).

**Extras** — `igfxfw=2` GuC on (smooth UI — stutter fix), VideoToolbox HW accel verified.

**Bug-hunt** — `pci-aspm-default=0` on Wi-Fi; `rps-control` removed (iGPU stuck-max → heat); YogaSMC/SMCLightSensor/RestrictEvents disabled (YogaSMC caused EC contention → `kernel_task` 100% on AC plug); RealtekCardReader+Friend disabled (180s sleep-timeout → slow resume); `USBPorts.kext` model key fixed `MacBookPro15,4→16,2` (unlocked Bluetooth + webcam); FeatureUnlock 1.1.8. All validated on hardware.

**Wi-Fi deep-dive** — AirportItlwm → **itlwm.kext + HeliPort** (ethernet-spoof kills macOS-initiated scans = fixes streaming stutter + post-sleep drops); `io80211.awdl=0`, IPv6 link-local, TCP windows 4MB.

**Battery/SSD round** — `pci-aspm-default=0x2` on NVMe+bridge and 0x3 on I219 (~1-2W idle); `perf-bias=0x0F` in provider; noatime on Data volume; logd persist off (~500MB/day writes cut); ReportCrash off; Spotlight off; RAM disk for caches; io-throttle off; `hbfx-ahbm=15` hibernation gating.

**UI/UX** — reduceTransparency+motion, animations off, `AppleFontSmoothing=3` (retina-like weight on 1080p), HiDPI scaling via BetterDisplay, 19 dead daemons disabled, TrackPoint tuned (2× speed, palm-reject bug fixed).

## Usage

1. Mount ESP: `sudo diskutil mount diskXsY`
2. Copy `EFI/` to the ESP root
3. Run `scripts/tier1_pmset.sh` and `scripts/tier3_pmset.sh` with sudo
4. Reboot

## Warnings

- ⚠️ **`config.plist` uses generated SMBIOS serials (MBP16,2)** — **regenerate your own** with [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) before using (`PlatformInfo→Generic`), otherwise iServices will not work.
- Regenerate `CPUFriendDataProvider` after each macOS update.
- Native HDMI may output pink-tinted video on monitors that negotiate YCbCr — use a USB-C adapter.
- Wi-Fi is managed by **HeliPort.app** (not the native menu) — itlwm presents as Ethernet.
- Tested: boot, S3→S4 sleep, full audio, QuickSync, Wi-Fi/BT/webcam, USB-C display, Moonlight.

## Credits / References

- [5T33Z0/Thinkpad-T490-Hackintosh-OpenCore](https://github.com/5T33Z0/Thinkpad-T490-Hackintosh-OpenCore) — hibernation, framebuffer, ReYogaSMC
- [Baio1977/Lenovo-Thinkpad-T14](https://github.com/Baio1977/Lenovo-Thinkpad-T14) — card reader forks, exact T14
- [acidanthera](https://github.com/acidanthera) — OpenCore, Lilu, WEG, AppleALC, CPUFriend, HBFX, RTCMemoryFixup
- [dortania](https://dortania.github.io) — base guides
