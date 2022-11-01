#!/bin/bash

# Cleaning files in raw
sDays=1
echo Starting $0 $(date)

find /srv/recorder/raw/* -ctime +${sDays} -delete

# Cleaning files in publish a.k.a. files.wrir.org/shows
# sDir="/srv/static/shows"
sDays=14
find /srv/recorder/ready/* -ctime +${sDays} -delete
# echo "Starting $0 $(date)"

