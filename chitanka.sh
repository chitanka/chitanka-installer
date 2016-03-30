#!/bin/bash

## 
#
# version: 1-alfa
# last_build: 30.03.2016
#
##

## General

DATE=`date +"%d-%m-%y"`
NOW=`date +"%T"`


## META - colors [START]

# Reset
COLOR_RESET='\033[0m'

# Regular
COLOR_REGULAR_BLACK='\033[0;30m'
COLOR_REGULAR_RED='\033[0;31m'
COLOR_REGULAR_GREEN='\033[0;32m'
COLOR_REGULAR_YELLOW='\033[0;33m'
COLOR_REGULAR_BLUE='\033[0;34m'
COLOR_REGULAR_PURPLE='\033[0;35m'
COLOR_REGULAR_CYAN='\033[0;36m'
COLOR_REGULAR_WHITE='\033[0;37m'

# Bold
COLOR_BOLD_BLACK='\033[1;30m'
COLOR_BOLD_RED='\033[1;31m'
COLOR_BOLD_GREEN='\033[1;32m'
COLOR_BOLD_YELLOW='\033[1;33m'
COLOR_BOLD_BLUE='\033[1;34m'
COLOR_BOLD_PURPLE='\033[1;35m'
COLOR_BOLD_CYAN='\033[1;36m'
COLOR_BOLD_WHITE='\033[1;37m'

## META - color [END]

## Directories >> work

CH_INSTALL_DIRECTORY='/root/chitanka/'
CH_INSTALL_WORK_DIRECTORY='/root/chitanka/work/'
CH_INSTALL_LOG='/root/chitanka/install.log'

## Directories >> production

CH_WEB_DIRECTORY='/var/www/chitanka'
CH_WEB_DIRECTORY_WEB='/var/www/chitanka/web'
CH_WEB_DIRECTORY_CONFIG='/var/www/chitanka/app/config'
CH_WEB_CONFIG_DOWNLOAD='http://download.chitanka.info/parameters.yml'

## Work files

CH_INSTALL_LOG='/root/chitanka/install.log'

## Apache2 section
FCGID_WRAPPER='/usr/local/bin/php-fcgid-wrapper'
CH_VHOST_DOWNLOAD='http://download.chitanka.info/chitanka-mirror.conf'

## MariaDB section

MYSQL_SERVICE_PASSWORD='cH-00-service_paS$W'
MYSQL_EXEC='which mysql'
MYSQL_CH_USER='chitanka'
MYSQL_CH_USER_PASSWORD='chitanka-mirror'
MYSQL_CH_DATABASE='chitanka'
MYSQL_DWN_DATABASE='http://download.chitanka.info/chitanka.sql.gz'


##################################

