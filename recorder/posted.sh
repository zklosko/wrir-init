#!/bin/bash

sWorkDir=/scripts
sPid=${sWorkDir}/me.pid

if [[ -f ${sPid} ]] && ps -p $(< ${sPid} ) -f | grep $0
then
  echo "$0 is running already"
  exit
else
  echo $$ > ${sPid}
fi

# make working folders if they're not here
[[ ! -d ${sWorkDir}/raw ]] && mkdir ${sWorkDir}/raw

# this file, the name of the current show should exist.
[[ ! -f ${sWorkDir}/currentshow.txt ]] && exit

if sList=$(ls -1 *.mp3 | grep -v $(<${sWorkDir}/currentshow.txt) )
then
  mv ${sList} ${sWorkDir}/raw/  # moves sList into raw directory

  for i in ${sList}
  do
    sFF=$(ls ${sWorkDir}/raw/${i:0:12}-*.mp3|head -1)  # returns beginning of filename
    touch ${sFF}.new  # creates new file, sFF.new
  done
fi

#VBR quality (really size) is selected using a number from 0 to 9.
# Use a value of 0 for high quality, larger files, and 9 for smaller files of lower quality. 4 is the default.
#In LAME, 0 specifies highest quality but is very slow, while 9 selects poor quality, but is fast.

cd /srv/recorder/raw/
for sNew in $(ls *.new)
do
  sFile=${sNew%%-*}
  sProg=${sNew:18}
  sProg=${sProg%%.mp3.new}
  echo GG ${sFile} ${sProg}
  #sox "${sFile}-[0-2]*.mp3" -C-9.2 ${sFile}.${sProg}.lo.mp3 stats 2> ${sFile}.${sProg}.stats.txt

  #sDur=$(grep "Length s" ${sFile}.${sProg}.stats.txt|awk '{printf "%i\n",$3+0.5}')
  #echo "DURS|${sDur}|" > ${sFile}.${sProg}.audio.txt

  sDate="${sNew:4:2}/${sNew:6:2}/${sNew:0:4}"
  sTime="${sNew:8:4}"
  if grep "^$(date -d ${sDate} +%A)|${sTime}" ../showdata.txt | cut -f5 -d'|' | egrep "music|local"
  then
    #sox "${sFile}-[0-2]*.wav" -C-0.2 ${sFile}.${sProg}.hi.mp3
    #sox -m "${sFile}-[0-2]*.mp3" ${sFile}.${sProg}.mp3
    echo OOO "${sFile}.${sProg}.mp3"
    sPLS=$(mktemp)
    find . -maxdepth 1 -name "${sFile}-[0-2]*.mp3" -printf "file $PWD/'%P'\n" > ${sPLS}
    ffmpeg -f concat -safe 0  -i ${sPLS} -c copy "${sFile}.${sProg}.mp3"
    rm ${sPLS}
    #ffmpeg "copy ${sFile}.${sProg}.mp3" "${sFile}.${sProg}.ogg"
    ffmpeg -i "${sFile}.${sProg}.mp3" -codec:a libvorbis "${sFile}.${sProg}.ogg"
    #sox "${sFile}-[0-2]*.mp3" -C3 ${sFile}.${sProg}.ogg  # soundexchange, was compressing files
    touch ${sFile}.${sProg}.publish
  fi
  rm ${sFile}-[0-2]*.mp3
done

[[ -f ${sPid} ]] && rm ${sPid}
