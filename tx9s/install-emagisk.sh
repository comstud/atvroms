#!/system/bin/sh

# Install eMagisk, if the .zip exists and it's not yet installed.
#
# NOTE: This will normally ask you if you want to install ATVServices,
# but if this runs automatically from custom.sh, you will not see it and
# it will automatically install it after waiting 10 seconds. You may want
# to run this manually after you're done imaging, so you can see and
# answer any prompts. If you do run it manually, it needs to be run as root.
#
# Also: If you want the RDM monitoring, I believe you have to unzip
# the eMagisk zip, edit the emagisk.config, and then re-zip it. Do the same
# thing and remove custom/ATVServices.sh if you don't want it at all.

# Set this to 0 if you don't want the autoreboot after install.
reboot_after_install=1

if [ -f eMagisk-9.4.4-adb-patched.zip ]; then
    if [ ! -d /data/adb/emagisk ]; then
        # Not installed yet.
        magisk --install-module eMagisk-9.4.4-adb-patched.zip
        if [ $reboot_after_install -ne 0 ]; then
            reboot
        fi
    fi
fi
