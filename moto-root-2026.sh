#!/bin/bash
#============================================================
# Moto G Play 2026 (XT2615-1) Root Script
# Codename: nevada | Chipset: MediaTek | Android 16
#
# One-click root with auto-recovery if something goes wrong.
# Includes stock ROM flash capability for unbricking.
#
# Usage:
#   chmod +x moto-root-2026.sh
#   ./moto-root-2026.sh
#
# Requirements:
#   - Linux, macOS, or WSL
#   - adb and fastboot installed
#   - USB cable connected to phone
#
# Developed by ghost — https://paypal.me/ghost-ble
# Buy me a coffee: bill.jtrammell@gmail.com (PayPal/Cash App)
#============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAGISK_APK_URL="https://github.com/topjohnwu/Magisk/releases/download/v29.0/Magisk-v29.0.apk"
MAGISK_APK="$SCRIPT_DIR/Magisk.apk"
FIRMWARE_URL="https://mirrors.lolinet.com/firmware/lenomola/2026/nevada/official/RETUS/"

banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║  Moto G Play 2026 (XT2615-1) Root Script     ║"
    echo "  ║  Codename: nevada | Android 16 | MediaTek    ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[-]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

check_deps() {
    log "Checking dependencies..."
    local missing=0
    for cmd in adb fastboot; do
        if command -v "$cmd" &>/dev/null; then
            info "$cmd: $(command -v "$cmd")"
        elif [ -f "$HOME/Android/Sdk/platform-tools/$cmd" ]; then
            export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
            info "$cmd: found in Android SDK"
        else
            err "$cmd not found! Install Android platform-tools."
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo ""
        echo "  Install instructions:"
        echo "    Ubuntu/Debian: sudo apt install android-tools-adb android-tools-fastboot"
        echo "    Arch: sudo pacman -S android-tools"
        echo "    macOS: brew install android-platform-tools"
        echo "    Or download from: https://developer.android.com/tools/releases/platform-tools"
        exit 1
    fi
}

