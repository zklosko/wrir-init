# /bin/bash

# 1. Install prereqs
apt update
apt install -y ffmpeg tzdata procps id3v2 apache2 icecast2 nfs-common

# 2. Copy files

# Config files
cp -av icecast.xml /etc/icecast2/
cp -av files.wrir.org.conf /etc/apache2/sites-enabled/

# Application files
cp -avr srv/* /srv

# 3. Initialize setup

# Attach network drives
mkdir /srv/shares/Y
mkdir /srv/shares/Z
echo "192.168.200.16:/volume1/shared    /srv/shares/Y   nfs auto,nofail,noatime,nolock,intr,tcp 0 0" >> /etc/fstab
echo "192.168.200.23:/volume1/z    /srv/shares/Z   nfs auto,nofail,noatime,nolock,intr,tcp 0 0" >> /etc/fstab

mount -a

# Set up cron
cat crontab > /etc/crontab

# Set up firewall
ufw enable
ufw allow 22,80,443,8000/tcp

# Restart services
systemctl restart apache2
systemctl enable apache2
systemctl restart icecast2
systemctl enable icecast2
systemctl restart cron
systemctl enable cron

echo 'All done!'