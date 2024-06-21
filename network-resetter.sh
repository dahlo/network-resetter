#!/bin/bash

# Default values
INTERFACE="wlan0"
PING_ADDRESS="8.8.8.8"
REBOOT_WAIT_TIME=3600 # 1 hour in seconds

# Display usage information
usage() {
    echo "Usage: $0 [-i interface] [-a address-to-ping] [-t seconds-between-reboots]"
    echo "  -i  Network interface to restart (default: wlan0)"
    echo "  -a  Address to ping for internet connectivity (default: 8.8.8.8)"
    echo "  -t  Time in seconds to wait between reboots (default: 3600 seconds)"
    echo "  -h  Print this help message"
    exit 1
}

# Function to restart network interface
restart_interface() {
    if command -v ifdown > /dev/null 2>&1; then
        # Using ifdown/ifup
        echo "Restarting network interface using ifdown/ifup..."
        /sbin/ifdown ${INTERFACE} && /sbin/ifup ${INTERFACE}
    elif command -v nmcli > /dev/null 2>&1; then
        # Using nmcli
        echo "Restarting network interface using nmcli..."
        nmcli device down ${INTERFACE} && nmcli device up ${INTERFACE}
    else
        echo "No suitable command found to restart network interface"
        exit 1
    fi
}

# Parse arguments
while getopts "i:a:t:h" opt; do
  case ${opt} in
    i )
      INTERFACE=$OPTARG
      ;;
    a )
      PING_ADDRESS=$OPTARG
      ;;
    t )
      REBOOT_WAIT_TIME=$OPTARG
      ;;
    h )
      usage
      ;;
    \? )
      usage
      ;;
  esac
done

# Check for internet connectivity
ping -c 1 ${PING_ADDRESS} > /dev/null 2>&1

if [ $? -ne 0 ]; then
    # No internet, attempt to restart network interface
    echo "No internet, attempting to restart network interface..."
    restart_interface
    
    # Wait for 20 seconds before checking connectivity again
    sleep 20

    # Check internet connectivity again
    ping -c 1 ${PING_ADDRESS} > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "No internet after restart, checking reboot history..."
        
        CURRENT_TIME=$(date +%s)
        REBOOT_ATTEMPT_FILE="/tmp/last_reboot_attempt"

        if [ -f $REBOOT_ATTEMPT_FILE ]; then
            LAST_ATTEMPT=$(cat $REBOOT_ATTEMPT_FILE)

            # Check if the last reboot attempt was longer than REBOOT_WAIT_TIME ago
            if [ $((CURRENT_TIME - LAST_ATTEMPT)) -ge $REBOOT_WAIT_TIME ]; then
                echo "Rebooting the system due to prolonged internet outage..."
                date +%s > $REBOOT_ATTEMPT_FILE
                /sbin/reboot
            else
                echo "Reboot attempt was made less than $REBOOT_WAIT_TIME seconds ago. Skipping."
            fi
        else
            echo "First reboot attempt recorded, rebooting now..."
            date +%s > $REBOOT_ATTEMPT_FILE
            /sbin/reboot
        fi
    else
        echo "Internet connectivity restored after restarting the interface."
    fi
else
    echo "Internet is connected."
fi
