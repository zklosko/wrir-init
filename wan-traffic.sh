#!/bin/bash
# Run once an hour?

# wget "http://192.168.200.1/ifstats.php?if=vlan0"
#uptime,in,out
sNow=$(date +%Y%m%d%H%M%S)
sOut=traffic/$(date +%Y%m%d)

sNewLine=$(wget -O - "http://192.168.200.1/ifstats.php?if=wan")

echo ${sNow} ${sNewLine} >> ${sOut}
