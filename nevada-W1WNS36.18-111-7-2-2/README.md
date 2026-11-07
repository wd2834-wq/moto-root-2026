# Motorola Moto G Play (2026) `nevada` — Magisk root via patched `init_boot`

Pre-patched `init_boot` image + stock images for the **Motorola Moto G Play (2026)**, model **XT2615-3**,
codename `nevada` / `nevada_g_sys`, MediaTek **MT6835**, **Android 16 (SDK 36)**.

Tested on build **`W1WNS36.18-111-7-2-2`**
(fingerprint `motorola/nevada_g_sys/nevada:16/W1WNS36.18-111-7-2-2/ded89d-b274ce:user/release-keys`),
bootloader `MBM-3.1-nevada_g_vext-5e177-W1WNS36.18-111-7-2-2-ded89d`, CID 51, AVB 1.3, `ro.boot.verifiedbootstate=orange`.

Root was confirmed working on the device: `su -c id` → `uid=0(root) … context=u:r:magisk:s0`, Magisk app
shows **31.1 (31100)**, **Ramdisk: Yes**.

---

## Contents

```
work/
  init_boot_patched_v31.1_W1WNS36.18-111-7-2-2.img   Magisk 31.1-patched init_boot (flash this)
  Magisk-v31.1.apk                                   official Magisk manager (GitHub release)
stock/
  init_boot_stock_111-7-2-2.img                      stock init_boot (restore)
  boot_stock_111-7-2-2.img                           stock boot (restore / reference)
```

| file | size (bytes) | md5 | sha256 |
|---|---|---|---|
| `work/init_boot_patched_v31.1_W1WNS36.18-111-7-2-2.img` | 2,802,496 | `0166fe6f68c0088b9b5997e2851684aa` | `129396d6c7024dd5db190d50efe6906ad2628f910ebf6a4af3da09724bb0669a` |
| `work/Magisk-v31.1.apk` | 10,679,283 | — | `89cefac0a318afa39fb3880c45c87b036c05bc1ebf02a7a715b7f8d7c26ac6e7` |
| `stock/init_boot_stock_111-7-2-2.img` | 8,388,608 | `a3eeef99746e4a95bbbe12df98942a4b` | `4ef5c11ad083c87ea10d47e692cb2d94ac9ed09323fea527b1581d9db822c19d` |
| `stock/boot_stock_111-7-2-2.img` | 67,108,864 | `26a74008280d22d3e1f124db659d595b` | `dd3eb2706887384e4b598679111efef10cac4a2e3ee3808b8d3a570ad63484dd` |

---

## Requirements / warnings

- **Unlocked bootloader** required (`fastboot flashing unlock`; this wipes data). Already-unlocked device: skip.
- The patched image is **only** for build `W1WNS36.18-111-7-2-2`. A different build needs its own `init_boot.img` re-patched.
- Flash **one slot only** (A). Keep slot B stock as a fallback.
- **OTA updates will fail** / re-root is required after any OTA. Never accept an OTA while rooted without restoring stock first.
- **Do not use Magisk's "Direct Install"** on this device: it repacks the image the "normal" way
  (8 MiB with an AVB footer), which Motorola's bootloader **rejects** (see *Why this works*).
- Do not flash a Magisk-patched image built by Magisk **v27** `magiskboot`; it truncates the ramdisk and drops the
  image off the stock layout, resulting in a stock boot (no root).
- Rooting voids warranty, trips **`verifiedbootstate=orange`**, and breaks some banking/DRM apps.
- You are responsible for your own device. Keep the stock images offline; they are the way back.

---

## Flash (from bootloader / fastboot)

Put the phone in bootloader mode (`adb reboot bootloader`, or power+vol-down).

```sh
# Always re-enter the bootloader right before flashing:
# Motorola fastboot intermittently answers "FAILED (remote: No such file or directory)"
fastboot reboot-bootloader
fastboot getvar current-slot            # confirm a; otherwise use init_boot_b below
fastboot flash init_boot_a work/init_boot_patched_v31.1_W1WNS36.18-111-7-2-2.img
fastboot reboot
```

