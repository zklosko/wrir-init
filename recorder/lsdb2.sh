#!/bin/bash

sDIR="~/Y/DIGITAL MUSIC LIBRARY/LiveMusic/"
sLSDBFolder="/var/www/html/"
#cd /tmp

sPrevDB=$(ls -1tr ${sLSDBFolder}/*.lsdb|tail -1)

#sNewDB=$(date "+%Y%j")-$$.lsdb
#[[ -f ${sNewDB} ]] && rm ${sNewDB}
sNewDB="$(mktemp)"

sId=$(cut -f1 -d\| "${sPrevDB}"|sort -n|tail -1)

find "${sDIR}" -type f -name '*.mp3' |
while read sF; do
  sF1=${sF##$sDIR}
  sFile=${sF1##*/}
  sFold=${sF1%/*}
  sFileDate=$(date -r "${sF}")
  
  #Columns ID,Folder,File,Date. Match any files
  sMatch=$(cut -f1,6,7,10 -d\| <"${sPrevDB}" | grep "|${sFold}|${sFile}|${sFileDate}$")
  sMatchId=${sMatch%%|*}

  if [[ -n "${sMatchId}" ]]
  then
    grep "^${sMatchId}|" < "${sPrevDB}" >> "${sNewDB}"
  else
    #new file
    echo "${sF}"
    sTags=$(id3v2 -l "${sF}" | tr '|' ':') 

    sArt=$(grep TPE1 <<< "${sTags}")
    sSong=$(grep TIT2 <<< "${sTags}")
    sNum=$(grep TRCK <<< "${sTags}") 
    sSet=$(grep TALB  <<< "${sTags}")
    sYear=$(grep TYER  <<< "${sTags}")
#TXXX (User defined text information): (DATE): 11-20-2015
    [[ -z "${sYear}" ]] && sYear=$(grep TXXX <<< "${sTags}" | grep DATE)
    sDDMM=$(grep TDAT  <<< "${sTags}")
    sGenre=$(grep TCON  <<< "${sTags}")
    sGenre="${sGenre% (*}"
    sId=$((sId+1))
    echo "${sId}|${sArt#*: }|${sNum#*: }|${sSong#*: }|${sSet#*: }|${sFold}|${sFile}|${sYear##*: }|${sDDMM##*: }|${sFileDate}|${sGenre#*: }|" >> "${sNewDB}"
  fi
done

echo ${sPrevDB} ${sNewDB}
if diff -q ${sPrevDB} ${sNewDB}
then
  echo "discard"
  rm "${sNewDB}"
else
  echo "keep"
  chmod a+r "${sNewDB}"
  mv "${sNewDB}" ${sLSDBFolder}/$(date "+%Y%j").lsdb
fi
