#!/bin/bash
# ==============================================
# Automated Build Script: GQRX + RTL-SDR Blog V4
# Raspberry Pi (supports V4 / R828D dongles)
# ==============================================

set -e
set -o pipefail

# Number of parallel make jobs
JOBS=$(nproc)
BUILDROOT="$HOME/sdr-build"

echo "=== RTL-SDR Blog V4 Build Script ==="
echo "Build directory: $BUILDROOT"
echo "Using $JOBS parallel jobs"

# -----------------------------------------------------
# Install dependencies
# -----------------------------------------------------
echo "=== 0. Installing build dependencies ==="
sudo apt-get update
sudo apt-get install -y \
    git cmake build-essential pkg-config libusb-1.0-0-dev \
    libqt5core5a libqt5gui5 libqt5widgets5 qttools5-dev qttools5-dev-tools \
    libpulse-dev libfftw3-dev libqt5svg5-dev

# -----------------------------------------------------
# Blacklist DVB-T kernel drivers
# -----------------------------------------------------
echo "=== 1. Blacklisting DVB-T drivers ==="
BLACKLIST_FILE="/etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf"
if ! grep -q "blacklist dvb_usb_rtl28xxu" "$BLACKLIST_FILE" 2>/dev/null; then
    echo "blacklist dvb_usb_rtl28xxu" | sudo tee -a "$BLACKLIST_FILE"
    echo "DVB-T driver blacklisted."
else
    echo "DVB-T driver already blacklisted."
fi

# -----------------------------------------------------
# Create build root
# -----------------------------------------------------
mkdir -p "$BUILDROOT"
cd "$BUILDROOT"

# -----------------------------------------------------
# 2. Build RTL-SDR from source
# -----------------------------------------------------
echo "=== 2. Building RTL-SDR from source ==="
if [[ -d rtl-sdr ]]; then
    cd rtl-sdr
    git pull
else
    git clone https://github.com/osmocom/rtl-sdr
    cd rtl-sdr
fi

rm -rf build
mkdir build && cd build
cmake .. -DINSTALL_UDEV_RULES=ON
make -j"$JOBS"
sudo make install
sudo ldconfig

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# -----------------------------------------------------
# 3. Build gr-osmosdr
# -----------------------------------------------------
echo "=== 3. Building gr-osmosdr ==="
cd "$BUILDROOT"
if [[ -d gr-osmosdr ]]; then
    cd gr-osmosdr
    git pull
else
    git clone https://gitea.osmocom.org/sdr/gr-osmosdr
    cd gr-osmosdr
fi

rm -rf build
mkdir build && cd build
cmake .. -DENABLE_BLADERF=OFF -DCMAKE_BUILD_TYPE=Release
make -j"$JOBS"
sudo make install
sudo ldconfig

# -----------------------------------------------------
# 4. Build GQRX
# -----------------------------------------------------
echo "=== 4. Building GQRX ==="
cd "$BUILDROOT"
if [[ -d gqrx ]]; then
    cd gqrx
    git pull
else
    git clone https://github.com/gqrx-sdr/gqrx.git
    cd gqrx
fi

rm -rf build
mkdir build && cd build
cmake ..
make -j"$JOBS"
sudo make install

# -----------------------------------------------------
# 5. Test RTL-SDR and GQRX
# -----------------------------------------------------
echo "=== 5. Testing RTL-SDR ==="
if rtl_test -t; then
    echo "RTL-SDR detected successfully!"
else
    echo "WARNING: RTL-SDR not detected."
fi

echo "=== DONE: GQRX + RTL-SDR V4 built successfully! ==="
echo "Reboot your Pi or unplug/replug your RTL-SDR dongle before running GQRX."
