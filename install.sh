#!/bin/bash
# ==============================================
# GQRX + RTL-SDR Build Script for Raspberry Pi
# Supports Blog V4 / R828D RTL-SDR
# ==============================================

set -e
set -o pipefail

JOBS=$(nproc)

echo "=== 0. Sanity checks ==="
if [[ $EUID -eq 0 ]]; then
    echo "Do NOT run this script as root."
    exit 1
fi

echo "=== 1. Install build dependencies (idempotent) ==="
sudo apt update
sudo apt install -y \
    git cmake pkg-config build-essential \
    libusb-1.0-0-dev \
    gnuradio-dev gr-osmosdr \
    qt6-base-dev qt6-svg-dev qt6-wayland \
    libasound2-dev libjack-jackd2-dev \
    portaudio19-dev libpulse-dev

echo "=== 2. Blacklist DVB driver (safe overwrite) ==="
sudo tee /etc/modprobe.d/rtl-sdr-blacklist.conf >/dev/null <<'EOF'
blacklist dvb_usb_rtl28xxu
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

BUILDROOT="$HOME/sdr-build"
mkdir -p "$BUILDROOT"

# -----------------------------------------------------
# RTL-SDR
# -----------------------------------------------------
echo "=== 3. Build rtl-sdr from source ==="
cd "$BUILDROOT"

if [[ -d rtl-sdr ]]; then
    echo "Updating existing rtl-sdr source..."
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

# Install udev rules safely
if [[ -f ../rtl-sdr.rules ]]; then
    sudo install -m 644 ../rtl-sdr.rules /etc/udev/rules.d/
fi

sudo udevadm control --reload-rules
sudo udevadm trigger

# -----------------------------------------------------
# gr-osmosdr
# -----------------------------------------------------
echo "=== 4. Build gr-osmosdr from source ==="
cd "$BUILDROOT"

if [[ -d gr-osmosdr ]]; then
    echo "Updating existing gr-osmosdr source..."
    cd gr-osmosdr
    git pull
else
    git clone https://gitea.osmocom.org/sdr/gr-osmosdr
    cd gr-osmosdr
fi

rm -rf build
mkdir build && cd build
cmake ..
make -j"$JOBS"
sudo make install
sudo ldconfig

# -----------------------------------------------------
# GQRX
# -----------------------------------------------------
echo "=== 5. Build GQRX ==="
cd "$BUILDROOT"

if [[ -d gqrx ]]; then
    echo "Updating existing GQRX source..."
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

echo "=== 6. Verification ==="
echo "Testing rtl-sdr device detection..."
rtl_test || true

echo
echo "======================================"
echo " GQRX + RTL-SDR build complete!"
echo " You may need to log out or reboot."
echo "======================================"