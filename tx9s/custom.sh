#!/system/bin/sh
# version v5

# This sets up a tx9s atv. Put this file and the *.apk and *.zip in here
# on a USB drive. Insert USB drive in the port furthest from the ethernet
# (for Tanix, anyway). Plug in ethernet and power cable. There will be a
# couple of reboots and the USB drive needs to remain inserted at the
# moment. After 5 minutes or so, you should be good to go.
#
# (If you are using a newer firmware image, you can zip or tar everything
# up as on-boot.tgz and throw it on the USB drive.. OR.. serve it from
# a webservice on your LAN with DNS name 'atv-installer.local.lan'.
#
# Alternative method (via adb):
#   * adb push custom.sh *.apk *.zip /sdcard/Download/.#
#   * adb shell sh /sdcard/Download/custom.sh
#   [ reboot will happen -- after this point, you can and need su: ]
#   * adb shell su -c sh /sdcard/Download/custom.sh
# Repeat this last command after it reboots until done.
#
# For either step, things are done when /sdcard/Download/custom-install.log
# says 'DONE'.
#
# KNOWN ISSUES:
#
# * For whatever reason, sometimes the init script that is inside
#   the image is randomly not run on boot. So that means this doesn't run
#   either. Just reboot.
# * Installing Magisk requires opening it, tapping, and rebooting at the
#   right time to avoid getting stuck at bootloader. I suspect the reboot
#   I do sometimes results in a bad install and it has to be repeated. There's
#   a workaround in this code to do this.
# * When everything is done, Play Integrity API Checker fails to get a token
#   from Google. This seems random and temporary. When I check again later,
#   it is passing.
#
# CHANGELOG:
#
# v5: 2023/10/08
# - touch /sdcard/.no-custom-install when done. If running cs5 or newer image,
#   this prevents it from trying to continue to install from net/usb.
# v4: unreleased
# v3:
# - log file is now under /sdcard/.custom-install as install.log
# - changed the check for install-atlas.sh to be install-more.sh. Install what
#   you want.
# - changed name of filename for pogo apk. name it 'pokemongo.apk' and use
#   whatever version you need.
# - fixed type in setting 'immersive.full=*'
#   - this resulted in the display randomly having nav bar and randomly not
#     and tap locations would change.
# - try to coerce playstore into updating if it didn't.
# - moved denylist til later
# v1/v2:
# - initial release

cd `dirname $0`

magisk='/sbin/magisk'
magisk_apk='Magisk.v26.3.apk'
pogo_apk='pokemongo.apk'
integrity_checker_apk='integritychecker.apk'
playintegrity_fix_zip='playintegrityfix.zip'
playintegrity_fix_name=`echo $playintegrity_fix_zip | sed -e 's/\.zip$//'`
logdir=/sdcard/.custom-install
logfile=${logdir}/install.log

wait_for_sdcard() {
    i=0
    while [ $i -lt 20 -a ! -d /sdcard/Download ]; do
        sleep 1
        i=`expr $i + 1`
    done
}

log() {
    line="`date +'[%Y-%m-%dT%H:%M:%S %Z]'` $@"
    echo "$line"
}

do_settings() {
    settings put global policy_control 'immersive.navigation=*'
    settings put global policy_control 'immersive.full=*'
    settings put secure immersive_mode_confirmations confirmed
    settings put global heads_up_enabled 0
    settings put global bluetooth_disabled_profiles 1
    settings put global bluetooth_on 0
    settings put global package_verifier_user_consent -1
}

setup_magisk_denylist() {
    $magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.android.vending','com.android.vending');"
    $magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.google.android.gms','com.google.android.gms');"
    $magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.google.android.gms.setup','com.google.android.gms.setup');"
    $magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.google.android.gsf','com.google.android.gsf');"
    $magisk --sqlite "REPLACE INTO denylist (package_name,process) VALUES('com.nianticlabs.pokemongo','com.nianticlabs.pokemongo');"
}

setup_magisk_settings() {
    # root access for shell:
    shell_uid=`id -u shell`
    $magisk --sqlite "REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($shell_uid,2,0,1,1);"
    # enable zygisk
    $magisk --sqlite "REPLACE INTO settings (key,value) VALUES('zygisk',1);"
    # enable denylist
    $magisk --sqlite "REPLACE INTO settings (key,value) VALUES('denylist',1);"
}

install_package() {
    package="$1"
    apk="$2"
    ver=`dumpsys package "$package" | grep versionName | sed -e 's/ //g' | awk -F= '{ print $2 }'`
    if [ -z "$ver" ]; then
        pm install "$apk"
    else
        log "$package version $ver already installed. Skipping..."
    fi
}

