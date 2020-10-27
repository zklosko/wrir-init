#!/bin/bash

#Begin CopyToRAS.sh
ps -ef | grep -v $$ | grep -q $0 && exit

sWorkDir=${PWD}
# make working folder if not present
[[ ! -d ${sWorkDir}/publish ]] && mkdir ${sWorkDir}/publish
[[ ! -d ${sWorkDir}/archive ]] && mkdir ${sWorkDir}/archive

sDest=${PWD}/publish
sMinFree=97

echo Start $0 $(date)

cd ./raw/

ls *.publish |
while read sFile ; do
  echo Working on ${sFile}

  mv ${sFile} ${sFile%.publish}.tfr  # renames input file
  sFN=${sFile%.publish}  # removes .publish from filename variable
  echo Publishing $sFN
  for sExt in mp3 ogg; do
    if cp ${sFN}.${sExt} ${sDest} ; then  # copy mp3, ogg files to dest
      echo Copy good
    else
      touch ${sFN}.${sExt}.error  # create showname.error file on copy error
    fi
    
    # Archive the show directly to the Z drive for immediate access
    sShowYr=${sFile:0:4}
    sShowMo=${sFile:4:2}
    sShowDn=${sFile:6:2}
    mkdir -p "/Z/AUDIO ARCHIVES/test/ShowArchive/${sShowYr}/${sShowMo}/${sShowDn}"
    if cp ${sFN}.mp3 "/Z/AUDIO ARCHIVES/test/ShowArchive/${sShowYr}/${sShowMo}/${sShowDn}"
    then
      echo Archive good
    else
      cp ${sFN}.mp3 sWorkDir/archive
      echo Archive error
    fi
  done
  
  [[ -s ${sFN}.info ]] && cp ${sFN}.info ${sDest}
  [[ -s ${sFN}.audio.txt ]] && cp ${sFN}.audio.txt ${sDest}
  if cp ${sFN}.tfr ${sDest}/${sFN##*/}.ready ; then
    mv ${sFN}.tfr ${sFN}.done
  fi
done

# below condition appears to be failing
# sSched=$(find showdata.txt -newer showdata.txt.copied)
# if [[ -n ${sSched} ]] ; then
#   if cp showdata.txt ${sDest} ; then
#     touch -r showdata.txt showdata.txt.copied
#   fi
# fi
