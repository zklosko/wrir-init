#!/bin/bash

# File 1: Mon.txt for each day
# HHMM ShowKey
# whats complicated is the first line of Mon as 0000 Cosmic is the show last line of Sunday, and 2400 Midnight is alway at the end
#0000 CosmicSlop
#0100 BasisofFunk
#2300 TimeAgainRadioShow
#2400 Midnight

#File 2: showdata.txt
# Day|HHMM|ShowKey|Show Name|type|DJ|URL|Icon URL|Show Link|Show Description
#Sunday|0000|SoulFoodMidAtlanticJams|Soul Food / Mid Atlantic Jams|music||http://wrir.org/show/soul-food/|http://wrir.org/wp-content/uploads/2015/10/Soul-Food-300x300.png||
#Sunday|0100|HipHopfortheRestofUs|Hip-Hop for the Rest of Us|music||http://wrir.org/show/hip-hop-for-the-rest-of-us/|http://wrir.org/wp-content/uploads/2015/07/blaq-0x70.jpg||
#Sunday|0300|DealersChoice|Dealers Choice|music||http://wrir.org/show/dealers-choice/|/wp-content/uploads/2017/04/wrir.png||

#File 3: shows.txt
# ShowKey type Show Name
#Activate music Activate!
#AGrainofSand local A Grain of Sand
#AlteredCircuitry music Altered Circuitry

echo $0
if ps -eo pid,comm | grep -v $$ | grep ${0##*/}
then
  echo Can only run once
  exit
fi

sCSV="$(mktemp)"
sCSV=$$.tmp

#if ! curl -s http://www.wrir.org/generate-schedule-csv > "${sCSV}"
if ! curl -s https://www.wrir.org/generate-schedule-csv > "${sCSV}"
then
  echo CURL failed
  exit
fi

if ! grep -q Saturday "${sCSV}"
then
  echo "quitting because there's no Saturday in this file ${sCSV}"
  exit
fi


#Sunday,1300,MellowMadness,"Mellow Madness",music,michaelm,http://www.radio4all.net/index.php/series/Mellow+Madness,http://wrir.org/wp-content/uploads/2015/07/mellowmadness2_thumb-0x70.jpg,

sDays="Mon Tue Wed Thu Fri Sat Sun"
rm -f showdata.$$ shows.x.$$ showdata.inc.$$
for sDay in ${sDays}
do
  rm -f ${sDay}.x.$$ ${sDay}.$$
done

while IFS="|" read sDay sHHMM sShowKey sShowNameQ sType sDJ sURL sIMG sExtra
do
  echo "${sHHMM} ${sShowKey}" >> ${sDay:0:3}.x.$$
  sShowName=$(tr -d '"' <<< "${sShowNameQ}")
  echo "${sDay}|${sHHMM}|${sShowKey}|${sShowName}|${sType}|${sDJ}|${sURL}|${sIMG}|${sExtra}" >> showdata.$$
  [[ -n "${sType}" ]] && echo "${sShowKey} ${sType} ${sShowName}" >> shows.x.$$
done < "${sCSV}"

#Fix days, add prev show at start, sort numerically, add Midnight at end
sPrev="Sun"
for sDay in ${sDays}
do
  sLastShow=$(tail -1 ${sPrev}.x.$$)
  echo "0000 ${sLastShow:5}" > ${sDay}.$$
  sort -n  ${sDay}.x.$$ >> ${sDay}.$$
  echo "2400 Midnight" >> ${sDay}.$$

  sPrev=${sDay}
done

for sDay in ${sDays}
do
  rm ${sDay}.x.$$
done

sort -u shows.x.$$ > shows.$$
rm shows.x.$$

rm "${sCSV}"

#recover old shows for the Archive lookup.
while IFS="|" read sDay sHHMM sShowKey sShowName sType sDJ sURL sIMG sExtra
do
  if ! grep -q "|${sShowKey}|" showdata.$$
  then
    echo "Retired|0000|${sShowKey}|${sShowName}|${sType}|${sDJ}|${sURL}|${sIMG}|${sExtra}" >> showdata.inc.$$
  fi
done < showdata.txt

cat showdata.$$ showdata.inc.$$ > showdata.final.$$
rm -f  showdata.$$ showdata.inc.$$ 

#Keep versions of changes
for sDay in ${sDays}; do
  if cmp ${sDay}.$$ ${sDay}.txt
  then
    echo no change for ${sDay}
    rm ${sDay}.$$
  else
    cp ${sDay}.txt ${sDay}.old.$(date "+%Y%m%d%H%M%S")
    mv ${sDay}.$$ ${sDay}.txt
  fi
done

if cmp showdata.final.$$ showdata.txt
then
  rm showdata.final.$$
  echo "No change of show data"
else
  cp showdata.txt showdata.old.$(date "+%Y%m%d%H%M%S")
  mv showdata.final.$$ showdata.txt
fi

if cmp shows.$$ shows.txt
then
  echo "No change of shows file"
  rm shows.$$
else
  cp shows.txt shows.old.$(date "+%Y%m%d%H%M%S")
  mv shows.$$ shows.txt
fi

cp -f showdata.txt ./publish  # updating showdata.txt file for files.wrir.org scripts

