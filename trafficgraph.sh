#!/bin/bash

sDate=$1
[[ -z $sDate ]] && sDate=$(date +%Y%m%d)

sFolder=./traffic/
echo ${sDate}

sInc=$(( 5 * 60 ))

sScratch=$(mktemp)

sMax=0

sIndex=0
sMarker=""
sIn=0
sOut=0
while read sStamp sRecord; do
  sEpo1=$(echo ${sRecord}|cut -f1 -d\|)
  sEpoc=${sEpo1%%.*}
  sInV=$(echo ${sRecord}|cut -f2 -d\|)
  sOutV=$(echo ${sRecord}|cut -f3 -d\|)

  if [[ -z "${sMarker}" ]]; then
    sMarker=$(( sEpoc + sInc ))
    sInP=${sInV}
    sOutP=${sOutV}
  fi

  [[ ${sInV} -lt ${sInP} ]] && sInP=0
  [[ ${sOutV} -lt ${sOutP} ]] && sOutP=0
  
  sIn=$(( sIn + sInV - sInP ))
  sOut=$(( sOut + sOutV - sOutP ))

  sInP=${sInV}
  sOutP=${sOutV}

  if [[ ${sEpoc} -gt ${sMarker} ]]; then
    echo $(date -d "@${sMarker}" "+%H:%M") $sIndex $sIn $sOut >> ${sScratch}
    [[ ${sIn} -gt ${sMax} ]] && sMax=${sIn}
    [[ ${sOut} -gt ${sMax} ]] && sMax=${sOut}
    sIn=0
    sOut=0
    sIndex=$((sIndex+1))
    sMarker=$(( sMarker + sInc ))
  fi
done < ${sFolder}/${sDate} 

echo ${sMax} 
{
echo "<!DOCTYPE html>" 
echo "<html><title>traffic ${sDate}</title><body>"
echo "<h1>traffic ${sDate}</h1>"
echo "<svg width=\"$((2*sIndex))\" height=\"200\">"
} > ~/${sDate}-report.html

while read sTime sIndx sBIn sBOut; do
  sH1=$((200*sBIn/sMax))
  sH2=$((200*sBOut/sMax))
  echo "<line x1=$((2*sIndx)) x2=$((2*sIndx)) y1=200 y2=$((200-sH2)) style=\"stroke:rgb(255,0,0);stroke-width:1\"/>"
  echo "<line x1=$((2*sIndx+1)) x2=$((2*sIndx+1)) y1=200 y2=$((200-sH1)) style=\"stroke:rgb(0,255,0);stroke-width:1\"/>"
done < ${sScratch} >> ~/${sDate}-report.html

{
echo "SVG support needed"
echo "</svg>"
echo "<p>Max $((sMax/sInc)) bytes/sec</p>"
echo "</body></html>"
} >> ~/${sDate}-report.html

rm ${sScratch}
