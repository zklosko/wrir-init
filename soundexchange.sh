#!/bin/bash

#sLogs=/var/log/icecast2/access.log
#don't forget about logrotated .gs files

#96.253.116.23 - - [11/Feb/2018:07:40:47 -0500] "GET /WRIR96kbps HTTP/1.1" 200 505709 "http://wrir.org/listen/" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36" 37
#173.53.41.149 - - [11/Feb/2018:07:49:03 -0500] "GET /WRIR96kbps HTTP/1.1" 200 150869 "http://wrir.org/listen/" "Mozilla/5.0 (iPhone; CPU iPhone OS 11_2_5 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) CriOS/63.0.3239.73 Mobile/15D60 Safari/604.1" 51


#date: invalid date ‘18/Feb/2018 12:44:57 -0500’
#Log file submissions need to include
#                IP Address:  #.#.#.#
#                Date:  YYYY-MM-DD
#                Start time:  HH:MM:SS
#                Stream name:  Free text with no spaces (eg. /WEST)
#                Duration:  Seconds
#                HTTP Status Code:  200
#                Referrer/Client:  Free text  - spaces are fine

sMounts=(WRIR96kbps wrir)

sAnnaDate="2021-02-01"

sRangeStart=$(date "+%s" -d "${sAnnaDate}")
sRangeEnd=$(date "+%s" -d "${sAnnaDate} + 14 days")

for sL in /var/log/icecast2/access*
do

for sMount in ${sMounts[*]}
do
  echo ${sMount}
  sGrep=grep
  [[ ${sL: -2} == "gz" ]] && sGrep=zgrep
  ${sGrep} "GET /${sMount} " ${sL} |
  while read sLine
  do
    sIP=${sLine%% *}
    sDT=${sLine%%]*}
    sDT=${sDT#*[}
    sDate=${sDT:0:11}
#    sDate=${sDate//\//-}
    sEndDate=$(date "+%s" -d "${sDate//\//-} ${sDT:12}")
    sStatus=$(cut -f9 -d' ' <<< "${sLine}")
    sReferrer=$(cut -f11 -d' ' <<< "${sLine}")
    sClient=${sLine##*\"}
    sClient=${sClient%\"*}
    sDur=${sLine##* }
    
    sStartDate=$(( sEndDate - sDur ))

    if [[ ${sStartDate} -gt ${sRangeStart} ]] && [[ ${sStartDate} -le ${sRangeEnd} ]] 
    then
      sRFN="$(date '+%Y-%m-%d' -d @${sStartDate})-${sMount}.txt"
      echo -e "${sIP}\t$(date '+%Y-%m-%d' -d @${sStartDate})\t$(date '+%H:%M:%S' -d @${sStartDate})\tWRIR\t${sDur}\t${sStatus}\t${sReferrer}" | tee -a ${sRFN}
#    else
#      echo "$(date '+%Y-%m-%d' -d @${sStartDate}) is out of range"
    fi
  done
done
done

grep -h -v 127.0.0. *.txt > foranna-${sRangeStart}.txt

