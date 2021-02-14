#!/bin/bash
ps -ef | grep -v $$ | grep -q $0 && exit
echo Start $0

cd /srv/recorder/raw/

ls -1r *.mp3.new |
while read sFile
do
  sFile=${sFile##*/}
#remove second record start time 201604210600-0800.Breakf
  sInfoFil1=${sFile:0:12}.${sFile:18}
  sInfoFile=${sInfoFil1%%.mp3.new}.info 
  if [[ ! -f ${sInfoFile} ]]
  then
    sShowYr=${sFile:0:4}
    sShowMo=${sFile:4:2}
    sShowDn=${sFile:6:2}
    sShowHr=${sFile:8:4}
    sShowDy=$(date "+%A" -d "${sFile:0:4}/${sFile:4:2}/${sFile:6:2}")
    #sShowEp=$(date "+%s" -d "${sFile:0:4}/${sFile:4:2}/${sFile:6:2}")  # is this needed?

    #sShowURL will be a list for alrernating shows, as it will match more than one line in showdata
    sShowURL=$(grep "^${sShowDy}|${sShowHr}|" ../showdata.txt|cut -f7 -d"|")

    echo ${sFile} ${sShowDy} ${sShowURL}

    for sURL in ${sShowURL}
    do
      touch ${sInfoFile}
#<li><a href="http://wrir.org/2016/04/16/party-of-one-record-store-day/">Party of One: Record Store Day!</a></li>
      wget -q "${sURL}" -O - | grep "myplaylist-blog-posts" | sed 's/<li/\n&/g' |grep -v myplaylist-post-list|
      while read sLine
      do
		sTrim1="${sLine##*wrir.org/}"
		sBlogDate=$(date "+%s" -d ${sTrim1:0:10})
		sTitle1=${sTrim1#*>}
		sTitle=${sTitle1%%<*}

		if true # [[ ${sBlogDate} -eq ${sShowEp} ]]  # info file not populated if condition is not met?
		then
		  sShowName=$(grep "^${sShowDy}|${sShowHr}|" ../showdata.txt|grep "${sURL}"|cut -f3 -d"|")
		  sDisplayDate=$(date --date="@${sBlogDate}")
		  sBlogURL1=${sLine##*a href=\"}
		  sBlogURL=${sBlogURL1%%\"*}
		  sPoster=$(wget -O - ${sBlogURL} |grep 'glyphicon glyphicon-user'|  grep -v meta|sed 's/[<|>]/|/g'|cut -f7 -d\|)
		  echo "${sInfoFile%%.info}|${sDisplayDate}|${sShowName}|${sPoster}|${sTitle}|" > ${sInfoFile}  # error: info file is empty
		fi
      done 
    done
  fi
done
