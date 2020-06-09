#! /bin/bash
sudo yum -y update

# OS timezone
sudo timedatectl set-timezone Asia/Tokyo

# location
sudo localectl set-locale LANG=ja_JP.UTF-8
sudo localectl set-keymap jp106

# nginx install
sudo amazon-linux-extras install -y nginx1.12

# php / php-fpm
sudo amazon-linux-extras install -y php7.2
# php library install
sudo yum install -y php-mbstring php-opcache php-dom

# php-fpm adjustment
sudo cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf_bkup
sudo sed -i -e 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf

# php adjustment
sudo cp /etc/php.ini /etc/php.ini_bkup
sudo sed -i -e 's/expose_php = On/expose_php = Off/g' /etc/php.ini
sudo sed -i -e 's/;date.timezone =/date.timezone = Asia\/Tokyo/g' /etc/php.ini
sudo sed -i -e 's/;mbstring.language = Japanese/mbstring.language = Japanese/g' /etc/php.ini
sudo sed -i -e 's/;mbstring.encoding_translation = Off/mbstring.encoding_translation = Off/g' /etc/php.ini
sudo sed -i -e 's/;mbstring.detect_order = auto/mbstring.detect_order = UTF-8,SJIS,EUC-JP,JIS,ASCII/g' /etc/php.ini

# systemctl start / enable
sudo systemctl start php-fpm
sudo systemctl start nginx
sudo systemctl enable php-fpm
sudo systemctl enable nginx

# git install
sudo yum install -y git
echo "Host github.com
StrictHostKeyChecking no" | sudo tee /root/.ssh/config

# github connect
echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2ao5o2t87ZXaUx5e4KvA8WWpazJcJC4jO4QbLK9SndJIO7Ce
0BrkAwGdB0rnnWWZVaeiD1CTvTIH1Il8fECPg2fOkDR4cU3axNxWNkDisZpix86u
SSt2rG/ffvMcB6Oni9N51SRFHYBXVvYTGuyEckw0ait9lfwOB7KJld0Tkm/WoxsF
2+UAmzE+ZKduRRDf1K+TKWXMUlzQ2x+ahxujxIs+Cyy1SOflIGeFlp1ifgSv9bzu
kfxBbQNTQStsPtPYcI+0g7QNSbfnWrC2XIgZhQlrm5Qn0yyyLpgIXoWysQh17tKl
TLwFjoN382JzZMQLTDWXdLjuvVXY7aQbrJsAiwIDAQABAoIBAQDPWxP3s7FaoLRR
FJCsFdMD5KZGAb63lOBplUtSAV+CC85WVsakV8m5d3MBfIEzd5Ngfwaq8kccKKo+
9g8KS3Ksa1rkE6hdwB5WBdV3b87GBN5vnFx6RhaS5SyTwsOEH4rAcOEShK/3D8mk
hV3j+0edny0bq3zDQlCXUqUxiF9Z0sDsw2hoi8EzVh1wrX6mbzi4SQSCEU7HsYf8
ZCqkGoy7Ki9iLh0ZEmbgFJAazmjfLPHr3kA/hA2HjjkiMgUx0qry+aE3YwI8vPHi
+XptR1YaVljlG4Mc7iktHs2udz9bj2/0HuRq0R4SFtCbv2DP3stvm9oOYUVnhzUT
tHc/C/IRAoGBAPfEaLrEWOOStuSdIb6G0tAgMoK70fz03n+XTNyaoqpl2UQQNoM1
V6ocD9Pcwn43ZvR3XADs7jdqSfD9Fk4g7cQUNh39s3JaAV2TpdTiDz/Sr4sacooH
u7GLxsdC4S2cE1Xjw2W/SSFB7LZzHxePhrP8mEr7GsEhraGcvJN9LXdJAoGBAODl
wYeaCaLBPY8kjWCjesu36Mplo8gckhIDNnBTpE7JUn8cR4vboLsSAeN7l7ACgmLv
IGIswqMBluBOaSdVyrO+nRJOXgWgKArz3dUJ7v9jjD7KiPD8XcAtN9fK1RThIip4
6fUBIpo3a0Sv0MIxuLdziW35bx92Zfz0mSL/aVUzAoGBAIvUAq70xJ2aXTFkJHkc
KblfkmIJkZbKsw8a2jvd4VN9K0KoS7t8zT6pm50bh4An0CjDe97h2AbaK2Sf0IjD
OKxiI7CFT1KHzSF8hChCdAy24G8GvAF+H8UxdztZWS+eV6MvaUTw0Vq9k9Pb4H4x
d/n34hLe59h7IzyD8kDiclhRAoGAC+TayVsiK1Ng+BMMzxGWSvPdAedCNDEeoIk+
9c3WoLwQ+tv6BLGG3J3lL6y3pv1a+/R9l/OaD5jj69T5xrTI1Zy9Hdy7KD0CISIo
lz3BQAx5vFBl0ajnJGS/0U/O2R3W+rwOU4DN3a4UpDtQJRUQGdOobwKEF/vhBPHC
r5EmdvUCgYA2nR8gDcgtFn07LKAaGby1wtpWioF4vCKaa0+b0uSXLWNUZwbSycLc
jhwlyDLdQwkUc6dqVSJktxLgL4G+JUWXm2Z0JtHYKd4Iyz8fP1OOIOfjcbG2D3N7
Ty9iHa4+wd7UBtnAlw1Hv04Xjz3c+2ejzyZi8cTvUv+zRI3V+ig9+g==
-----END RSA PRIVATE KEY-----" \
| sudo tee /root/.ssh/id_rsa 
sudo chmod 600 /root/.ssh/id_rsa

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZqjmja3ztldpTHl7gq8DxZalrMlwkLiM7hBssr1Kd0kg7sJ7QGuQDAZ0HSuedZZlVp6IPUJO9MgfUiXx8QI+DZ86QNHhxTdrE3FY2QOKxmmLHzq5JK3asb99+8xwHo6eL03nVJEUdgFdW9hMa7IRyTDRqK32V/A4HsomV3ROSb9ajGwXb5QCbMT5kp25FEN/Ur5MpZcxSXNDbH5qHG6PEiz4LLLVI5+UgZ4WWnWJ+BK/1vO6R/EFtA1NBK2w+09hwj7SDtA1Jt+dasLZciBmFCWublCfTLLIumAhehbKxCHXu0qVMvAWOg3fzYnNkxAtMNZd0uO69VdjtpBusmwCL root@ip-20-10-3-166.ap-northeast-1.compute.internal" \
| sudo tee /root/.ssh/id_rsa.pub
sudo chmod 600 /root/.ssh/id_rsa.pub

# composer
cd /usr/share/nginx/html/
sudo git clone git@github.com:hassyadai/Ivy.git
cd Ivy
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php
sudo php -r "unlink('composer-setup.php');"
sudo mv composer.phar /sbin/composer

sudo composer global require "laravel/installer"
sudo composer install
sudo chmod -R 777 storage/
sudo chmod -R 777 bootstrap/cache/

# nginx change root
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_bkup
sudo sed -i -e 's/\/usr\/share\/nginx\/html/\/usr\/share\/nginx\/html\/Ivy\/public/' /etc/nginx/nginx.conf
sudo systemctl reload nginx

# env copy
# sudo php artisan key:generate