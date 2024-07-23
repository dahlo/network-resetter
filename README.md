# network-resetter

Script to reset a network interface if there is no internet connection. If it doesn't work after that it will reboot the computer. 

## Usage

```bash
network-resetter.sh [-h] [-i <network if name>] [-a <address to ping>] [-t <min time between reboots>]
ex.
network-resetter.sh
network-resetter.sh -i wlp58s0 -a 123.123.123.123 -t 7200

Usage: ./network-resetter.sh [-i interface] [-a address-to-ping] [-t seconds-between-reboots]
  -i  Network interface to restart (default: wlan0)
  -a  Address to ping for internet connectivity (default: 8.8.8.8)
  -t  Time in seconds to wait between reboots (default: 3600 seconds)
  -h  Print this help message
```

Set a crontab that runs every minute to ensure internet connectivity:

```bash
# m h  dom mon dow   command
* * * * * /path/to/network-resetter/network-resetter.sh -i wlp1s0 -a 192.168.1.1 > /dev/null
```

Any problems with the internet connection will be printed to `stderr`. Remove the `> /dev/null` to see also the all-ok message that gets printed to `stdout`, but since it runs every minute it will fill your log files quickly.