function mirror(){

clear

unset LANG

mkdir $CH_INSTALL_DIRECTORY

mkdir $CH_INSTALL_WORK_DIRECTORY

touch $CH_INSTALL_LOG

echo "Инсталацията е започната на $DATE година в `date +"%T"` часа." > $CH_INSTALL_LOG

# are you root?

if [ "$(id -u)" != "0" ]; then
   echo -e "${COLOR_BOLD_RED}Инсталаторът трябва да бъде стартиран с ${COLOR_BOLD_WHITE}root${COLOR_RESET} потребител!${COLOR_RESET}" 1>&2
   exit 1
fi

echo "`date +"%T"` Инсталаторът беше стартиран с root потребител." >> $CH_INSTALL_LOG

# check if distributions is Debian

check_distribution=`cat /etc/issue | grep 'Debian' | wc -l`
if [[ $check_distribution -lt 1 ]]; then
    echo -e "${COLOR_BOLD_RED} Опа! Вашата Linux дистрибуция е различна от Debian. Следва изход. ${COLOR_RESET}\\n"
    exit 1;
fi

export DEBIAN_FRONTEND=noninteractive

echo "`date +"%T"` Вашата дистрибуция е Debian базирана - инсталацията може да започне." >> $CH_INSTALL_LOG

# if you are root and distribution is Debian, let's rock


# splash screen

echo -e 
echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
echo -e "${COLOR_BOLD_YELLOW}*${COLOR_RESET} ${COLOR_BOLD_WHITE}       Читанка - автоматичен инсталатор       ${COLOR_RESET} ${COLOR_BOLD_YELLOW}*${COLOR_RESET}"
#echo -e "${COLOR_BOLD_YELLOW}*${COLOR_RESET} ${COLOR_BOLD_WHITE}       -------------------------------       ${COLOR_RESET} ${COLOR_BOLD_YELLOW}*${COLOR_RESET}"
echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"

echo -e "${COLOR_BOLD_WHITE} След секунди ще започне процедура по автоматичната инсталация ${COLOR_RESET}"
echo -e "${COLOR_BOLD_WHITE} на необходимия софтуер на МОЯТА БИБЛИОТЕКА.${COLOR_RESET}"
echo -e
echo -e "${COLOR_BOLD_WHITE} За коректната работа на софтуера, необходимо е:${COLOR_RESET}"
echo -e "${COLOR_BOLD_WHITE} 1) Инсталаторът е стартиран с ${COLOR_BOLD_RED}root${COLOR_RESET} ${COLOR_BOLD_WHITE}потребител ${COLOR_RESET}"
echo -e "${COLOR_BOLD_WHITE} 2) Компютърът е включен към електрическата мрежа ${COLOR_RESET}"
echo -e "${COLOR_BOLD_WHITE} 3) Компютърът има достъп до Интернет${COLOR_RESET}"
echo -e "${COLOR_BOLD_WHITE} 4) Разполагате с най-малко 20 гигабайта дисково пространство${COLOR_RESET}"
echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
echo -e
# sleep for seven seconds 
#sleep 3

#read -p "Желаете ли да продължите? Въведете yes за съгласие:" SPSCREEN_INPUT

#if [ "$SPSCREEN_INPUT" = yes ] ; then
#   echo -e "${COLOR_BOLD_GREEN} Избрахте да продължите. Започва процедурата по обновяване на операционната Ви система: ${COLOR_RESET}"
#	sleep 3
#	apt-get update && apt-get upgrade
#elif [ "$SPSCREEN_INPUT" = no ] ; then
#   echo -e "${COLOR_BOLD_RED} Избрахте да прекратите процедурата по инсталация на огледалото. Следва изход.${COLOR_RESET}"
#	exit 2
#else
#   echo -e "${COLOR_BOLD_RED} Избрахте несъществуващ отговор. Следва изход. Можете да стартирате процедурата по инсталация отново.${COLOR_RESET}"
#fi

# splash screen

echo -e "${COLOR_BOLD_GREEN} Желаете ли процедурата по инсталация да започне? Изберете y (да) или n (не).${COLOR_RESET}"
read yn
yn=${yn:-y}
if [ "$yn" != "y" ]; then
  echo -e "${COLOR_BOLD_RED} Избрахте да прекратите процедурата по инсталация на огледалото. Следва изход.${COLOR_RESET}"
  echo "`date +"%T"` Инсталацията беше прекратена по желание на потребителя." >> $CH_INSTALL_LOG
  exit
fi

echo "`date +"%T"` Избрахте да продължите инсталацията." >> $CH_INSTALL_LOG

sleep 1

clear

echo -e "${COLOR_BOLD_GREEN} Започва процедурата по обновяване на операционната Ви система. ${COLOR_RESET}"

sleep 1

apt-get update -y && apt-get upgrade -y

echo "`date +"%T"` Вашата операционна система е успешно обновена." >> $CH_INSTALL_LOG

# install "basic" software packages:

sleep 1

clear

echo -e "${COLOR_BOLD_GREEN} Инсталация на системен софтуер. ${COLOR_RESET}"

sleep 2

apt-get install -y build-essential software-properties-common curl wget rsync git screen

echo "`date +"%T"` Инсталиран е необходимия системен софтуер." >> $CH_INSTALL_LOG

# install apache2, PHP5, mod_fcgid

clear

echo -e "${COLOR_BOLD_GREEN} Започва инсталацията на уеб сървъра. ${COLOR_RESET}"

sleep 2

apt-get install -y apache2 libapache2-mod-fcgid apache2-mpm-worker php5 php5-cgi

# enable mod_fcgid

a2enmod fcgid

# let's create fcgid wrapper

touch $FCGID_WRAPPER

echo "#!/bin/sh" > $FCGID_WRAPPER
echo "#Add desired PHP_FCGI_* variables" >> $FCGID_WRAPPER
echo "PHP_FCGI_MAX_REQUESTS=10000" >> $FCGID_WRAPPER
echo "export PHP_FCGI_MAX_REQUESTS" >> $FCGID_WRAPPER
echo "" >> $FCGID_WRAPPER
echo "exec /usr/bin/php-cgi" >> $FCGID_WRAPPER

chmod +x $FCGID_WRAPPER

echo "`date +"%T"` fcgid wrapper-ът е създаден." >> $CH_INSTALL_LOG

# let's download and enable chitanka-mirror vhost

cd $CH_INSTALL_WORK_DIRECTORY

cat /dev/null > /etc/apache2/sites-enabled/000-default.conf

wget $CH_VHOST_DOWNLOAD

cat chitanka-mirror.conf > /etc/apache2/sites-enabled/000-default.conf

### TO-DO: CHOOSE DOMAIN

clear

echo -e "${COLOR_BOLD_WHITE} По подразбиране, в конфигурацията е заложено домейн името chitanka.local. В случай, че разполагате със собствено домейн име, бихте могли да го използвате за конфигурацията на огледалото.${COLOR_RESET}"

echo -e ""

echo -e "${COLOR_BOLD_WHITE} Желаете ли да използвате свое домейн име? Изберете (y) за да посочите свой домейн или (n) за да продължи инсталацията с домейн chitanka.local.${COLOR_RESET}"

read yn

sleep 2

yn=${yn:-y}
if [ "$yn" = "n" ]; then

  echo -e "${COLOR_BOLD_GREEN} Избрахте да използвате служебното име chitanka.local. Инсталацията продължава.${COLOR_RESET}"
  
  echo "`date +"%T"` Избрано домейн име за инсталацията: служебно (chitanka.local)." >> $CH_INSTALL_LOG

  sed -i -e '1i\'"127.0.0.1	chitanka.local" /etc/hosts

  echo "`date +"%T"` Избран е заложения по подразбиране домейн chitanka.local." >> $CH_INSTALL_LOG
	
  else 

  echo -e "${COLOR_BOLD_WHITE} Моля, въведете желаното домейн име: ${COLOR_RESET}"  

  read own_domain_name

  sleep 2

  echo -e "${COLOR_BOLD_RED} Избрахте домейн името: $own_domain_name ${COLOR_RESET}"

  sed -i "s/chitanka.local/$own_domain_name/g" /etc/apache2/sites-enabled/000-default.conf

  sed -i -e '1i\'"127.0.0.1	$own_domain_name" /etc/hosts

  echo "`date +"%T"` Избран е различен от заложения домейн: $own_domain_name и е добавен в конфигурационните файлове." >> $CH_INSTALL_LOG

fi

mkdir $CH_WEB_DIRECTORY

mkdir $CH_WEB_DIRECTORY_WEB

echo '<?php phpinfo(); ?>' > $CH_WEB_DIRECTORY_WEB/p.php

a2enmod rewrite
a2enmod expires
a2enmod headers

apt-get install -y php5-gd php5-curl php5-xsl php5-intl

/etc/init.d/apache2 restart

echo "`date +"%T"` Виртуалният хост е създаден успешно." >> $CH_INSTALL_LOG

### TO-DO: TEST IF WORKS AS FastCGI!!!


# install MariaDB with service password

clear

echo -e "${COLOR_BOLD_GREEN} Инсталация на MariaDB база данни. ${COLOR_RESET}"

sleep 2

debconf-set-selections <<< "mariadb-server mysql-server/root_password password $MYSQL_SERVICE_PASSWORD"
debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $MYSQL_SERVICE_PASSWORD"
apt-get -y install mariadb-server
apt-get -y install php5-mysql

echo "`date +"%T"` Инсталирана е MariaDB база данни със служебна парола: $MYSQL_SERVICE_PASSWORD" >> $CH_INSTALL_LOG

# add MariaDB user, password and database for chitanka

clear

echo -e "${COLOR_BOLD_GREEN} Създаване на потребителско име и база данни за огледалото. ${COLOR_RESET}"

sleep 2

# queries skel.

CH_DB_CREATE_USER="CREATE USER '$MYSQL_CH_USER'@'localhost' IDENTIFIED BY '$MYSQL_CH_USER_PASSWORD';"
CH_DB_GRANT_PRIVILEGES="GRANT ALL PRIVILEGES ON * . * TO '$MYSQL_CH_USER'@'localhost';"
CH_DB_FLUSH_PRIVILEGES="FLUSH PRIVILEGES;"
CH_DB_CREATE_DATABASE="CREATE DATABASE $MYSQL_CH_DATABASE;"

# generate queries

CH_DB_QUERY_1="${CH_DB_CREATE_USER} ${CH_DB_GRANT_PRIVILEGES} ${CH_DB_FLUSH_PRIVILEGES}"
CH_DB_QUERY_2="$CH_DB_CREATE_DATABASE"

# execute queries

mysql -uroot -p'cH-00-service_paS$W' -e "${CH_DB_QUERY_1}"
mysql -uroot -p'cH-00-service_paS$W' -e "${CH_DB_QUERY_2}"

# add result in log

echo "`date +"%T"` Създаден е MySQL потребител със служебна парола: $MYSQL_CH_USER_PASSWORD" >> $CH_INSTALL_LOG
echo "`date +"%T"` Създадена е MySQL база данни: $MYSQL_CH_DATABASE" >> $CH_INSTALL_LOG

# download MySQL database

cd ${CH_INSTALL_WORK_DIRECTORY}
wget ${MYSQL_DWN_DATABASE}
gunzip chitanka.sql.gz

mysql -uchitanka -p'chitanka-mirror' ${MYSQL_CH_DATABASE} < ${CH_INSTALL_WORK_DIRECTORY}chitanka.sql

echo "`date +"%T"` Базата данни за огледалото е внесена." >> $CH_INSTALL_LOG

# clone chitanka code from github

clear

echo -e "${COLOR_BOLD_GREEN} Клониране на код от хранилището в github. ${COLOR_RESET}"

sleep 2

cd /var/www/

rm -rf chitanka/

rm -rf html/

git clone https://github.com/chitanka/chitanka-production.git chitanka

echo "`date +"%T"` Програмният код е успешно клониран от GitHub хранилището." >> $CH_INSTALL_LOG

# download configuration file

cd $CH_WEB_DIRECTORY_CONFIG

wget $CH_WEB_CONFIG_DOWNLOAD

echo "`date +"%T"` Конфигурационният файл е свален." >> $CH_INSTALL_LOG

# set permissions for cache, log and spool directory

cd $CH_WEB_DIRECTORY

chmod -R a+w var/cache var/log var/spool web/cache

echo "`date +"%T"` Правата за cache, log и spool директориите са променени." >> $CH_INSTALL_LOG

# final step - move log in web directory and delete work directory

cp $CH_INSTALL_DIRECTORY/install.log $CH_WEB_DIRECTORY_WEB/install.log

rm -rf $CH_INSTALL_DIRECTORY


}

