#!/bin/bash

# Cleaning files in raw
sDays=1
echo Starting $0 $(date)

find /srv/recorder/raw/* -ctime +${sDays} -delete

# Cleaning files in publish a.k.a. files.wrir.org/shows
# sDir="/srv/static/shows"

# echo "Starting $0 $(date)"

# cd "${sDir}" || exit

# sLimit="95"
# while sPCFree=$(df . --output=pcent|tail -1) && [[ ${sPCFree%\%} -ge ${sLimit} ]]
# do
#   echo "Free space: ${sPCFree}"
#   sDel=$(ls -tr ./ | head -1)
#   echo "delete ${sDel}"
#   rm "${sDel}"
# done

# echo Ending $0 $(date)
