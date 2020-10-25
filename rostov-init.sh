# /bin/bash

# 1. Install prereqs

apt update -y && apt install ffmpeg tzdata procps id3v2 \
  apache2 icecast2 cifs-utils winbind libnss-winbind -y && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  echo $TZ > /etc/timezone

# 2. Copy files

# For the stream recorder
cp recorder ~/

# For Apache (WebDAV)
cp conf-available/dav.conf /etc/apache2/conf-available/dav.conf
cp sites-available /etc/apache2/sites-available
cp user.passwd /

cp guides /var/lib/dav/data

# 3. Initialize setup

cd /var/lib/dav/data/ && mkdir Y && mkdir Z

touch ~/.smbcredentials && \
  echo -e 'username=rfrdj\npassword=wwr4trou\ndomain=wrir.local' > ~/.smbcredentials

echo "//192.168.200.16/shared ~/Y cifs credentials=/home/wrirops/.smbcredentials,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab
echo "//192.168.200.23/z ~/Z cifs credentials=/home/wrirops/.smbcredentials,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab

mount -a

echo "*/5 * * * * cd ~/recorder && bash RecRunner.sh &" >> /etc/crontab

ufw enable
ufw allow 22,443/tcp

a2enmod dav
systemctl restart apache2

echo 'All done!'