function dwncontent()
{

	# rsync content

	clear

	echo -e "${COLOR_BOLD_GREEN} Сваляне на съдържанието. ${COLOR_RESET}"

	sleep 2
	
	cd $CH_WEB_DIRECTORY
	
	echo "`date +"%T"` rsync процедурата е СТАРТИРАНА" >> $CH_WEB_DIRECTORY_WEB/install.log

	rsync -avz --delete rsync.chitanka.info::content/ content

	echo "`date +"%T"` rsync процедурата ПРИКЛЮЧИ" >> $CH_WEB_DIRECTORY_WEB/install.log

}

function destroy(){

# remove chitanka web directory

rm -rf $CH_WEB_DIRECTORY

# drop database

mysql -uroot -p'cH-00-service_paS$W' -e "DROP DATABASE chitanka"

echo -e "${COLOR_BOLD_RED} Файловото съдържание и базата данни на Моята библиотека бяха премахнати от сървъра. ${COLOR_RESET}"

echo && echo

echo -e "${COLOR_BOLD_RED} Запазена е единствено конфигурацията на уеб сървъра. ${COLOR_RESET}"


}

function changedomain(){

  echo -e "${COLOR_BOLD_WHITE} Моля, въведете желаното домейн име: ${COLOR_RESET}"  

  read own_domain_name

  echo -e "${COLOR_BOLD_RED} Избрахте домейн името: $own_domain_name ${COLOR_RESET}"

  sed -i "s/chitanka.local/$own_domain_name/g" /etc/apache2/sites-enabled/000-default.conf

  sed -i -e '1i\'"127.0.0.1	$own_domain_name" /etc/hosts

}

case "$1" in
   mirror)
      mirror
   ;;
   dwncontent)
      dwncontent
   ;;
   destroy)
	  destroy
   ;;
   changedomain)
      changedomain
   ;;
   *)
      echo "Опитайте така: $0 mirror"
esac