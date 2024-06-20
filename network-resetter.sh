#!/bin/bash

# Define the network interface (Update this if necessary)
INTERFACE=$1

# Path to a temporary file to store the reboot timestamp
REBOOT_ATTEMPT_FILE="/root/.network-resetter.last_reboot_attempt"

# Reboot cooldown, amount of seconds to wait until rebooting again
REBOOT_COOLDOWN=3600


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

# Checking for internet connectivity
ping -c 1 8.8.8.8 > /dev/null 2>&1

if [ $? -ne 0 ]; then
    # No internet, attempt to restart network interface
    echo "No internet, attempting to restart network interface..."
    restart_interface
    
    # Wait for 20 seconds before checking connectivity again
    sleep 20

    # Check internet connectivity again
    ping -c 1 8.8.8.8 > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "No internet after restart, checking reboot history..."
        
        CURRENT_TIME=$(date +%s)

        if [ -f $REBOOT_ATTEMPT_FILE ]; then
            LAST_ATTEMPT=$(cat $REBOOT_ATTEMPT_FILE)

            # Check if the last reboot attempt was less than an hour ago
            if [ $((CURRENT_TIME - LAST_ATTEMPT)) -ge $REBOOT_COOLDOWN ]; then
                echo "Rebooting the system due to prolonged internet outage..."
                date +%s > $REBOOT_ATTEMPT_FILE
                /sbin/reboot
            else
                echo "Reboot attempt was made less than an hour ago. Skipping."
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
