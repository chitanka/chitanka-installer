#!/bin/bash

##
#
# version: 1-alpha
# last_build: 22.04.2016
#
##

## General

DATE=`date +"%d.%m.%Y"`

## META - colors [START]

# Reset
COLOR_RESET='\033[0m'

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

MYSQL_ROOT="mysql -uroot -p'${MYSQL_SERVICE_PASSWORD}'"
MYSQL_CHITANKA="mysql -u${MYSQL_CH_USER} -p'${MYSQL_CH_USER_PASSWORD}' ${MYSQL_CH_DATABASE}"

INSTALL_PKG='apt-get install -y'

CHITANKA_GIT='https://github.com/chitanka/chitanka-production.git'
CHITANKA_RSYNC_CONTENT='rsync.chitanka.info::content'

DEFAULT_DOMAIN='chitanka.local'

##################################

color_echo () {
	echo -e $1$2$COLOR_RESET
}

log () {
	logfile=${2:-$CH_INSTALL_LOG}
	log "$1" >> $logfile
}

rsync_content () {
	color_echo $COLOR_BOLD_GREEN "Сваляне на съдържанието."

	sleep 2

	cd $CH_WEB_DIRECTORY_WEB

	log "rsync процедурата е СТАРТИРАНА" $CH_WEB_DIRECTORY_WEB/install.log

	rsync -avz --delete ${CHITANKA_RSYNC_CONTENT}/ content

	log "rsync процедурата ПРИКЛЮЧИ" $CH_WEB_DIRECTORY_WEB/install.log
}

