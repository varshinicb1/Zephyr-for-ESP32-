#!/bin/bash
# Zephyr RTOS ESP32 Automated Setup Script
# Based on successful Ubuntu 22.04 installation process
# Version: 1.0
# Date: August 2025

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_warning "This script is tested on Ubuntu 22.04. Other distributions may need modifications."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    sudo apt update && sudo apt upgrade -y
    
    sudo apt install -y --no-install-recommends \
        git cmake ninja-build gperf ccache dfu-util \
        device-tree-compiler wget python3-dev python3-pip \
        python3-setuptools python3-tk python3-wheel \
        xz-utils file make gcc gcc-multilib g++-multilib \
        libsdl2-dev libmagic1
    
    print_success "System dependencies installed"
}

# Function to add user to dialout group
setup_serial_permissions() {
    print_status "Setting up serial port permissions..."
    
    sudo usermod -aG dialout $USER
    
    print_warning "User added to dialout group. You MUST log out and log back in for this to take effect!"
    print_warning "The script will continue, but flashing may fail until you restart your session."
}

# Function to setup Python environment
setup_python_env() {
    print_status "Setting up Python virtual environment..."
    
    # Create zephyrproject directory if it doesn't exist
    mkdir -p ~/zephyrproject
    
    # Create virtual environment
    python3 -m venv ~/zephyrproject/.venv
    
    # Activate virtual environment
    source ~/zephyrproject/.venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install west
    pip install west
    
    print_success "Python environment set up"
}

# Function to get Zephyr source
get_zephyr_source() {
    print_status "Getting Zephyr source code..."
    
    cd ~/zephyrproject
    
    # Initialize west workspace (skip if already exists)
    if [ ! -f ".west/config" ]; then
        west init .
    else
        print_status "West workspace already initialized"
    fi
    
    # Update repositories
    west update
    
    # Export Zephyr environment
    west zephyr-export
    
    # Install Python requirements
    source .venv/bin/activate
    pip install -r zephyr/scripts/requirements.txt
    
    print_success "Zephyr source code downloaded and configured"
}

# Function to install Zephyr SDK
install_zephyr_sdk() {
    print_status "Installing Zephyr SDK..."
    
    cd ~
    
    # Check if SDK already exists
    if [ -d "zephyr-sdk-0.17.2" ]; then
        print_status "Zephyr SDK already installed"
        return
    fi
    
    # Download SDK (check if file exists)
    if [ ! -f "zephyr-sdk-0.17.2_linux-x86_64.tar.xz" ]; then
        print_status "Downloading Zephyr SDK (this may take a while)..."
        wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.2/zephyr-sdk-0.17.2_linux-x86_64.tar.xz
    fi
    
    # Extract SDK
    print_status "Extracting SDK..."
    tar xf zephyr-sdk-0.17.2_linux-x86_64.tar.xz
    
    # Run setup
    cd zephyr-sdk-0.17.2
    ./setup.sh
    
    # Add to bashrc if not already there
    if ! grep -q "ZEPHYR_SDK_INSTALL_DIR" ~/.bashrc; then
        echo 'export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.2"' >> ~/.bashrc
        print_status "SDK path added to ~/.bashrc"
    fi
    
    # Source the environment
    export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.2"
    
    print_success "Zephyr SDK installed"
}

# Function to test the installation
test_installation() {
    print_status "Testing installation with Hello World build..."
    
    cd ~/zephyrproject/zephyr
    source ../.venv/bin/activate
    
    # Try to build hello_world for ESP32
    if west build -p always -b esp32_devkitc/esp32/procpu samples/hello_world; then
        print_success "Build test SUCCESSFUL! Installation is working correctly."
        print_status "Build output is in: ~/zephyrproject/zephyr/build/"
    else
        print_error "Build test FAILED! Check the output above for errors."
        return 1
    fi
}

