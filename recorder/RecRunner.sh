#!/bin/bash

#Pull schedule on script start
cd /srv/recorder
mkdir archive && mkdir raw
./getsched17.sh  #removed & from command

while true
do
  cd /srv/recorder
  date -R
  ./whatson4.sh &  
  
  sMinuteHand=$(date +%M)
  #Five minutes after expected show end, tag and convert. xx:05 or xx:35
  if [ ${sMinuteHand} -eq 5 ] || [ ${sMinuteHand} -eq 35 ];
  then
      bash ./posted.sh  # none -> .new + .publish
      bash ./getInfo2.sh  # .new -> .info
      bash ./Publish.sh  # .publish -> .tfr -> .done
  fi
  #At 10 minutes to, get the new schedule, run cleanup. xx:50
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