Then install `work/Magisk-v31.1.apk` (must be **v31.1**, to match the embedded `magiskinit`), open it, and grant root
when prompted by apps. Magisk Home should read `Installed: 31.1 (31100)` and `Ramdisk: Yes`.

> On Git Bash use `cygpath -w <file>` for image paths, and `MSYS_NO_PATHCONV=1` for `fastboot` device paths
> (`/dev/block/...`), otherwise MSYS mangles the arguments.

## Restore to stock (unroot)

```sh
fastboot reboot-bootloader
fastboot flash init_boot_a stock/init_boot_stock_111-7-2-2.img
fastboot flash boot_a      stock/boot_stock_111-7-2-2.img
fastboot reboot
```

Slot B was never touched; if slot A fails to boot, the bootloader falls back to slot B (stock, unrooted).
Uninstalling the Magisk app afterwards removes the manager.

---

## How the patched image was made (recipe)

Two Motorola-specific quirks had to be worked around.

**1. Preflash validation: the image must end exactly at the end of its embedded vbmeta.**
Motorola rejects any `init_boot` image that is not byte-exact in size/layout — an 8 MiB image with an AVB footer
fails validation, while the same image truncated right after the vbmeta blob flashes `OKAY`.

**2. Magisk stage-1 needs the stock section layout.**
Simply repacking with a smaller ramdisk produced an image that boots but never starts `magiskd`
(no `/debug_ramdisk`, Magisk reports `Ramdisk: No`). Using **Magisk v31.1's own `magiskboot`** keeps the original
image size and section offsets (`original_ramdisk_size` stays 0, `original_dtb_size` 0x6018), and stage-1 works.

Recipe on the stock `init_boot.img`:

1. Patch with Magisk **v31.1**'s own `boot_patch.sh` and `magiskboot` (not v27's, not the app).
2. In the embedded vbmeta at `vbmeta_offset` (here `0x2AC000`, `AvbFooter` at end of file), zero the `u64` at
   `vbmeta_offset + 0x18` (vbmeta `auxiliary_block_size` field in this layout, which also clears the chained flag).
3. Truncate the file to `vbmeta_offset + 0x340` → **2,802,496 bytes** (`0x2AC340`), no AVB footer, no padding.
4. Flash as above (`fastboot reboot-bootloader` first).

Resulting header (little-endian fields):
`ANDROID!  original_ramdisk_size=0  kernel_size=0x2AAA18 (ramdisk)  original_dtb_size=0x6018  dtb_size=0  page_size=0x1000`,
vbmeta at `0x2AC000` starts with `AVB0 00000001` (unsigned, auxiliary block zeroed), descriptors
`com.android.build.init_boot.os_version` and `com.android.build.init_boot.fingerprint` intact at the file tail.

> Note: step 2 (zeroing the vbmeta aux field) and step 1's stock-size layout are both part of the working,
> device-tested combination. Their individual contributions were not isolated further — reproduce both.

## Other observations

- Stock `init_boot` is 8 MiB with the AVB footer at offset `0x7FFFC0`; stock vbmeta blob is `0x340` bytes at `0x323000`.
- `fastboot boot` (temporary boot) is not implemented on this device.
- `fastboot oem device-info` is unsupported.
- `dmesg` and `/proc/1/*` are not readable as `shell` on this build.
- Stock images should also be available from Motorola Rescue and Smart Assistant (RSA) for this build;
  the copies here are byte-identical to it.

## Credits & support

- Root pack, verification and recipe: [wd2834-wq](https://github.com/wd2834-wq)
- One-click root/unbrick script in this repo: original project by Bill J Trammell ([ghost-ble](https://github.com/bill-jtrammell), [moto-root-2026](https://github.com/bill-jtrammell/moto-root-2026))

Support this pack:

- **PayPal (maintainer)**: igorwd@gmail.com

Support the original author:

- **PayPal**: bill.jtrammell@gmail.com
- **Cash App**: $slauter99
