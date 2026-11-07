# Moto G Play 2026 (XT2615-1) Root Script

One-click root for the Moto G Play 2026 with automatic recovery and unbricking.

## Device Info

| | |
|---|---|
| **Model** | Moto G Play 2026 (XT2615-1) |
| **Codename** | nevada |
| **Chipset** | MediaTek |
| **Android** | 16 |
| **Root Method** | Magisk (boot image patch) |

## Features

- Full root with Magisk in 5 minutes
- Automatic bootloader unlock flow
- Boot image backup before flashing
- Stock ROM recovery / unbrick mode
- Works on Linux, macOS, and WSL

## Requirements

- [Android platform-tools](https://developer.android.com/tools/releases/platform-tools) (adb + fastboot)
- USB cable
- Phone with USB debugging enabled

## Usage

```bash
chmod +x moto-root-2026.sh
./moto-root-2026.sh
```

## Menu Options

1. **Full root** - Complete root process (recommended)
2. **Check device** - Display phone info and connection status
3. **Backup boot** - Save original boot image
4. **Flash patched boot** - Flash already-patched boot.img
5. **Recovery/Unbrick** - Flash stock ROM to recover soft-bricked device
6. **Install Magisk** - Push and install Magisk APK to phone

## Unbricking

If your phone is stuck in a bootloop or won't boot:

1. Hold **Volume Down + Power** for 10 seconds to enter fastboot
2. Run the script and select **Recovery / Unbrick**
3. The script will flash the full stock ROM

You need the stock firmware ZIP for your model. Place it in the script directory.

## Troubleshooting

**"No device detected"**
- Enable USB debugging: Settings > About Phone > tap Build Number 7 times > Developer Options > USB Debugging
- Try a different USB cable (data cable, not charge-only)
- Hold Vol Down + Power for 10s to force fastboot mode

**"Bootloader is LOCKED"**
- The script will guide you through Motorola's unlock process
- This **erases all data** - back up first
- You need a Motorola account

**Phone stuck after root**
- Hold Vol Down + Power for 10s to enter fastboot
- Run the script and select Recovery > Restore original boot

## Disclaimer

Rooting your phone may void your warranty. This script backs up your original boot image so you can always restore it. Use at your own risk.

## Contributing

If this worked for your device, please open an issue or PR to let me know.

## Support

If this saved you time or saved your bricked phone:

- **PayPal**: bill.jtrammell@gmail.com
- **Cash App**: $slauter99

## License

MIT