# Function to create helper scripts
create_helper_scripts() {
    print_status "Creating helper scripts..."
    
    # Create environment activation script
    cat > ~/zephyr-env.sh << 'EOF'
#!/bin/bash
# Zephyr Environment Activation Script
cd ~/zephyrproject/zephyr
source ../.venv/bin/activate
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.2"
echo "Zephyr environment activated!"
echo "Current directory: $(pwd)"
echo "Python virtual environment: activated"
echo "SDK path: $ZEPHYR_SDK_INSTALL_DIR"
EOF
    chmod +x ~/zephyr-env.sh
    
    # Create quick build and flash script
    cat > ~/zephyr-flash.sh << 'EOF'
#!/bin/bash
# Quick Zephyr Build and Flash Script
# Usage: ./zephyr-flash.sh [sample_path] [board] [device]
# Example: ./zephyr-flash.sh samples/hello_world esp32_devkitc/esp32/procpu /dev/ttyUSB0

SAMPLE=${1:-samples/hello_world}
BOARD=${2:-esp32_devkitc/esp32/procpu}
DEVICE=${3:-/dev/ttyUSB0}

echo "Building: $SAMPLE for $BOARD"
echo "Will flash to: $DEVICE"

cd ~/zephyrproject/zephyr
source ../.venv/bin/activate
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.2"

# Kill any processes using the serial port
sudo fuser -k $DEVICE 2>/dev/null || true

# Build
if west build -p always -b $BOARD $SAMPLE; then
    echo "Build successful! Flashing..."
    # Flash
    if west flash --esp-device $DEVICE --esp-baud-rate 115200; then
        echo "Flash successful! Starting monitor..."
        echo "Press Ctrl+C to exit monitor"
        sleep 2
        west espressif monitor
    else
        echo "Flash failed! Try holding BOOT button and pressing EN button on your ESP32"
    fi
else
    echo "Build failed!"
    exit 1
fi
EOF
    chmod +x ~/zephyr-flash.sh
    
    print_success "Helper scripts created:"
    print_status "  ~/zephyr-env.sh - Activate Zephyr environment"
    print_status "  ~/zephyr-flash.sh - Quick build and flash"
}

# Function to display final instructions
show_final_instructions() {
    print_success "=== ZEPHYR RTOS SETUP COMPLETE! ==="
    echo
    print_status "Quick Start Commands:"
    echo "  1. Connect your ESP32 board via USB"
    echo "  2. Activate environment: source ~/zephyr-env.sh"
    echo "  3. Build and flash: ~/zephyr-flash.sh samples/hello_world esp32_devkitc/esp32/procpu /dev/ttyUSB0"
    echo
    print_status "Manual Commands:"
    echo "  cd ~/zephyrproject/zephyr"
    echo "  source ../.venv/bin/activate"
    echo "  west build -p always -b esp32_devkitc/esp32/procpu samples/hello_world"
    echo "  west flash --esp-device /dev/ttyUSB0 --esp-baud-rate 115200"
    echo "  west espressif monitor"
    echo
    print_status "Common ESP32 Board Targets:"
    echo "  esp32_devkitc/esp32/procpu      - Standard ESP32 DevKitC"
    echo "  esp32s3_devkitc/esp32s3/procpu  - ESP32-S3 DevKitC"
    echo "  esp32c3_devkitm/esp32c3         - ESP32-C3 DevKitM"
    echo
    print_warning "IMPORTANT: Remember to log out and log back in for serial port permissions!"
    echo
    print_status "Sample Applications to Try:"
    echo "  samples/hello_world                        - Basic test"
    echo "  samples/basic/blinky                       - LED control"
    echo "  samples/boards/espressif/deep_sleep        - Power management"
    echo "  samples/net/wifi/shell                     - WiFi capabilities"
    echo "  samples/bluetooth/beacon                   - Bluetooth"
    echo
    print_success "Happy coding with Zephyr RTOS! 🚀"
}

# Main installation function
main() {
    print_status "Starting Zephyr RTOS ESP32 Setup..."
    echo
    
    check_not_root
    check_ubuntu
    
    install_system_deps
    setup_serial_permissions
    setup_python_env
    get_zephyr_source
    install_zephyr_sdk
    
    if test_installation; then
        create_helper_scripts
        show_final_instructions
    else
        print_error "Installation completed but build test failed!"
        print_error "Please check the error messages above."
        exit 1
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
