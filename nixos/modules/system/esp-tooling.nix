{ pkgs, ... }:
{
  boot.kernelModules = [
    "cp210x"  # USB-to-UART bridge (classic ESP32 via CP2102)
    "cp341"   # CH340/CH341 USB-to-UART bridge
    "cdc_acm" # Native USB ACM (ESP32-S2/S3/C3/C6/H2)
  ];

  services.udev.extraRules = ''
    # USB-to-UART bridges (CP210x, CH34x) — classic ESP32
    KERNEL=="ttyUSB[0-9]*", MODE="0660", GROUP="dialout"
    # Native USB CDC ACM — newer ESP32 variants
    KERNEL=="ttyACM[0-9]*", MODE="0660", GROUP="dialout"
  '';

  environment.systemPackages = with pkgs; [
    esptool
    espflash
  ];
}
