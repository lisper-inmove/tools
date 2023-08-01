#!/bin/bash
logfile=`pwd`"/monitor.log"
logdir=$(dirname "$logfile")
while true; do
    if [ $(du -m "$logfile" | cut -f1) -ge 100 ]; then
        mv "$logfile" "$logfile.$(date +%Y%m%d%H%M%S)"
        touch "$logfile"
    fi
    find "$logdir" -name "monitor.log.*" -mtime +1 -exec rm {} \;
    echo "=========================== `date` =============================" >> "$logfile"
    echo "Memory Usage:" >> "$logfile"
    COLUMNS=200 top -b -n 1 -c -o %MEM | awk 'NR>=8 && NR<=27' >> "$logfile"
    echo "CPU Usage:" >> "$logfile"
    COLUMNS=200 top -b -n 1 -c -o %CPU | awk 'NR>=8 && NR<=27' >> "$logfile"
    sleep 1
done
