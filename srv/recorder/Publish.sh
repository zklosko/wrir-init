#!/bin/bash

#Begin CopyToRAS.sh
#ps -ef | grep -v $$ | grep -q $0 && exit

sWorkDir=/srv/recorder
# make working folder if not present
[[ ! -d ${sWorkDir}/archive ]] && mkdir ${sWorkDir}/archive

sDest=/srv/static/shows
sMinFree=97

echo Start $0 $(date)

cd /srv/recorder/raw/

ls *.publish |
while read sFile ; do
  echo Working on ${sFile}

  mv ${sFile} ${sFile%.publish}.tfr  # renames input file
  sFN=${sFile%.publish}  # removes .publish from filename variable
  echo Publishing $sFN
  for sExt in mp3 ogg; do
    if cp ${sFN}.${sExt} ${sDest}  # copy mp3, ogg files to dest
    then
      echo Copy good
    else
      touch ${sFN}.${sExt}.error  # create showname.error file on copy error
    fi
    
    # Archive the show directly to the Z drive for immediate access
    sShowYr=${sFile:0:4}
    sShowMo=${sFile:4:2}
    # sShowDn=${sFile:6:2}
    mkdir -p "/srv/shares/Z/AUDIO ARCHIVES/ShowArchive/${sShowYr}/${sShowMo}"
    if cp ${sFN}.mp3 "/srv/shares/Z/AUDIO ARCHIVES/ShowArchive/${sShowYr}/${sShowMo}"
    then
      echo Archive good
    else
      cp ${sFN}.mp3 ${sWorkDir}/archive
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
