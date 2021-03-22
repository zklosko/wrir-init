# /bin/bash

# 1. Install prereqs
apt update
apt install -y ffmpeg tzdata procps id3v2 apache2 icecast2 cifs-utils winbind libnss-winbind

# 2. Copy files

# Config files
cp -av icecast.xml /etc/icecast2/
cp -av files.wrir.org.conf /etc/apache2/sites-enabled/

# Application files
cp -avr srv/* /srv

# 3. Initialize setup

# Attach network drives
mkdir /Y && mkdir /Z

echo -e 'username=rfrdj\npassword=wwr4trou\ndomain=wrir.local' >> /.smbcredentials
echo "//192.168.200.16/shared /Y cifs credentials=/.smbcredentials,vers=1.0,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab
echo "//192.168.200.23/z /Z cifs credentials=/.smbcredentials,vers=1.0,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab

mount -a

# Set up cron
cat crontab > /etc/crontab

# Set up firewall
ufw enable
ufw allow 22,80,8000/tcp

# Restart services
systemctl restart apache2
systemctl enable apache2
systemctl restart icecast2
systemctl enable icecast2
systemctl restart cron
systemctl enable cron

echo 'All done!'