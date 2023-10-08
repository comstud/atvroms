#!/system/bin/sh

# Place in unpacked image at level2/system/system/etc/custom-install.sh with mode 0755.

# Base directory for state, tgz extraction, etc.
base_dir='/sdcard/.custom-install'

# File to look for on mounted media
usb_custom_script="custom.sh"

# File to look for on server OR on USB.
tgz_name="on-boot.tgz"
# Where USB tgz will be extracted
usb_extract_dir="${base_dir}/.usb-install/on-boot"

# Mounted media path to search
media_path='/mnt/media_rw/'

# State file one can use to send stage to server.
run_stage_statefile='/sdcard/.custom-run-stage'

# URL for server installs. Web service must expose /on-boot.tgz handler that
# returns a gzipped tar file (it can be a zip file, too!)  with that name. Inside the tar file should be a
# 'run.sh'. Our mac address will be sent as a query param ('mac'). A
# 'run_stage' param will also be sent. This starts at 0 and is read from
# /sdcard/.run-stage. It is not updated by this script. Your own scripts may
# update it.
net_url='http://atv-installer.local.lan'
# Where to place the net on-boot.tgz.
net_install_dir="${base_dir}/.net-install"
# Where to extract the net on-boot.tgz.
net_extract_dir="${base_dir}/.net-install/on-boot"

setup_dirs() {
    rm -rf "$base_dir"
    mkdir -p "$base_dir"
}

do_log() {
    log -t custom-install "$@"
}

wait_for_usb_drive() {
    local i=0
    local got_drive=0

    do_log 'Waiting for usb drive to be mounted...'
    while [ $i -lt 30 ]; do
        if [ $i -gt 0 ]; then
            sleep 1
        fi
        i=`expr $i + 1`
        ls "$media_path"/* > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            do_log "There's something in '$media_path', so USB drive must be mounted."
            got_drive=1
            break
        fi
    done

    if [ $got_drive -eq 0 ]; then
        do_log "Doesn't seem like usb drive is mounted, let's continue anyway"
    fi
}

extract_and_run() {
    local src="$1"
    local dest="$2"

    rm -rf "$dest"
    mkdir -p "$dest"
    local tar_errors=`tar -C "$dest" -xf "$src" 2>&1`
    if [ $? -eq 0 ]; then
        do_log "Extracted $tgz_name to $dest"
        if [ -f "${dest}/run.sh" ]; then
            do_log 'Running custom run.sh'
            cd "$dest" && /system/bin/sh ./run.sh
        else
            do_log 'No run.sh found.'
        fi
    else
        do_log "$tgz_name failed to extract to $dest: $tar_errors"
    fi
}

check_net_url() {
    # check if we have a server we can use for install.
    do_log "Checking for ${net_url}..."
    ping -c1 -W 5 atv-installer.local.lan > /dev/null 2>&1
    local res=$?
    if [ $res -eq 0 ]; then
        do_log "Found ${net_url} and the IP is pingable. Querying it..."
    fi
    if [ $res -eq 1 ]; then
        do_log "Found ${net_url}, but the IP isn't pingable. Querying it, anyway..."
        res=0
    fi
    if [ $res -eq 0 ]; then
        # Wow, we do! Hit the url looking for the tgz..
        local our_mac=`ip link show eth0 | tail -1 | awk '{ print $2 }'`
        local our_img=`/system/bin/csimgver`
        local run_stage='0'
        if [ -f "$run_stage_statefile" ]; then
            run_stage=`cat "$run_stage_statefile"`
            if [ -z "$run_stage" ]; then
                run_stage='0'
            fi
        fi
        rm -rf "${net_install_dir}"
        mkdir -p "${net_install_dir}"
        rm -f "${net_install_dir}/$tgz_name"
        local curl_errors=`curl -s -f -L -o "${net_install_dir}/$tgz_name" "${net_url}/${tgz_name}?run_stage=$run_stage&mac=$our_mac" 2>&1`
        if [ $? -eq 0 -a -f "${net_install_dir}/$tgz_name" ]; then
            do_log "Found $tgz_name from install server. Extracting it..."
            extract_and_run "${net_install_dir}/$tgz_name" "${net_extract_dir}"
        else
            do_log "Failed to get $tgz_name from server: $curl_errors"
        fi
    else
        do_log "No luck with ${net_url}. Skipping..."
    fi
}

check_usb_drive() {
    wait_for_usb_drive

    sleep 1
    local usbfile=`find "$media_path" -name "$usb_custom_script" | head -n1`
    if [ -n "$usbfile" ]; then
        do_log 'Found '$usb_custom_script' on USB drive. Running it...'
        /system/bin/sh "$usbfile"
    else
        do_log "Did not find '$usb_custom_script' on USB drive. Looking for '$tgz_name', instead."

        usbfile=`find "$media_path" -name "$tgz_name" | head -n1`
        if [ -n "$usbfile" ]; then
            do_log 'Found '$tgz_name' on USB drive. Extracting it...'
            extract_and_run "$usbfile" "${usb_extract_dir}"
        else
            do_log "Did not find '$usb_custom_script' on USB drive."
        fi
    fi
}

check_net_url
check_usb_drive

do_log 'Exiting!'

exit 0
