#!/bin/bash
# ==============================================
# GQRX + RTL-SDR Build Script for Raspberry Pi
# Supports Blog V4 / R828D RTL-SDR
# ==============================================

set -e
set -o pipefail

JOBS=$(nproc)
BUILDROOT="$HOME/sdr-build"

echo "=== 1. Unhold any held RTL-SDR packages ==="
sudo apt-mark unhold rtl-sdr librtlsdr0 librtlsdr-dev || true

echo "=== 2. Purge old RTL-SDR packages ==="
sudo apt purge -y rtl-sdr librtlsdr0 librtlsdr-dev \
    gr-osmosdr libgnuradio-osmosdr* || true

echo "=== 3. Remove old source-installed libraries ==="
sudo rm -rf /usr/local/lib/librtlsdr* /usr/local/bin/rtl_* /usr/local/include/rtl-sdr* /usr/local/include/rtl_*
sudo ldconfig

echo "=== 4. Install build dependencies ==="
sudo apt update
sudo apt install -y \
    libusb-1.0-0-dev git cmake pkg-config build-essential \
    gnuradio-dev \
    qt6-base-dev qt6-svg-dev qt6-wayland \
    libasound2-dev libjack-jackd2-dev portaudio19-dev libpulse-dev

echo "=== 5. Blacklist DVB driver ==="
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf
sudo udevadm control --reload-rules
sudo udevadm trigger

# -----------------------------------------------------
# RTL-SDR
# -----------------------------------------------------
echo "=== 6. Build RTL-SDR from source ==="
mkdir -p "$BUILDROOT"
cd "$BUILDROOT"
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
sudo cp ../rtl-sdr.rules /etc/udev/rules.d/
sudo ldconfig
sudo udevadm control --reload-rules
sudo udevadm trigger

# -----------------------------------------------------
# gr-osmosdr
# -----------------------------------------------------
echo "=== 7. Build gr-osmosdr from source ==="
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
cmake ..
make -j"$JOBS"
sudo make install
sudo ldconfig

# -----------------------------------------------------
# GQRX
# -----------------------------------------------------
echo "=== 8. Build GQRX ==="
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
# Test
# -----------------------------------------------------
echo "=== 9. Testing configuration ==="
rtl_test -t
ldd $(which gqrx) | grep rtl

echo "=== DONE: GQRX + RTL-SDR built successfully! ==="
echo "Reboot your Pi or unplug/replug your RTL-SDR dongle before running GQRX."