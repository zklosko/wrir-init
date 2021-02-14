#!/bin/bash

#Pull schedule on script start
cd /srv/recorder
mkdir archive && mkdir raw
./getsched17.sh  #removed & from command

while true
do
  cd /srv/recorder
  date -R
  ./whatson4.sh &  # sending to background
  ./posted.sh &
  ./getInfo2.sh &
  ./Publish.sh &
  
  #At 10 minutes to, get the new schedule, run cleanup. xx:50
  sMinuteHand=$(date +%M)
  if [[ ${sMinuteHand} -eq 50 ]]  # was if [[ 10${sMinuteHand} -eq 50 ]]
  then
    ./getsched17.sh &
    ./lsdb2.sh &
    #bash ./Cleaner.sh &
  fi

  #Recheck at top of minute xx:xx:00
  sSecondHand=$(date "+%S")
  sleep $(( 60 - ${sSecondHand} ))  # was sleep $(( 60 - 10#${sSecondHand} ))
done
