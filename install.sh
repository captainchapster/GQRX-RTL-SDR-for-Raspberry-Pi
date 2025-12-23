#!/bin/bash
# ==============================================
# GQRX + RTL-SDR Build Script for Raspberry Pi
# Supports Blog V4 / R828D RTL-SDR
# ==============================================

set -e  # Exit on error
set -o pipefail

echo "=== 1. Remove old RTL-SDR packages and files ==="
sudo apt purge -y ^librtlsdr
sudo rm -rvf /usr/lib/librtlsdr* \
            /usr/include/rtl-sdr* \
            /usr/local/lib/librtlsdr* \
            /usr/local/include/rtl-sdr* \
            /usr/local/include/rtl_* \
            /usr/local/bin/rtl_*

echo "=== 2. Install build dependencies ==="
sudo apt-get update
sudo apt-get install -y libusb-1.0-0-dev git cmake pkg-config build-essential \
                        cmake gnuradio-dev gr-osmosdr qt6-base-dev qt6-svg-dev qt6-wayland \
                        libasound2-dev libjack-jackd2-dev portaudio19-dev libpulse-dev

echo "=== 3. Build and install rtl-sdr from source ==="
cd ~
git clone https://github.com/osmocom/rtl-sdr
cd rtl-sdr
mkdir -p build && cd build
cmake ../ -DINSTALL_UDEV_RULES=ON
make -j$(nproc)
sudo make install
sudo cp ../rtl-sdr.rules /etc/udev/rules.d/
sudo ldconfig

echo "=== 4. Blacklist the DVB kernel driver ==="
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

echo "=== 5. Hold rtl-sdr packages to prevent overwrite ==="
sudo apt-mark hold rtl-sdr librtlsdr0 librtlsdr-dev

echo "=== 6. Build and install gr-osmosdr ==="
cd ~
git clone https://gitea.osmocom.org/sdr/gr-osmosdr
cd gr-osmosdr
mkdir -p build && cd build
cmake ../
make -j$(nproc)
sudo make install
sudo ldconfig

echo "=== 7. Build and install GQRX ==="
cd ~
git clone https://github.com/gqrx-sdr/gqrx.git
cd gqrx
mkdir -p build && cd build
cmake ..
make -j$(nproc)
sudo make install

echo "=== DONE: GQRX + RTL-SDR built successfully! ==="
echo "Reboot your Pi or unplug/replug your RTL-SDR dongle before running GQRX."
