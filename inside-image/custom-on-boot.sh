#!/system/bin/sh

# Place in unpacked image at level2/system/system/etc/custom-on-boot.sh with mode 0755.

do_log() {
    log -t custom-boot "$@"
}

ensure_shell_root() {
    # If running under magisk, ensure that shell can su
    if [ -f /sbin/magisk -a -f /data/adb/magisk.db ]; then
        shell_uid=`id -u shell`
        /sbin/magisk --sqlite "REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($shell_uid,2,0,1,1);"
    fi
}

wait_for_sdcard() {
    i=0
    while [ $i -lt 20 -a ! -d /sdcard/Download ]; do
        sleep 1
        i=`expr $i + 1`
    done
}

wait_for_network() {
    local i=0
    local got_net=0

    do_log 'Waiting for network to be alive...'
    while [ $i -lt 40 ]; do
        if [ $i -gt 0 ]; then
            sleep 1
        fi
        i=`expr $i + 1`
        ping -c1 -W 5 8.8.8.8 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            do_log 'The network is up!'
            got_net=1
            break
        fi
    done

    if [ $got_net -eq 0 ]; then
        do_log 'Failed to get network. Going to continue, anyway.'
    fi
}

imgver=`/system/bin/csimgver`
do_log "Booted image ${csimgver}."

ensure_shell_root

wait_for_network
wait_for_sdcard

if [ ! -f /sdcard/.no-custom-install ]; then
    do_log '/sdcard/.no-custom-install does not exist. Running custom-install.sh...'
    sh /system/etc/custom-install.sh > /dev/null 2>&1 &
fi

if [ -d /sdcard/.custom-init.d ]; then
    cd /sdcard/.custom-init.d && (
        for x in `ls -1 *.sh`; do
            sh "$x" > /dev/null 2>&1 &
        done
    )
fi

do_log 'Exiting!'

exit 0
