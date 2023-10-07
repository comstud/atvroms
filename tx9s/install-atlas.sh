#!/system/bin/sh

# Put this alongside custom.sh to install atlas
# related stuff.

cd `dirname $0`

atlas_apk='PokemodAtlas-Public-v22071801.apk'
magisk='/sbin/magisk'
logfile=/sdcard/Download/atlas-install.log

touch "$logfile"
exec >> "$logfile" 2>&1

log() {
    line="`date +'[%Y-%m-%dT%H:%M:%S %Z]'` $@"
    echo "$line"
}

install_package() {
    package="$1"
    apk="$2"
    ver=`dumpsys package "$package" | grep versionName | sed -e 's/ //g' | awk -F= '{ print $2 }'`
    if [ -z "$ver" ]; then
        pm install "$apk"
        log 'Installed Atlas'
    else
        log "$package version $ver already installed. Skipping..."
    fi
}

install_packages() {
    if [ -f "$atlas_apk" ]; then
        install_package com.pokemod.atlas $atlas_apk
    fi
}

setup_root_access() {
    atlas_uid=`dumpsys package com.pokemod.atlas | grep userId= | awk -F= '{ print $2 }'`
    if [ -n "$atlas_uid" ]; then
        $magisk --sqlite "REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($atlas_uid,2,0,1,1);"
        log 'Magisk policy set so that Atlas can become root.'
    else
        log "Uh, where's atlas? I couldn't find it."
        exit 1
    fi
}

install_atlas_json() {
    if [ -f atlas_config.json ]; then
        log 'Installing atlas_cconfigjson'
        mkdir -p /data/local/tmp
        cp atlas_config.json /data/local/tmp/.
    fi
}

install_packages
setup_root_access
install_atlas_json
log 'Done.'