install_packages() {
    if [ -f "$pogo_apk" ]; then
        install_package com.nianticlabs.pokemongo $pogo_apk
    fi
    if [ -f "$integrity_checker_apk" ]; then
        install_package gr.nikolasspyr.integritycheck "$integrity_checker_apk"
    fi
}

install_magisk_app() {
    if [ -f "$magisk_apk" ]; then
        log 'Installing magisk app'
        # this happens on first boot of image.
        pm install -r "$magisk_apk"
        am start com.topjohnwu.magisk/.ui.MainActivity
        # wait for popup saying a reboot is needed to install more things
        sleep 5
        input tap 1850 560
        # Try to beat Magisk's own 5 second timer. Since Magisk takes a
        # couple seconds to prepare before the 5 second timer starts.. our
        # 6 second timer should beat it. This seems to avoid the reboot into
        # recovery that happens sometimes.
        sleep 6
        log 'Rebooting now after magisk app install'
        reboot
    fi
}

install_magisk_modules() {
    if [ -f "$playintegrity_fix_zip" -a ! -d "/data/adb/modules/$playintegrity_fix_name" ]; then
        log 'Installing play integrity fix'
        $magisk --install-module "$playintegrity_fix_zip"
        log 'Rebooting now after installing play integrity fix'
        reboot
    fi
}

repackage_magisk() {
    ver=`dumpsys package com.topjohnwu.magisk | grep versionName | sed -e 's/ //g' | awk -F= '{ print $2 }'`
    if [ -n "$ver" ]; then
        log 'Found magisk package. Attempting to repackage and hide it..'
        output=`am start com.topjohnwu.magisk/.ui.MainActivity 2>&1`
        echo $output
        # ugh. sometimes magisk is hosed. maybe from rebooting too early when installing
        # it initially. But reinstalling seems to fix it.
        echo "$output" | egrep 'Activity class.*does not exist' > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            if [ -f "$magisk_apk" ]; then
                log 'Attempting to reinstall Magisk because it is busted.'
                install_magisk_app
                # not reached. reboot happens.
            fi
        fi
        sleep 5
        # Go to home:
        input tap 39 42
        sleep 2
        # touch settings:
        input tap 1875 75
        sleep 2
        # Touch 'Hide the Magisk app'
        input tap 960 1000
        sleep 2
        # Select 'Magisk' from 'install unknown apps sidebar'
        input tap 1800 475
        sleep 2
        # back up
        input keyevent BACK
        sleep 2
        # Touch 'Hide the Magisk app' again
        input tap 960 1000
        sleep 2
        # Touch OK
        input tap 1875 650
        sleep 2
        # This will take a bit of time and the app will restart
        # and ask if you want shortcut on home screen.
        sleep 30
        # Touch 'OK' to add shortcut.
        input tap 1825 575
        sleep 2
        # Tap 'add automatically'
        input tap 1425 750
        # that's it.
        sleep 1
        input keyevent HOME
        ver=`dumpsys package com.topjohnwu.magisk | grep versionName | sed -e 's/ //g' | awk -F= '{ print $2 }'`
        if [ -n "$ver" ]; then
            log 'Ugh, magisk package is still there, so repackage failed.'
        fi
    fi
}

wait_for_sdcard

mkdir -p "$logdir"
touch "$logfile"
exec >>"$logfile" 2>&1

if [ ! -f "$magisk" ]; then
    log 'What? No /sbin/magisk?'
    exit 1
fi

log 'Booted.'

# Clean up space.
rm -f ../on-boot.tgz

log 'Making sure we do not get pop-ups and junk...'
do_settings

log 'Installing packages...'
install_packages

if [ ! -f /data/adb/magisk.db ]; then
    install_magisk_app
fi

if [ `id -u` -ne 0 ]; then
    log 'Root is needed from this point forward. Re-run as root.'
    exit 1
fi

setup_magisk_settings
repackage_magisk
install_magisk_modules

# try opening playstore to force an update, if it didn't happen. i've had intregity
# check fails until I did this.... No idea if this fixes it. Let's see.
am start com.android.vending/com.google.android.finsky.activities.MainActivity
# give it some time.
sleep 10
input keyevent HOME
# now put our denylist in place. i am not sure why, but when I had it earlier, at
# a time that I had to also update playstore... I found that Magisk did not have
# 2 things checked in the denylist. They did exist if you queried the DB, though!
# What?? So, let's try not putting in place until here. No idea if this fixes it.
setup_magisk_denylist

# Make your own script, and it'll run.
if [ -f install-more.sh ]; then
    /system/bin/sh install-more.sh
fi

# This tells the image to not try to contact net server or use usb drive
# anymore if running cs5 image or newer.
touch /sdcard/.no-custom-install
log 'DONE!'

exit 0
