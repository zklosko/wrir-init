#!/bin/bash

cd /scripts
date -R
bash ./whatson4.sh &
sleep 60
bash ./posted.sh  # none -> .new + .publish
bash ./getInfo2.sh  # .new -> .info
bash ./Publish.sh  # .publish -> .tfr -> .done
bash ./getsched17.sh