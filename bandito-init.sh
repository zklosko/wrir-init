# /bin/bash

# 1. Install prereqs
apt update -y && apt install ffmpeg tzdata procps id3v2 apache2 icecast2 cifs-utils winbind libnss-winbind -y

# 2. Copy files

# For Icecast
cp -av icecast.xml /etc/icecast2/

# For the stream recorder
cp -avr recorder /

# For Nginx
# cp -avr html/* /srv/static
# cp -avr cgi-bin/* /srv/cgi-bin/
# cp -av default /etc/nginx/sites-configured/

# 3. Initialize setup

# Attach network drives
mkdir /Y && mkdir /Z

touch /.smbcredentials && \
  echo -e 'username=rfrdj\npassword=wwr4trou\ndomain=wrir.local' > /.smbcredentials

echo "//192.168.200.16/shared /Y cifs credentials=/.smbcredentials,vers=1.0,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab
echo "//192.168.200.23/z /Z cifs credentials=/.smbcredentials,vers=1.0,iocharset=utf8,gid=1000,uid=1000,file_mode=0777,dir_mode=0777 0 0 " >> /etc/fstab

mount -a

# Add RecRunner.sh to crontab
echo "@reboot root bash /recorder/RecRunner.sh &" >> /etc/crontab

# Set up firewall
ufw enable
ufw allow 22,80,8000/tcp

# Restart services
systemctl restart nginx
systemctl restart icecast2

echo 'All done!'