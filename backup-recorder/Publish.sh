#!/bin/bash

#Begin CopyToRAS.sh
#ps -ef | grep -v $$ | grep -q $0 && exit

sWorkDir=/srv/recorder
# make working folder if not present
[[ ! -d ${sWorkDir}/archive ]] && mkdir ${sWorkDir}/archive
[[ ! -d ${sWorkDir}/ready ]] && mkdir ${sWorkDir}/ready

# sDest=/shows
# sMinFree=97

echo Start $0 $(date)

cd /srv/recorder/raw/

ls *.publish |
while read sFile ; do
  echo Working on ${sFile}

  mv ${sFile} ${sFile%.publish}.tfr
  sFN=${sFile%.publish}  # removes .publish from filename variable
  echo Publishing $sFN
  for sExt in mp3 ogg; do
    if cp ${sFN}.mp3 ${sWorkDir}/ready
    then
      echo Archive good
      mv ${sFN}.tfr ${sFN}.done
    else
      cp ${sFN}.mp3 ${sWorkDir}/archive
      echo Archive error
    fi
  done
done
