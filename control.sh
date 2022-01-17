#!/bin/bash

ip_list=()

DEFAULT_ADB_CLIENT_PORT=5555

function get_ips() {
    ip_addresses=$( echo ${ADB_CLK_IPS} | tr -d '"')

    for ip_address in ${ip_addresses}
    do

        num_valid_parts=0
        parts=$( echo ${ip_address} | tr "." " ")
        # check 4 parts for validity
        for part in ${parts}; do
            if [[ "${part}" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]
            then
                num_valid_parts=$(( num_valid_parts+=1 ))
            fi
        done

        if [ ${num_valid_parts} -eq 4 ]
        then
            echo "Valid IP address ${ip_address} was detected."
            ip_list+=( ${ip_address} )
        else
            echo "IP address ${ip_address} does not seem valid."
        fi

    done
}

function check_ips() {
    get_ips
    if [ ${#ip_list[@]} -eq 0 ]
    then
        echo "No valid IPs detected."
        exit 1
    fi
}

function start() {
    get_ips
    echo "Starting ADB server..."
    adb -a -P 5037 server nodaemon &

    sever_wait=5
    connect_retry=10

    echo "Waiting ${sever_wait} seconds for the server to start."
    sleep ${sever_wait}

    while true
    do

        echo "Looking clients for connection..."
        for ip in ${ip_list[@]}
        do

            is_connected=$(adb devices | awk '$2 == "device" { print $1; }' | awk -F ":" '{print $1}' | grep "${ip}")
            if [ ${is_connected} = ${ip} ]
            then
                echo "ADB server already connected to client ${ip}."
            else    
                echo "Connecting to ${ip} with port ${DEFAULT_ADB_CLIENT_PORT}."
                adb connect ${ip}:${DEFAULT_ADB_CLIENT_PORT}
            fi

        done

        echo "Waiting ${connect_retry} seconds for the next reconnect."
        sleep ${connect_retry}
    done
}

function stop() {

    echo "Stopping ADB server..."
    adb kill-server

}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
esac
