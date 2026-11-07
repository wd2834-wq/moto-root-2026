# Motorola Moto G Play 2026 (XT2615-3, nevada) flasher

Windows loader for build **W1WNS36.18-111-7-2-2** (MT6835, Android 16). It replays Motorola's own
`flashfile.xml` sequence from Rescue and Smart Assistant, and adds a root / unroot mode for the
verified pack.

## Setup

1. Copy this folder anywhere, e.g. `C:\nevada-flasher`.
2. Put the official **platform-tools** in `C:\nevada-flasher\platform-tools\`
   (https://dl.google.com/android/repository/platform-tools-latest-windows.zip) — needs `fastboot.exe`
   and `AdbWinApi.dll` **side by side**.
3. For a **full flash / unbrick**, copy the RSA firmware folder here and rename it `rom`
   (it must contain `flashfile.xml`, `PGPT`, `super.img_sparsechunk.0` … `.26`, ~6.9 GB).
4. For **root / unroot**, copy `init_boot_patched_v31.1_W1WNS36.18-111-7-2-2.img`,
   `init_boot_stock_111-7-2-2.img` and `boot_stock_111-7-2-2.img` next to the `.bat`.

Put the phone in bootloader mode: power off, hold **Vol-Down + Power**.

## Usage

```
flash_model_nevada.bat                  full stock flash from .\rom   (wipes data)
flash_model_nevada.bat --yes            same, no confirmation prompt
flash_model_nevada.bat --root           flash Magisk root to slot A    (keeps data)
flash_model_nevada.bat --restore        undo root (stock init_boot + boot, slot A)
flash_model_nevada.bat --slot-b         target slot B instead of A
```

The script refuses to run if the firmware in `rom\` is not `W1WNS36.18-111-7-2-2`, if the device is
not `nevada_g_sys`, or if `super.img_sparsechunk.26` is missing — so a wrong or half-downloaded ROM
cannot be flashed by accident.

## What full flash does (order taken from flashfile.xml)

1. `gpt` ← `PGPT` (repartition), `oem fb_mode_set`, `preloader`
2. `lk tee mcupm pi_img sspm dtbo logo` ← `_a`, then `flush`
3. erase `nvdata`
4. `spmfw scp vbmeta vbmeta_system md1img dpm gz mcf_ota vcp connsys_bt` ← `_a`
5. `init_boot boot vendor_boot` ← `_a`
6. `super` ← sparsechunk 0…26
7. erase `userdata metadata debug_token`, `oem fb_mode_clear`, `oem config unset console/cmdl`, reboot

`efuseBackup` (from `efuse.img`) is **not** flashed — it holds per-device calibration data and is
normally missing from service firmware. Keep your existing one.

## Troubleshooting

- `No such file or directory` from fastboot: known Motorola quirk. Re-enter the bootloader
  (Vol-Down + Power) and run again. The script does this automatically between root flashes.
- `Device is LOCKED`: enable **OEM unlocking** in Developer options, then run the standard
  fastboot unlock (wipes data).
- Phone black-screens mid-flash: hold **Vol-Down + Power** ~10 s. Bootloader is unaffected; re-run
  the full flash from the start.
- `Couldn't parse erase-block-size`: harmless, from the `erase` steps on some fastboot versions.
