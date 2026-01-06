#!/bin/bash
# ==============================================
# GQRX + RTL-SDR Build Script for Raspberry Pi
# Supports Blog V4 / R828D RTL-SDR
# ==============================================

set -e
set -o pipefail

JOBS=$(nproc)
BUILDROOT="$HOME/sdr-build"

# -----------------------------------------------------
# RTL-SDR
# -----------------------------------------------------
echo "=== 1. Build RTL-SDR from source ==="
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
echo "=== 2. Build gr-osmosdr from source ==="
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
cmake .. \
  -DENABLE_BLADERF=OFF \
  -DCMAKE_BUILD_TYPE=Release
make -j"$JOBS"
sudo make install
sudo ldconfig

# -----------------------------------------------------
# GQRX
# -----------------------------------------------------
echo "=== 3. Build GQRX ==="
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
# Purge the previous driver
# -----------------------------------------------------
echo "=== 4. Purge the previous driver ==="
sudo apt purge ^librtlsdr
sudo rm -rvf /usr/lib/librtlsdr* /usr/include/rtl-sdr* /usr/local/lib/librtlsdr* /usr/local/include/rtl-sdr* /usr/local/include/rtl_* /usr/local/bin/rtl_*

# -----------------------------------------------------
# Install the latest drivers
# -----------------------------------------------------
echo "=== 5. Install the latest drivers ==="
sudo apt-get install libusb-1.0-0-dev git cmake pkg-config build-essential
git clone https://github.com/osmocom/rtl-sdr
cd rtl-sdr
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON
make
sudo make install
sudo cp ../rtl-sdr.rules /etc/udev/rules.d/
sudo ldconfig

# -----------------------------------------------------
# Blacklist the DVB-T TV drivers
# -----------------------------------------------------
echo "=== 6. Blacklist the DVB-T TV drivers ==="
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# -----------------------------------------------------
# Test
# -----------------------------------------------------
echo "=== 7. Testing configuration ==="
rtl_test -t
ldd $(which gqrx) | grep rtl

echo "=== DONE: GQRX + RTL-SDR built successfully! ==="
echo "Reboot your Pi or unplug/replug your RTL-SDR dongle before running GQRX."