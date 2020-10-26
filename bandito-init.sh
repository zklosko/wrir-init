# /bin/bash

# 1. Install prereqs (and set timezone)
TZ="America/New_York"
apt update -y && apt install ffmpeg tzdata procps id3v2 \
  apache2 icecast2 cifs-utils winbind libnss-winbind -y && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  echo $TZ > /etc/timezone

# 2. Copy files

# For Icecast
cp icecast.xml /etc/icecast2/

# For the stream recorder
cp -r recorder ~/

# For Apache
cp htdocs/index.html /var/www/html/index.html
cp -r cgi-bin /usr/local/cgi-bin
cp -r apache2 /etc/apache2

# 3. Initialize setup

# Attach network drives
cd ~ && mkdir Y && mkdir Z

touch ~/.smbcredentials && \
  echo -e 'username=rfrdj\npassword=wwr4trou\ndomain=wrir.local' > ~/.smbcredentials

echo "//192.168.200.16/shared ~/Y cifs credentials=/home/wrirops/.smbcredentials,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab
echo "//192.168.200.23/z ~/Z cifs credentials=/home/wrirops/.smbcredentials,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab

mount -a

# Add stream recorder and lsbd2.sh to crontab
echo "*/5 * * * * cd ~/recorder && bash RecRunner.sh &" >> /etc/crontab
echo "50  * * * * bash ~/lsbd2.sh &" >> /etc/crontab

# Set up firewall
ufw enable
ufw allow 22,80,8000/tcp

# Restart services
systemctl restart apache2
systemctl restart icecast2

echo 'All done!'