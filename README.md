# GQRX-RTL-SDR-for-Raspberry-Pi

GQRX + RTL-SDR Build Script for Raspberry Pi which Supports Blog V4 / R828D RTL-SDR

## What it does

This bash script bundles the necessary command line entries to:

1. Install the latest RTL-SDR V4 dongle drivers on linux as per https://www.rtl-sdr.com/V4/.

2. Build and install gr-osmosdr from source via https://gitea.osmocom.org/sdr/gr-osmosdr.

3. Build and install GQRX from source via https://github.com/gqrx-sdr/gqrx.git.

Provided installation is done in this order, with these commands, GQRX + V4 RTL-SDR dongle will "just work" on the Raspberry Pi.

## How to install

```BASH
cd ~
sudo rm -rf GQRX-RTL-SDR-for-Raspberry-Pi
git clone https://github.com/captainchapster/GQRX-RTL-SDR-for-Raspberry-Pi.git
cd GQRX-RTL-SDR-for-Raspberry-Pi
sudo chmod +x install.sh
./install.sh
```

This will produce an sdr-build directory in ~ at which point GQRX-RTL-SDR-for-Raspberry-Pi can be removed if you desire.
