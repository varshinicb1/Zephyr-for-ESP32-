# Zephyr RTOS ESP32 Setup Guide

## Overview
This guide documents the complete process to set up Zephyr RTOS development environment for ESP32 boards, based on a successful Ubuntu 22.04 installation.

## Prerequisites
- Ubuntu 22.04 LTS (or similar Debian-based system)
- USB cable for ESP32 board
- Internet connection
- At least 2GB free disk space

## Hardware Requirements
- ESP32-based development board (ESP32 DevKitC, EdgeHax ESP32-4G, etc.)
- USB-to-serial bridge (usually built into dev boards)

## Installation Process

### Step 1: Install System Dependencies
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential build tools
sudo apt install -y --no-install-recommends \
    git cmake ninja-build gperf ccache dfu-util \
    device-tree-compiler wget python3-dev python3-pip \
    python3-setuptools python3-tk python3-wheel \
    xz-utils file make gcc gcc-multilib g++-multilib \
    libsdl2-dev libmagic1

# Add user to dialout group for serial port access
sudo usermod -aG dialout $USER
```
**⚠️ IMPORTANT: Log out and log back in after adding to dialout group!**

### Step 2: Install Python Dependencies
```bash
# Create and activate Python virtual environment
python3 -m venv ~/zephyrproject/.venv
source ~/zephyrproject/.venv/bin/activate

# Install west and other Python tools
pip install west
```

### Step 3: Get Zephyr Source Code
```bash
# Initialize Zephyr workspace
west init ~/zephyrproject
cd ~/zephyrproject

# Update all repositories
west update

# Install additional Python requirements
west zephyr-export
pip install -r ~/zephyrproject/zephyr/scripts/requirements.txt
```

### Step 4: Install Zephyr SDK
```bash
# Download and install Zephyr SDK 0.17.2 (or latest)
cd ~
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.2/zephyr-sdk-0.17.2_linux-x86_64.tar.xz
tar xvf zephyr-sdk-0.17.2_linux-x86_64.tar.xz
cd zephyr-sdk-0.17.2
./setup.sh

# Set environment variable
echo 'export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.2"' >> ~/.bashrc
source ~/.bashrc
```

## Building and Flashing

### Basic Build Process
```bash
# Always activate virtual environment first
cd ~/zephyrproject/zephyr
source ../.venv/bin/activate

# Build a sample (replace with your target)
west build -p always -b esp32_devkitc/esp32/procpu samples/hello_world

# Flash to ESP32
west flash --esp-device /dev/ttyUSB0 --esp-baud-rate 115200

# Monitor serial output
west espressif monitor
```

### Common Board Targets
- `esp32_devkitc/esp32/procpu` - Standard ESP32 DevKitC
- `esp32s3_devkitc/esp32s3/procpu` - ESP32-S3 DevKitC
- `esp32c3_devkitm/esp32c3` - ESP32-C3 DevKitM

### Sample Applications
```bash
# Hello World (basic test)
west build -p always -b esp32_devkitc/esp32/procpu samples/hello_world

# Blinky (LED control)
west build -p always -b esp32_devkitc/esp32/procpu samples/basic/blinky

# Deep Sleep (power management)
west build -p always -b esp32_devkitc/esp32/procpu samples/boards/espressif/deep_sleep

# WiFi Shell (network capabilities)
west build -p always -b esp32_devkitc/esp32/procpu samples/net/wifi/shell

# Bluetooth Beacon
west build -p always -b esp32_devkitc/esp32/procpu samples/bluetooth/beacon
```

## Troubleshooting

### Build Errors
- **Different project in build directory**: Use `-p always` to clean build
- **Board not found**: Check board name with `west boards | grep esp32`
- **Missing LED alias**: Create devicetree overlay (see LED Configuration section)

### Flash Errors
- **Port busy**: `sudo fuser -k /dev/ttyUSB0`
- **Permission denied**: Check dialout group membership with `groups`
- **Connection failed**: Try lower baud rate `--esp-baud-rate 115200`
- **Manual boot mode**: Hold BOOT button, press EN button, release BOOT, then flash

### LED Configuration for Blinky
For boards without LED aliases, create overlay file:
```bash
mkdir -p ~/zephyrproject/zephyr/samples/basic/blinky/boards/esp32_devkitc
nano ~/zephyrproject/zephyr/samples/basic/blinky/boards/esp32_devkitc/esp32_devkitc_procpu.overlay
```

Add content:
```dts
/ {
    aliases {
        led0 = &blue_led;
    };

    leds {
        compatible = "gpio-leds";
        blue_led: led_0 {
            gpios = <&gpio0 2 GPIO_ACTIVE_HIGH>;
            label = "Blue LED";
        };
    };
};
```

## Environment Setup
Always run these commands when starting development:
```bash
cd ~/zephyrproject/zephyr
source ../.venv/bin/activate
```

## Key Features of Zephyr RTOS
- **Real-time scheduling** with priority-based preemption
- **Memory protection** with MPU support
- **Power management** including deep sleep modes
- **Networking stack** with WiFi, Bluetooth, cellular support
- **Device tree** hardware abstraction
- **Professional tooling** with CMake and Kconfig
- **OTA updates** and secure boot capabilities
- **Multi-platform support** across 750+ boards

## What Makes Zephyr Different
- **Enterprise-grade reliability** vs hobbyist frameworks
- **Deterministic real-time behavior** for critical applications
- **Built-in security** with encryption and secure boot
- **Professional development ecosystem** used by major companies
- **Scalable architecture** from simple sensors to complex gateways
- **Vendor-neutral** open source with Linux Foundation backing

## Next Steps
1. **Test basic functionality** with hello_world and blinky samples
2. **Explore networking** with WiFi and Bluetooth samples
3. **Implement power management** with deep sleep samples
4. **Develop custom applications** for your specific use case
5. **Create custom board definitions** for your hardware

## Support Resources
- Official Documentation: https://docs.zephyrproject.org
- GitHub Repository: https://github.com/zephyrproject-rtos/zephyr
- Community Support: https://github.com/zephyrproject-rtos/zephyr/discussions
- Discord Channel: Zephyr RTOS community

## Version Information
- **Tested on**: Ubuntu 22.04 LTS
- **Zephyr Version**: 4.2.99 (development)
- **SDK Version**: 0.17.2
- **Date**: August 2025