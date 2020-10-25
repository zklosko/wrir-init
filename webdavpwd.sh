#!/bin/bash
# Found in /home/Peter/

sHTP="/var/www/web1/passwd.dav"
sAllowed="/var/www/data/allowed.txt"
sEMail="${1}"


if grep -iq "${sEMail}\$" ${sAllowed}
then
  echo "user already in alllowed"
else
  echo "${1}" >> ${sAllowed}
fi

sUserName="${sEMail%@*}"
grep "${sUserName}" ${sHTP} && echo "password reset"
sPasswd="$(makepasswd)"
if htpasswd -b ${sHTP} ${sUserName} ${sPasswd}
then
  {
  echo "From: peter@wrir.org"
  echo "To: ${sEMail}"
  echo "Reply-To: peter@wrir.org"
  echo "Subject: WebDav update"
  echo ""
  echo "user name: ${sUserName}"
  echo "pass: ${sPasswd}"
  echo ""
  echo "queries to: peter@wrir.org" 
  } | ssmtp -F $(uname -n) "${sEMail}"

  {
  echo "From: peter@wrir.org"
  echo "To: peter@wrir.org"
  echo "Reply-To: peter@wrir.org"
  echo "Subject: WebDav update"
  echo ""
  echo "user name: ${sUserName} added"
  } | ssmtp -F $(uname -n) "${sEMail}"


else
  echo "add failed"
fi
