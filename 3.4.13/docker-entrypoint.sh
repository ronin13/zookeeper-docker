#!/bin/bash
# This entrypoint works only with kubernetes, not meant to be run directly.

set -eux

if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R "$ZOO_USER" "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR" "$ZOO_CONF_DIR"
    exec su-exec "$ZOO_USER" "$0" "$@"
fi

CONFIG="$ZOO_CONF_DIR/zoo.cfg"

echo "clientPort=$ZOO_PORT" >> "$CONFIG"
echo "dataDir=$ZOO_DATA_DIR" >> "$CONFIG"
echo "dataLogDir=$ZOO_DATA_LOG_DIR" >> "$CONFIG"

echo "tickTime=$ZOO_TICK_TIME" >> "$CONFIG"
echo "initLimit=$ZOO_INIT_LIMIT" >> "$CONFIG"
echo "syncLimit=$ZOO_SYNC_LIMIT" >> "$CONFIG"

echo "autopurge.snapRetainCount=$ZOO_AUTOPURGE_SNAPRETAINCOUNT" >> "$CONFIG"
echo "autopurge.purgeInterval=$ZOO_AUTOPURGE_PURGEINTERVAL" >> "$CONFIG"
echo "maxClientCnxns=$ZOO_MAX_CLIENT_CNXNS" >> "$CONFIG"

myhostname=$(hostname)

myord=$(cut -d- -f2 <<< $myhostname)
htemp=$(cut -d- -f1 <<< $myhostname)
sdomain=$(hostname -f | cut -d. -f2)
myord=$((myord+1))


for id in ${ZOO_IDS//,/ }; do
    tid=$(( id-1 ))
    if [[ $id -eq $myord ]];then
        echo "server.${id}=0.0.0.0:2888:3888" >> "$CONFIG"
    else
        echo "server.${id}=${htemp}-${tid}.${sdomain}:2888:3888" >> "$CONFIG"
    fi
done

echo $myord > "$ZOO_DATA_DIR/myid"

sleep 2
exec "$@"
