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
