#!/bin/sh

# setup required repos
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >/etc/apk/repositories
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/community' >>/etc/apk/repositories
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >>/etc/apk/repositories
apk update
apk upgrade musl # required to compile fuse-zip
apk add apache2 apache2-proxy php-apache2 fuse unionfs-fuse curlftpfs sudo
sed -i 's/DEFAULT menu.c32/DEFAULT virt/g' /boot/extlinux.conf # boot directly into alpine

# install php packages
apk add php-json php-openssl php-session php-pdo php-pdo_sqlite php-simplexml php-xml
wget -O/tmp/vendor.tar https://github.com/FlashpointProject/svcomposer/releases/download/18c0ebd/vendor.tar
tar -xvf /tmp/vendor.tar -C /var/www/localhost --exclude='vendor/silexlabs/amfphp/doc'

# install fuse-zip
apk add fuse-dev build-base libzip-dev git
git clone https://bitbucket.org/agalanin/fuse-zip.git /tmp/fuse-zip
cd /tmp/fuse-zip
sed -i 's/-Werror//g' Makefile
make release && make install

# install fuzzyfs
git clone https://github.com/XXLuigiMario/fuzzyfs.git /tmp/fuzzyfs
cd /tmp/fuzzyfs
make && make install

# setup htdocs
mkdir /root/base /mnt/games /mnt/htdocs
git clone --recursive https://github.com/FlashpointProject/svroot_infinity.git /tmp/svroot
cd /tmp/svroot
find . -type f -not -path '*/.git*' -exec cp --parents {} /root/base \;
chmod -R 755 /root/base
rm /var/www/localhost/htdocs/index.html

# setup apache
rc-update add apache2 # run apache2 on startup
echo 'apache ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers
sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.htm index.php/g' /etc/apache2/httpd.conf
sed -i '/LogFormat.*common$/a\    LogFormat "%>s %r" flashpoint' /etc/apache2/httpd.conf
sed -i 's/access.log combined/access.log flashpoint env=!dontlog/g' /etc/apache2/httpd.conf
sed -i '/INCLUDES.*shtml$/a\    AddType x-world/x-xvr .xvr' /etc/apache2/httpd.conf
sed -i '/INCLUDES.*shtml$/a\    AddType x-world/x-svr .svr' /etc/apache2/httpd.conf
sed -i '/INCLUDES.*shtml$/a\    AddType x-world/x-vrt .vrt' /etc/apache2/httpd.conf
sed -i '/INCLUDES.*shtml$/a\    AddType application/x-httpd-php .phtml' /etc/apache2/httpd.conf
echo 'SetEnv force-response-1.0' >>/etc/apache2/httpd.conf # required for certain Shockwave games, thanks Tomy
echo 'SetEnvIf Remote_Addr "::1" dontlog' >>/etc/apache2/httpd.conf # disable logging of Apache's dummy connections
echo 'ProxyPreserveHost On' >>/etc/apache2/httpd.conf # keep "Host" header when proxying requests to router
echo Done!
