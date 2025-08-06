

# 🚀 Zephyr RTOS on ESP32/EdgeHax IoT Board — Ultimate Guide

## ✨ What’s This Repo?

A complete, reproducible guide for running **Zephyr RTOS** on ESP32/EdgeHax ESP32-4G/NavIC IoT boards.

- **Industrial-grade OS** for “serious” IoT and production.
- Professional, scriptable networking and shell.
- Foundation for adding 4G, NavIC, and market-ready features.


## 🛠 Prerequisites \& Setup

### System Requirements

- Ubuntu 22.04 or later (should work on most Linux distros)
- USB-serial cable with data support
- ESP32 DevKitC/EdgeHax ESP32-4G IoT Board


### TL;DR: Script-It Setup

**1. Update and Install Dependencies**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install --yes git cmake ninja-build gperf ccache dfu-util device-tree-compiler python3-pip python3-venv python3-setuptools python3-wheel python3-ply python3-colorama python3-packaging python3-tk wget
```

**2. Clone and Initialize Zephyr**

```bash
mkdir -p ~/zephyrproject
cd ~/zephyrproject
west init -m https://github.com/zephyrproject-rtos/zephyr.git
west update
west zephyr-export
```

**3. Create Python Virtual Environment**

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r zephyr/scripts/requirements.txt
```

**4. Install the Zephyr SDK**
(If not already, use the latest supported by your Zephyr repo!)

```bash
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.2/zephyr-sdk-0.17.2_linux-x86_64.tar.xz
tar xvf zephyr-sdk-0.17.2_linux-x86_64.tar.xz -C ~/
cd ~/zephyr-sdk-0.17.2
./setup.sh
```

Add to your shell startup (`~/.bashrc`):

```bash
echo 'export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.2"' >> ~/.bashrc
source ~/.bashrc
```

**5. Add User to Serial Group**

```bash
sudo usermod -aG dialout $USER
# Log out and log back in for group changes to take effect
```


## 🚦 Building Firmware for ESP32

### **A. First Test: Hello World**

```bash
cd ~/zephyrproject/zephyr
west build -p always -b esp32_devkitc/esp32/procpu samples/hello_world
west flash --esp-device /dev/ttyUSB0 --esp-baud-rate 115200
```


### **B. WiFi — Industrial-Fast**

Build and flash the WiFi shell demo:

```bash
west build -p always -b esp32_devkitc/esp32/procpu samples/net/wifi/shell
west flash --esp-device /dev/ttyUSB0 --esp-baud-rate 115200
```


## 🐚 Using the Zephyr Shell Like a Pro

Open the Zephyr shell after flashing:

```bash
west espressif monitor
# Or, if you prefer screen/minicom:
screen /dev/ttyUSB0 115200
```

**Try these commands:**


| Command | What it does |
| :-- | :-- |
| `help` | List available commands |
| `kernel version` | Zephyr version |
| `device list` | All detected hardware devices |
| `wifi scan` | Scan nearby WiFi networks |
| `wifi connect -s SSID -p PASS -k 1` | Connect to WPA2-PSK WiFi |
| `wifi status` | Connection status |
| `net iface` | Show network interfaces |
| `net ping 8.8.8.8` | Test internet access (if routed) |
| `wifi ap enable -s DEMO_AP -p DEMOPASS -c 6 -k 1` | Start Access Point |
| `wifi version` | Driver \& firmware versions |

## ⚡️ Troubleshooting \& Pro Tips

| Error/Problem | How to Fix |
| :-- | :-- |
| Board not found / CMake errors | Use correct board name: `esp32_devkitc/esp32/procpu` |
| "Could not find Zephyr-SDK"/cmake errors | Check/install full Zephyr SDK, set SDK var |
| Serial permission denied | Add user to `dialout` group \& re-login |
| Device/busy/flash failures | `sudo fuser -k /dev/ttyUSB0` or unplug USB |
| Flash too fast (errors) | Add `--esp-baud-rate 115200` to `west flash` |
| "Set CONFIG_NET_STATISTICS_WIFI..." message | Ignore, or build with stats config for wifi |
| AP/Connect doesn’t work (WPA2) | Always specify `-k 1` for WPA2-PSK |
| Overlay errors, blinky sample fails | Use the correct device tree overlay for LED setup |

## 🧩 Common Device Tree Overlay (for Blinky example)

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

Create as `samples/basic/blinky/boards/esp32_devkitc/esp32_devkitc_procpu.overlay`.

## 🚀 Next Level: Your EdgeHax Board

**Want to add 4G/LTE (A7672S) and NavIC support?**

- Fork this repo.
- Add new board definition under `boards/edgehax/`.
- Document all GPIO/UART/power connections for 4G and NavIC.
- Add shell commands for `4g` and `navic`.
- Market as the only professional “Make in India” NavIC-edge IoT platform!


## 📝 README Template Structure (for your GitHub)

```markdown
# Zephyr RTOS for ESP32/EdgeHax
## Introduction
## Prerequisites
## Step-by-Step Setup
## Building and Flashing Firmware
## Zephyr Shell Usage
## Example Output
## Networking & WiFi Commands
## Device Tree Customizations
## Troubleshooting
## Next Steps for Custom Hardware (EdgeHax)
## Contributor Guide / License
```


## 🏁 Final Pro Tip

**Always use `west build -p always ...` when switching between samples or after any errors.**
Document every custom overlay, shell command, and issue you encounter—they add real value for commercial support and future development!

**You’re now ready to ship industrial, professional, and scalable ESP32 solutions with Zephyr RTOS—no more “Arduino limitations”!**
Happy Hacking and Market Dominating! 🚀

