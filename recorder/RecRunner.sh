#!/bin/bash

function cleaner() {
    # args: number of days
    find /recorder/raw/* -ctime +$1 -delete
}

cd /recorder
date -R
./whatson4.sh &  
sleep 30
./posted.sh  # none -> .new + .publish
./getInfo2.sh  # .new -> .info
./Publish.sh  # .publish -> .tfr -> .done
./getsched17.sh
cleaner 1