check_device() {
    log "Checking for connected device..."
    
    # Check ADB
    local adb_state
    adb_state=$(adb get-state 2>/dev/null || echo "none")
    
    if [ "$adb_state" = "device" ]; then
        local model=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')
        local build=$(adb shell getprop ro.build.display.id 2>/dev/null | tr -d '\r')
        local android=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
        local serial=$(adb get-serialno 2>/dev/null | tr -d '\r')
        
        info "Device found via ADB"
        info "  Model: $model"
        info "  Android: $android"
        info "  Build: $build"
        info "  Serial: $serial"
        
        if [[ "$model" != *"XT2615"* ]] && [[ "$model" != *"Moto G Play"* ]]; then
            warn "This doesn't look like a Moto G Play 2026 (XT2615-1)"
            warn "Detected: $model"
            read -p "Continue anyway? (y/N): " confirm
            [[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 1
        fi
        return 0
    fi
    
    # Check fastboot
    local fb_state
    fb_state=$(fastboot getvar product 2>&1 | head -1 || echo "none")
    if [[ "$fb_state" == *"nevada"* ]] || [[ "$fb_state" == *"mt"* ]]; then
        info "Device found in fastboot mode"
        return 0
    fi
    
    err "No device detected!"
    echo ""
    echo "  Make sure:"
    echo "    1. USB debugging is enabled (Settings > Developer Options)"
    echo "    2. USB cable is connected"
    echo "    3. Phone is unlocked for USB debugging"
    echo ""
    echo "  If phone is bricked/bootlooping:"
    echo "    Hold Volume Down + Power for 10 seconds to enter fastboot"
    echo ""
    read -p "Press Enter to retry detection, or Ctrl+C to exit..."
    check_device
}

get_unlock_data() {
    log "Getting bootloader unlock data..."
    adb reboot bootloader 2>/dev/null
    sleep 5
    
    local unlock_data
    unlock_data=$(fastboot oem get_unlock_data 2>&1 | grep -v "OKAY\|finished\|total" | tr -d '\r\n ' | sed 's/(bootloader)//g')
    
    if [ -z "$unlock_data" ]; then
        err "Failed to get unlock data. Is the bootloader already unlocked?"
        local state=$(fastboot oem device-info 2>&1 | grep -i "unlocked" || echo "unknown")
        info "Bootloader state: $state"
        return 1
    fi
    
    info "Unlock data: $unlock_data"
    echo ""
    echo "  ═══════════════════════════════════════════════════"
    echo "  NEXT STEPS:"
    echo "  1. Go to: https://motorola-global-portal.custhelp.com/app/standalone/bootloader/unlock-your-device-a"
    echo "  2. Sign in with your Motorola account"
    echo "  3. Paste this unlock data:"
    echo ""
    echo -e "  ${BOLD}$unlock_data${NC}"
    echo ""
    echo "  4. Submit and wait for the unlock code email"
    echo "  5. Come back here and enter the code"
    echo "  ═══════════════════════════════════════════════════"
    echo ""
    
    read -p "Enter unlock code from Motorola email (or 'skip' if already unlocked): " unlock_code
    
    if [ "$unlock_code" != "skip" ] && [ -n "$unlock_code" ]; then
        warn "Unlocking bootloader. This ERASES ALL DATA."
        read -p "Type 'ERASE' to confirm: " confirm
        if [ "$confirm" = "ERASE" ]; then
            fastboot oem unlock "$unlock_code"
            log "Unlock sent. Phone will reboot and wipe data."
            log "Wait for phone to boot, re-enable USB debugging, then re-run this script."
            fastboot reboot 2>/dev/null
            exit 0
        else
            warn "Unlock cancelled."
        fi
    fi
}

check_bootloader() {
    log "Checking bootloader state..."
    adb reboot bootloader 2>/dev/null
    sleep 5
    
    local info
    info=$(fastboot oem device-info 2>&1)
    
    if echo "$info" | grep -qi "unlocked.*true"; then
        log "Bootloader is UNLOCKED"
        return 0
    elif echo "$info" | grep -qi "unlocked.*false"; then
        warn "Bootloader is LOCKED"
        get_unlock_data
        return $?
    else
        warn "Could not determine bootloader state"
        info "fastboot output: $info"
        return 1
    fi
}

backup_boot() {
    log "Backing up original boot.img..."
    adb reboot bootloader 2>/dev/null
    sleep 5
    
    local backup_dir="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    fastboot pull boot_a "$backup_dir/boot_a.img" 2>/dev/null || true
    fastboot pull boot_b "$backup_dir/boot_b.img" 2>/dev/null || true
    fastboot pull boot "$backup_dir/boot.img" 2>/dev/null || true
    
    log "Backup saved to: $backup_dir"
    ls -la "$backup_dir/"
}

extract_boot_from_firmware() {
    log "Extracting boot.img from stock firmware..."
    
    local fw_zip
    fw_zip=$(find "$SCRIPT_DIR" "$HOME/Downloads" -name "*nevada*RETUS*.zip" -o -name "*XT2615*.zip" 2>/dev/null | head -1)
    
    if [ -z "$fw_zip" ]; then
        warn "Stock firmware ZIP not found."
        echo ""
        echo "  Download the stock firmware from:"
        echo "  $FIRMWARE_URL"
        echo ""
        echo "  Place the ZIP in: $SCRIPT_DIR"
        echo "  Or in: $HOME/Downloads/"
        echo ""
        
        # Check if boot.img exists already
        if [ -f "$SCRIPT_DIR/boot.img" ]; then
            log "Found boot.img in script directory"
            return 0
        elif [ -f "$HOME/Downloads/moto_rom/boot.img" ]; then
            log "Found boot.img in ~/Downloads/moto_rom/"
            cp "$HOME/Downloads/moto_rom/boot.img" "$SCRIPT_DIR/boot.img"
            return 0
        fi
        
        read -p "Press Enter once firmware is downloaded..."
        extract_boot_from_firmware
        return
    fi
    
    info "Found firmware: $fw_zip"
    
    # Try to extract boot.img directly
    local tmpdir="$SCRIPT_DIR/_fw_extract"
    mkdir -p "$tmpdir"
    
    unzip -o -j "$fw_zip" "boot.img" -d "$tmpdir" 2>/dev/null && {
        cp "$tmpdir/boot.img" "$SCRIPT_DIR/boot.img"
        log "Extracted boot.img from ZIP"
        rm -rf "$tmpdir"
        return 0
    }
    
    # Try payload.bin extraction
    unzip -o -j "$fw_zip" "payload.bin" -d "$tmpdir" 2>/dev/null && {
        if command -v payload-dumper-go &>/dev/null; then
            payload-dumper-go -o "$tmpdir/out" "$tmpdir/payload.bin" --partitions boot 2>/dev/null
            cp "$tmpdir/out/boot.img" "$SCRIPT_DIR/boot.img"
            log "Extracted boot.img from payload.bin"
            rm -rf "$tmpdir"
            return 0
        elif command -v payload-dumper &>/dev/null; then
            cd "$tmpdir"
            payload-dumper -o out payload.bin --partitions boot 2>/dev/null
            cp "$tmpdir/out/boot.img" "$SCRIPT_DIR/boot.img"
            cd "$SCRIPT_DIR"
            log "Extracted boot.img from payload.bin"
            rm -rf "$tmpdir"
            return 0
        fi
    }
    
    rm -rf "$tmpdir"
    err "Could not extract boot.img from firmware"
    return 1
}

patch_boot_with_magisk() {
    log "Patching boot.img with Magisk..."
    
    if [ ! -f "$SCRIPT_DIR/boot.img" ]; then
        extract_boot_from_firmware
    fi
    
    # Push boot.img to phone
    adb push "$SCRIPT_DIR/boot.img" /sdcard/Download/boot.img
    log "boot.img pushed to phone"
    
    echo ""
    echo "  ═══════════════════════════════════════════════════"
    echo "  MANUAL STEP REQUIRED:"
    echo ""
    echo "  1. On your phone, open Magisk app"
    echo "     (Install from: https://github.com/topjohnwu/Magisk/releases)"
    echo ""
    echo "  2. Tap 'Install' -> 'Select and Patch a File'"
    echo "  3. Navigate to /sdcard/Download/boot.img"
    echo "  4. Wait for patching to complete"
    echo "  5. The patched file will be saved as:"
    echo "     /sdcard/Download/magisk_patched-XXXXX.img"
    echo ""
    echo "  ═══════════════════════════════════════════════════"
    echo ""
    
    read -p "Press Enter when Magisk patching is complete..."
    
    # Find the patched file
    local patched
    patched=$(adb shell "ls -t /sdcard/Download/magisk_patched-*.img 2>/dev/null | head -1" | tr -d '\r')
    
    if [ -z "$patched" ]; then
        err "Could not find patched boot image on phone"
        err "Expected: /sdcard/Download/magisk_patched-*.img"
        return 1
    fi
    
    info "Found patched image: $patched"
    adb pull "$patched" "$SCRIPT_DIR/magisk_patched.img"
    log "Patched boot image pulled to: $SCRIPT_DIR/magisk_patched.img"
    return 0
}

flash_patched_boot() {
    log "Flashing patched boot image..."
    
    if [ ! -f "$SCRIPT_DIR/magisk_patched.img" ]; then
        err "magisk_patched.img not found!"
        return 1
    fi
    
    # Go to fastboot
    adb reboot bootloader 2>/dev/null
    sleep 5
    
    # Detect which boot partition to use
    local current_slot
    current_slot=$(fastboot getvar current-slot 2>&1 | grep -o "[ab]" || echo "a")
    info "Current slot: $current_slot"
    
    # Flash to both slots for safety
    fastboot flash boot_a "$SCRIPT_DIR/magisk_patched.img" 2>/dev/null && log "Flashed boot_a" || true
    fastboot flash boot_b "$SCRIPT_DIR/magisk_patched.img" 2>/dev/null && log "Flashed boot_b" || true
    fastboot flash boot "$SCRIPT_DIR/magisk_patched.img" 2>/dev/null && log "Flashed boot" || true
    
    log "Flash complete!"
    echo ""
    warn "IMPORTANT: First boot may take 2-3 minutes"
    warn "Do NOT interrupt the boot process"
    echo ""
    
    read -p "Reboot now? (Y/n): " do_reboot
    if [ "$do_reboot" != "n" ] && [ "$do_reboot" != "N" ]; then
        fastboot reboot
        log "Rebooting... Wait for phone to fully boot."
        echo ""
        echo "  After boot, verify root with:"
        echo "    adb shell su -c 'id'"
        echo "  Or install 'Root Checker' from Play Store"
    fi
}

unbrick() {
    log "Stock ROM recovery mode..."
    echo ""
    echo "  This will flash the FULL stock ROM to recover a bricked device."
    echo "  ALL DATA WILL BE ERASED."
    echo ""
    
    local flash_script="$SCRIPT_DIR/flash_moto.sh"
    
    if [ ! -f "$flash_script" ]; then
        # Check common locations
        for dir in "$HOME/Downloads/moto_rom" "$SCRIPT_DIR/firmware" "$SCRIPT_DIR"; do
            if [ -f "$dir/flash_moto.sh" ]; then
                flash_script="$dir/flash_moto.sh"
                break
            fi
        done
    fi
    
    if [ ! -f "$flash_script" ]; then
        err "flash_moto.sh not found!"
        echo ""
        echo "  You need the full stock firmware with flash_moto.sh"
        echo "  Download from: $FIRMWARE_URL"
        echo "  Extract and place all files in: $SCRIPT_DIR/"
        echo ""
        echo "  Required files:"
        echo "    flash_moto.sh, flashfile.xml, boot.img, dtbo.img,"
        echo "    PGPT, preloader.img, lk.img, tee.img, etc."
        return 1
    fi
    
    info "Found flash script: $flash_script"
    warn "Phone must be in fastboot mode (Vol Down + Power)"
    read -p "Proceed with stock flash? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return 1
    
    chmod +x "$flash_script"
    bash "$flash_script"
}

recovery_menu() {
    echo ""
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║         Recovery & Troubleshooting            ║"
    echo "  ╠═══════════════════════════════════════════════╣"
    echo "  ║  1. Flash stock ROM (unbrick)                ║"
    echo "  ║  2. Restore original boot.img                ║"
    echo "  ║  3. Force reboot to fastboot                 ║"
    echo "  ║  4. Back to main menu                        ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
    read -p "Choice: " choice
    
    case $choice in
        1) unbrick ;;
        2)
            local backup_dir
            backup_dir=$(find "$SCRIPT_DIR" -maxdepth 1 -name "backup_*" -type d | sort -r | head -1)
            if [ -n "$backup_dir" ]; then
                adb reboot bootloader 2>/dev/null; sleep 5
                if [ -f "$backup_dir/boot_a.img" ]; then
                    fastboot flash boot_a "$backup_dir/boot_a.img"
                fi
                if [ -f "$backup_dir/boot_b.img" ]; then
                    fastboot flash boot_b "$backup_dir/boot_b.img"
                fi
                log "Original boot restored"
                fastboot reboot
            else
                err "No backup found"
            fi
            ;;
        3)
            adb reboot bootloader 2>/dev/null || true
            warn "Hold Vol Down + Power for 10 seconds if phone is unresponsive"
            ;;
        4) return ;;
    esac
}