function mirror(){

clear

unset LANG

mkdir $CH_INSTALL_DIRECTORY

mkdir $CH_INSTALL_WORK_DIRECTORY

touch $CH_INSTALL_LOG

log "Начало на инсталацията на $DATE"

# are you root?

if [ "$(id -u)" != "0" ]; then
   color_echo $COLOR_BOLD_RED "Инсталаторът трябва да бъде стартиран с ${COLOR_BOLD_WHITE}root${COLOR_RESET} потребител!" 1>&2
   exit 1
fi

log "Инсталаторът беше стартиран с root потребител."

# check if distributions is Debian

check_distribution=`cat /etc/os-release | grep ID | grep debian`
if [[ $check_distribution != "ID=debian" ]]; then
    color_echo $COLOR_BOLD_RED "Опа! Вашата Linux дистрибуция е различна от Debian. Следва изход.\\n"
    exit 1;
fi

export DEBIAN_FRONTEND=noninteractive

log "Вашата дистрибуция е Debian базирана - инсталацията може да започне."

# if you are root and distribution is Debian, let's rock


# splash screen

echo
echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
echo -e "${COLOR_BOLD_YELLOW}*${COLOR_RESET} ${COLOR_BOLD_WHITE}       Читанка - автоматичен инсталатор       ${COLOR_RESET} ${COLOR_BOLD_YELLOW}*${COLOR_RESET}"
echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"

color_echo $COLOR_BOLD_WHITE "След секунди ще започне процедура по автоматичната инсталация"
color_echo $COLOR_BOLD_WHITE "на необходимия софтуер на МОЯТА БИБЛИОТЕКА."
echo
color_echo $COLOR_BOLD_WHITE "За коректната работа на софтуера, необходимо е:"
echo -e "${COLOR_BOLD_WHITE} 1) Инсталаторът е стартиран с ${COLOR_BOLD_RED}root${COLOR_RESET} ${COLOR_BOLD_WHITE}потребител ${COLOR_RESET} (ОК)"
echo -e "${COLOR_BOLD_WHITE} 2) Използваната дистрибуция да е ${COLOR_BOLD_RED}Debian${COLOR_RESET} ${COLOR_RESET} (OK)"
color_echo $COLOR_BOLD_WHITE "3) Разполагате с най-малко 20 гигабайта дисково пространство"
color_echo $COLOR_BOLD_WHITE "4) Да не прекъсвате процеса по инсталация, докато не приключи"
echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
echo

color_echo $COLOR_BOLD_GREEN "Желаете ли процедурата по инсталация да започне? Изберете y (да) или n (не)."
read yn
yn=${yn:-y}
if [ "$yn" != "y" ]; then
  color_echo $COLOR_BOLD_RED "Избрахте да прекратите процедурата по инсталация на огледалото. Следва изход."
  log "Инсталацията беше прекратена по желание на потребителя."
  exit
fi

log "Избрахте да продължите инсталацията."

sleep 1

clear

color_echo $COLOR_BOLD_GREEN "Започва процедурата по обновяване на операционната Ви система."

sleep 1

apt-get update -y && apt-get upgrade -y

log "Вашата операционна система е успешно обновена."

# install "basic" software packages:

sleep 1

clear

color_echo $COLOR_BOLD_GREEN "Инсталация на системен софтуер."

sleep 2

$INSTALL_PKG build-essential software-properties-common curl wget rsync git screen

log "Инсталиран е необходимия системен софтуер."

# install apache2, PHP5, mod_fcgid

clear

color_echo $COLOR_BOLD_GREEN "Започва инсталацията на уеб сървъра."

sleep 2

$INSTALL_PKG apache2 libapache2-mod-fcgid apache2-mpm-worker php5 php5-cgi

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

log "fcgid wrapper-ът е създаден."

# let's download and enable chitanka-mirror vhost

cd $CH_INSTALL_WORK_DIRECTORY

cat /dev/null > /etc/apache2/sites-enabled/000-default.conf

wget $CH_VHOST_DOWNLOAD

cat chitanka-mirror.conf > /etc/apache2/sites-enabled/000-default.conf

### select domain

clear

color_echo $COLOR_BOLD_WHITE "По подразбиране, в конфигурацията е заложено домейн името ${DEFAULT_DOMAIN}. В случай че разполагате със собствено домейн име, бихте могли да го използвате за конфигурацията на огледалото."

echo

color_echo $COLOR_BOLD_WHITE "Желаете ли да използвате свое домейн име? Изберете (y) за да посочите свой домейн или (n) за да продължи инсталацията с домейн ${DEFAULT_DOMAIN}."

read yn

sleep 2

yn=${yn:-y}
if [ "$yn" = "n" ]; then

  color_echo $COLOR_BOLD_GREEN "Избрахте да използвате служебното име ${DEFAULT_DOMAIN}. Инсталацията продължава."

  log "Избрано домейн име за инсталацията: служебно (${DEFAULT_DOMAIN})."

  sed -i -e '1i\'"127.0.0.1	${DEFAULT_DOMAIN}" /etc/hosts

  log "Избран е заложения по подразбиране домейн ${DEFAULT_DOMAIN}."

  else

  color_echo $COLOR_BOLD_WHITE "Моля, въведете желаното домейн име:"

  read own_domain_name

  sleep 2

  color_echo $COLOR_BOLD_RED "Избрахте домейн името: $own_domain_name"

  sed -i "s/${DEFAULT_DOMAIN}/$own_domain_name/g" /etc/apache2/sites-enabled/000-default.conf

  sed -i -e '1i\'"127.0.0.1	$own_domain_name" /etc/hosts

  log "Избран е различен от заложения домейн: $own_domain_name и е добавен в конфигурационните файлове."

fi

mkdir $CH_WEB_DIRECTORY

mkdir $CH_WEB_DIRECTORY_WEB

echo '<?php phpinfo(); ?>' > $CH_WEB_DIRECTORY_WEB/p.php

a2enmod rewrite
a2enmod expires
a2enmod headers

$INSTALL_PKG php5-gd php5-curl php5-xsl php5-intl

/etc/init.d/apache2 restart

log "Виртуалният хост е създаден успешно."

### TO-DO: TEST IF WORKS AS FastCGI!!!


# install MariaDB with service password

clear

color_echo $COLOR_BOLD_GREEN "Инсталация на MariaDB база данни."

sleep 2

debconf-set-selections <<< "mariadb-server mysql-server/root_password password $MYSQL_SERVICE_PASSWORD"
debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $MYSQL_SERVICE_PASSWORD"
$INSTALL_PKG mariadb-server php5-mysql

log "Инсталирана е MariaDB база данни със служебна парола: $MYSQL_SERVICE_PASSWORD"

# add MariaDB user, password and database for chitanka

clear

color_echo $COLOR_BOLD_GREEN "Създаване на потребителско име и база данни за огледалото."

sleep 2

# queries skel.

$MYSQL_ROOT -e "CREATE USER '$MYSQL_CH_USER'@'localhost' IDENTIFIED BY '$MYSQL_CH_USER_PASSWORD'"
$MYSQL_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_CH_USER'@'localhost'"
$MYSQL_ROOT -e "FLUSH PRIVILEGES"
$MYSQL_ROOT -e "CREATE DATABASE $MYSQL_CH_DATABASE"

# add result in log

log "Създаден е MySQL потребител със служебна парола: $MYSQL_CH_USER_PASSWORD"
log "Създадена е MySQL база данни: $MYSQL_CH_DATABASE"

# download MySQL database

cd ${CH_INSTALL_WORK_DIRECTORY}
wget ${MYSQL_DWN_DATABASE}
gunzip -c `basename $MYSQL_DWN_DATABASE` | $MYSQL_CHITANKA

log "Базата данни за огледалото е внесена."

# clone chitanka code from github

clear

color_echo $COLOR_BOLD_GREEN "Клониране на код от хранилището в github."

sleep 2

cd /var/www/

rm -rf chitanka/

rm -rf html/

git clone $CHITANKA_GIT chitanka

log "Програмният код е успешно клониран от GitHub хранилището."

# download configuration file

cd $CH_WEB_DIRECTORY_CONFIG

wget $CH_WEB_CONFIG_DOWNLOAD

log "Конфигурационният файл е свален."

# set permissions for cache, log and spool directory

cd $CH_WEB_DIRECTORY

chmod -R a+w var/cache var/log var/spool web/cache

log "Правата за cache, log и spool директориите са променени."

# and finally - get content

color_echo $COLOR_BOLD_GREEN "Желаете ли да свалите съдържанието към текущата дата - `date +"%d-%m-%y"`? Изберете y (да) или n (не)."
read yn
yn=${yn:-y}
if [ "$yn" != "y" ]; then
  echo -e "${COLOR_BOLD_GREEN} Огледалната версия на огледалото е успешно инсталирана, но избрахте да ${COLOR_BOLD_RED}НЕ${COLOR_RESET} сваляте съдържание.${COLOR_RESET}"
  color_echo $COLOR_BOLD_GREEN "Можете да споделите адреса на Вашето огледало във форума на Моята библитека:"
  color_echo $COLOR_BOLD_GREEN "https://forum.chitanka.info"
  log "Избрана е опция да не бъде сваляно съдържание."
  exit
fi

	clear
	rsync_content

# final step - move log in web directory and delete work directory

cp $CH_INSTALL_DIRECTORY/install.log $CH_WEB_DIRECTORY_WEB/install.log

rm -rf $CH_INSTALL_DIRECTORY

}

