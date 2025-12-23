# GQRX-RTL-SDR-for-Raspberry-Pi

GQRX + RTL-SDR Build Script for Raspberry Pi which Supports Blog V4 / R828D RTL-SDR

# What it does

This bash script bundles the necessary command line entries to:

1. Install the latest RTL-SDR V4 dongle drivers on linux as per https://www.rtl-sdr.com/V4/.

2. Issue a command to hold these packages to prevent future overwrites/updates.

3. Build and install gr-osmosdr from source via https://gitea.osmocom.org/sdr/gr-osmosdr.

4. Build and install GQRX from source via https://github.com/gqrx-sdr/gqrx.git.

Provided installation is done in this order, with these commands, GQRX + V4 RTL-SDR dongle will "just work" on the Raspberry Pi.
