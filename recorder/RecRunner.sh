#!/bin/bash

#Pull schedule on script start, pass to publish directory for json container
bash ./getsched17.sh  #removed & from command

while true
do
  date -R
  
  bash ./whatson4.sh &  # sending to background
  bash ./posted.sh &
  bash ./getInfo2.sh &
  bash ./Publish.sh &
  
  #At 10 minutes to, get the new schedule, run cleanup. xx:50
  sMinuteHand=$(date +%M)
  if [[ ${sMinuteHand} -eq 50 ]]  # was if [[ 10${sMinuteHand} -eq 50 ]]
  then
    bash ./getsched17.sh &
    bash ./Cleaner.sh &
  fi

  #Recheck at top of minute xx:xx:00
  sSecondHand=$(date "+%S")
  sleep $(( 60 - ${sSecondHand} ))  # was sleep $(( 60 - 10#${sSecondHand} ))
done