main_menu() {
    banner
    check_deps
    
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║              Main Menu                        ║"
    echo "  ╠═══════════════════════════════════════════════╣"
    echo "  ║  1. Full root (recommended)                   ║"
    echo "  ║  2. Check device status                       ║"
    echo "  ║  3. Backup boot image                         ║"
    echo "  ║  4. Flash patched boot only                   ║"
    echo "  ║  5. Recovery / Unbrick                        ║"
    echo "  ║  6. Install Magisk app on phone               ║"
    echo "  ║  7. Exit                                      ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
    read -p "Choice: " choice
    
    case $choice in
        1)
            check_device
            check_bootloader
            backup_boot
            patch_boot_with_magisk
            flash_patched_boot
            ;;
        2)
            check_device
            adb shell getprop ro.product.model 2>/dev/null
            adb shell getprop ro.build.display.id 2>/dev/null
            adb shell getprop ro.build.version.release 2>/dev/null
            adb shell getprop ro.boot.bootloader 2>/dev/null || true
            ;;
        3)
            check_device
            backup_boot
            ;;
        4)
            check_device
            flash_patched_boot
            ;;
        5)
            recovery_menu
            ;;
        6)
            check_device
            log "Downloading Magisk..."
            curl -L -o "$MAGISK_APK" "$MAGISK_APK_URL"
            adb install "$MAGISK_APK" 2>/dev/null && log "Magisk installed on phone" || {
                warn "Direct install failed. Pushing APK to Downloads..."
                adb push "$MAGISK_APK" /sdcard/Download/Magisk.apk
                info "Install manually from /sdcard/Download/Magisk.apk"
            }
            ;;
        7)
            echo ""
            echo -e "${CYAN}Thanks for using this script!${NC}"
            echo ""
            echo "  If this helped you, consider buying me a coffee:"
            echo "  PayPal: bill.jtrammell@gmail.com"
            echo "  Cash App: \$slauter99"
            echo ""
            exit 0
            ;;
        *)
            warn "Invalid choice"
            main_menu
            ;;
    esac
}

#============================================================
# Entry point
#============================================================
main_menu

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  If this script saved you time or saved your phone,${NC}"
echo -e "${CYAN}  consider buying me a coffee! ☕${NC}"
echo ""
echo -e "  ${BOLD}PayPal: bill.jtrammell@gmail.com${NC}"
echo -e "  ${BOLD}Cash App: \$slauter99${NC}"
echo ""
echo "  Star this repo: https://github.com/ghost-ble/moto-root-2026"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