function destroy(){

# remove chitanka web directory

rm -rf $CH_WEB_DIRECTORY

# drop database

$MYSQL_ROOT -e "DROP DATABASE ${MYSQL_CH_DATABASE}"

color_echo $COLOR_BOLD_RED "Файловото съдържание и базата данни на Моята библиотека бяха премахнати от сървъра."

echo && echo

color_echo $COLOR_BOLD_RED "Запазена е единствено конфигурацията на уеб сървъра."

}

function changedomain(){

  color_echo $COLOR_BOLD_WHITE "Моля, въведете желаното домейн име:"

  read own_domain_name

  color_echo $COLOR_BOLD_RED "Избрахте домейн името: $own_domain_name"

  sed -i "s/${DEFAULT_DOMAIN}/$own_domain_name/g" /etc/apache2/sites-enabled/000-default.conf

  sed -i -e '1i\'"127.0.0.1	$own_domain_name" /etc/hosts

}

function addcron(){

crontab -l > chitanka_cron

echo "PASTE HERE THE RIGHT COMMAND" >> chitanka_cron

crontab chitanka_cron

rm -f chitanka_cron

}

case "$1" in
   mirror)
      mirror
   ;;
   getcontent)
      rsync_content
   ;;
   destroy)
	  destroy
   ;;
   changedomain)
      changedomain
   ;;
   addcron)
      addcron
   ;;
   *)
	  echo
      color_echo $COLOR_BOLD_RED "Невалидна команда. Моля, запознайте се с опциите за стартиране на инсталатора"
	  echo
      echo -e "Правилният начин за стартиране на инсталатора е:\n\n\t${COLOR_BOLD_GREEN}$0${COLOR_RESET} ${COLOR_BOLD_WHITE}команда${COLOR_RESET}"
	  echo
	  echo -e "Можете да използвате следните команди:"
	  echo -e "${COLOR_BOLD_WHITE} mirror ${COLOR_RESET}       - автоматична инсталация и конфигурация на огледало на Моята библиотека"
	  echo -e "${COLOR_BOLD_WHITE} getcontent ${COLOR_RESET}   - сваляне на съдържание за огледалото на Моята библитека (съществува като опция при процеса ${COLOR_BOLD_WHITE} mirror ${COLOR_RESET}"
	  echo -e "${COLOR_BOLD_WHITE} destroy ${COLOR_RESET}      - изтрива съдържанието на вече инсталирано огледало на Моята библиотека"
      echo -e "${COLOR_BOLD_WHITE} changedomain ${COLOR_RESET} - можете да изберете нов домейн, който да бъде конфигуриран в уеб сървъра"
	  echo -e "${COLOR_BOLD_WHITE} addcron ${COLOR_RESET}      - добавят се cron задачите, необходими за обновяването на огледалото"
	  echo
esac
