#!/bin/bash

sRecPID=./
sMe=whatson.pid

#sRecBinary=arecord
sRecBinary=wget

#kill any other instance of me, may have hung
[[ -f ${sRecPID}/${sMe} ]] && kill $(<${sRecPID}/${sMe})
echo $$ > ${sRecPID}/${sMe}

#Work out which schedule to use, either YYYYMMDD if it exists, or Mon, Tue, etc.
sDate=$(date '+%Y%m%d')
sDay=$(date '+%a')
sHour=$(date '+%H%M')

#see if there's a date file, eg for christmas 20131225.txt
sSchedule=${sDate}.txt
[[ -f ${sSchedule} ]] || sSchedule=${sDay}.txt

echo using schedule ${sSchedule}

#Configured to pull from icecast container
sStream=http://192.168.200.35:8000/wrir  # previously http://files.wrir.org:8000/wrir
sSaveTo=./  # saves to workdir

sYesterdaysLast=$(grep -v 2400 $(date "+%a" -d yesterday).txt|tail -1)
sYLS=${sYesterdaysLast:0:4}
sYLP=${sYesterdaysLast:5:99}

#Read the schedule to find what programme, read down until the schedule time is ahead
#and stick with what we have
#Now: 03:10
#0000 Prog1
#0100 Prog2
#0300 Prog3
#0500 Prog4 test 0500 is greater than 0310 so stick with Prog3

sDone=N
while read sStart sTitle && [[ ${sDone} = N ]]
do
#  echo $sTitle
  if [[ 10#${sStart} -gt 10#${sHour} ]]
  then
    echo Current ${sPrevTitle}
# Find the program which is on now identify by start time YYYYMMDDHHMM
    sProg=${sDate}${sPrevStart}
# amend: check for first program of day being continuation from yesterday
    [[ "${sPrevStart}" = "0000" ]] && [[ "${sPrevTitle}" = "${sYLP}" ]] && sProg=$(date '+%Y%m%d' -d yesterday)${sYLS}
# look for a wget recording that identity
    if  ps -ef | grep -v grep | grep ${sRecBinary} | grep -q ${sProg} 
    then
# found? Y Quit. this should occur very frequently
      echo Recording already
# no: maybe it's a new program or the current recorder crashed
    else
# remember an active wget recorder would have caused an exit earlier/already
      sOutFile=${sSaveTo}/${sProg}-${sHour}-${sPrevTitle}.mp3
# look for recorder running, there shouldn't be one. maybe caputure the PID, maybe from the command pattern
# found one? kill it before starting new
      if [[ -f ${sRecPID}/RecPID ]] && ps -p $(<${sRecPID}/RecPID)
      then
        kill $(<${sRecPID}/RecPID)
      fi
      echo $sProg > ${sSaveTo}/currentshow.txt
      #find any other wgets and kill them
      #while sPIds=$(ps -f|grep -v grep|grep ${sRecBinary}) 
      while sPIds=$(ps -C ${sRecBinary} -o pid=)
      do kill $sPIds
      done
# start new recorder for program identity, background it
      wget -q -O ${sOutFile} ${sStream}
      echo $! > ${sRecPID}/RecPID
    fi
    sDone=Y
  else
    sPrevStart=${sStart}
    sPrevTitle=${sTitle}
  fi
done < ${sSchedule}


rm ${sRecPID}/${sMe}  # error here, sees it as .//whatson.pid
