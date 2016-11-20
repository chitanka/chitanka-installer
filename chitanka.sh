#!/usr/bin/env bash

INSTALLER_GIT=https://github.com/chitanka/chitanka-installer.git
INSTALLER_DIR=${INSTALLER_DIR:-/root/chitanka-installer}
INSTALL_LOG=`dirname $0`/install.log
CHITANKA_DIR=/var/www/chitanka
CHITANKA_GIT='https://github.com/chitanka/chitanka-production.git'
CHITANKA_RSYNC_CONTENT='rsync.chitanka.info::content'
DEFAULT_DOMAIN='chitanka.local'
DISTRIBUTION=`awk -F'=' '/ID/ {print $2}' /etc/os-release`

## Web server section
FCGID_WRAPPER_TARGET=/usr/local/bin

## Database section
MYSQL_SERVICE_PASSWORD='cH-00-service_paS$W'
MYSQL_CH_USER='chitanka'
MYSQL_CH_USER_PASSWORD='chitanka'
MYSQL_CH_DATABASE='chitanka'
MYSQL_DB_DUMP='http://download.chitanka.info/chitanka.sql.gz'
MYSQL_ROOT="mysql -uroot -p${MYSQL_SERVICE_PASSWORD}"
MYSQL_CHITANKA="mysql -u${MYSQL_CH_USER} -p${MYSQL_CH_USER_PASSWORD} ${MYSQL_CH_DATABASE}"

INSTALL_PKG_DEBIAN='apt install -y'
INSTALL_PKG_CENTOS='yum install -y'
INSTALL_PKG_FEDORA='dnf install -y'

source extra/colors

##################################

install() {
	# only root is allowed to execute the installer
	if [ "$(id -u)" != "0" ]; then
		color_echo $COLOR_BOLD_RED "Инсталаторът трябва да бъде стартиран с потребител ${COLOR_BOLD_WHITE}root${COLOR_RESET}!" 1>&2
		exit 1
	fi

	log "Начало на инсталацията"

	clear
	splash_screen

	color_echo $COLOR_BOLD_GREEN "Желаете ли процедурата по инсталация да започне? Изберете y (да) или n (не)."
	read yn
	yn=${yn:-y}
	if [ "$yn" != "y" ]; then
		color_echo $COLOR_BOLD_RED "Избрахте да прекратите процедурата по инсталация на огледалото. Следва изход."
		log "Инсталацията беше прекратена по желание на потребителя."
		exit
	fi

	unset LANG
	export DEBIAN_FRONTEND=noninteractive

	clear
	#detect_linux_distribution

	clear
	update_system
	sleep 1

	clear
	install_basic_packages

	clear
	#install_web_server

	clear
	#set_domain
	sleep 3

	clear
	#install_db_server

	clear
	#create_chitanka_db

	clear
	#install_chitanka_software
	#get_chitanka_content

	echo_success
}

uninstall () {
	rm -rf $CHITANKA_DIR
	rm -rf $INSTALLER_DIR

	# drop database
	$MYSQL_ROOT -e "DROP DATABASE ${MYSQL_CH_DATABASE}"

	color_echo $COLOR_BOLD_RED "Файловото съдържание и базата данни на Моята библиотека бяха премахнати от сървъра."
	echo && echo
	color_echo $COLOR_BOLD_RED "Запазена е единствено конфигурацията на уеб сървъра."
}

changedomain () {
	color_echo $COLOR_BOLD_WHITE "Моля, въведете желаното домейн име:"
	read own_domain_name
	color_echo $COLOR_BOLD_RED "Избрахте домейн името: $own_domain_name"

	set_domain_in_webhost $own_domain_name
	set_domain_in_localhost $own_domain_name
	restart_web_server
}

addcron () {
	crontab -l > chitanka_cron
	echo "0 0 * * * ${CHITANKA_DIR}/bin/update" >> chitanka_cron
	crontab chitanka_cron
	rm -f chitanka_cron
}

show_help () {
	echo
	echo -e "Употреба на инсталатора:\n\n\t${COLOR_BOLD_GREEN}$0${COLOR_RESET} ${COLOR_BOLD_WHITE}команда${COLOR_RESET}"
	echo
	echo -e "Можете да използвате следните команди:"
	echo -e "${COLOR_BOLD_WHITE} install ${COLOR_RESET}      - автоматична инсталация и конфигурация на огледало на Моята библиотека"
	echo -e "${COLOR_BOLD_WHITE} getcontent ${COLOR_RESET}   - сваляне на съдържание за огледалото на Моята библиотека (може да бъде изпълнено и при командата ${COLOR_BOLD_WHITE}install${COLOR_RESET})"
	echo -e "${COLOR_BOLD_WHITE} changedomain ${COLOR_RESET} - можете да изберете нов домейн, който да бъде конфигуриран в уеб сървъра"
	echo -e "${COLOR_BOLD_WHITE} addcron ${COLOR_RESET}      - добавят се cron задачите, необходими за обновяването на огледалото"
	echo -e "${COLOR_BOLD_WHITE} uninstall ${COLOR_RESET}    - изтрива съдържанието на вече инсталирано огледало на Моята библиотека"
	echo -e "${COLOR_BOLD_WHITE} fix-ubuntu ${COLOR_RESET}	 - поправя инсталацията върху Ubuntu 16.04 и по-нови версии"
	echo
}

splash_screen () {
	echo
	echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
	echo -e "${COLOR_BOLD_YELLOW}*${COLOR_RESET} ${COLOR_BOLD_WHITE}       Читанка - автоматичен инсталатор       ${COLOR_RESET} ${COLOR_BOLD_YELLOW}*${COLOR_RESET}"
	echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
	color_echo $COLOR_BOLD_WHITE "След секунди ще започне инсталацията на необходимия софтуер за МОЯТА БИБЛИОТЕКА."
	echo
	color_echo $COLOR_BOLD_WHITE "За правилната работа на софтуера е необходимо:"
	color_echo $COLOR_BOLD_WHITE "1) Да разполагате с най-малко 20 гигабайта дисково пространство."
	color_echo $COLOR_BOLD_WHITE "2) Да не прекъсвате процеса по инсталация, докато не приключи."
	echo -e "${COLOR_BOLD_YELLOW}**************************************************${COLOR_RESET}"
	echo
}

update_system () {
	color_echo $COLOR_BOLD_GREEN "Започва обновяване на операционната система."
	sleep 1
	apt update -y
	#apt upgrade -y
	log "Операционната система беше обновена."
}

detect_linux_distribution () {

	# detect which linux distribution is used on host
	lsb_release -is > work.os-distribution
	log "Инсталираната дистрибуиция е записана в работния файл."
}

fix_ubuntu_issues () {
	
	# setting the right php-fpm socket
	sed -i "s\/\/var\/run\/php5-fpm.sock;/\/var\/run/php\/php7.0-fpm.sock;/g" /etc/nginx/sites-enabled/chitanka
	# fix path to fpm socket in www.config
	
	/etc/init.d/php*-fpm restart

}

install_basic_packages () {

	if [[ "$DISTRIBUTION" == "debian" ]]; then
        
	color_echo $COLOR_BOLD_GREEN "Инсталация на системен софтуер."
	sleep 2
	$INSTALL_PKG_DEBIAN git curl rsync elinks
	log "Инсталиран е необходимият системен софтуер."
	if [ ! -d $INSTALLER_DIR ]; then
		git clone $INSTALLER_GIT $INSTALLER_DIR
	fi

	elif [[ "$DISTRIBUTION" == "ubuntu" ]]; then
	
	color_echo $COLOR_BOLD_GREEN "Инсталация на системен софтуер."
	sleep 2
	$INSTALL_PKG_DEBIAN git curl rsync elinks
	log "Инсталиран е необходимият системен софтуер."
	if [ ! -d $INSTALLER_DIR ]; then
		git clone $INSTALLER_GIT $INSTALLER_DIR
	fi
	
	elif [[ "$DISTRIBUTION" == "centos" ]]; then
	
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "fedora" ]]; then
	
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "opensuse" ]]; then

	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "arch" ]]; then
	
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "freebsd" ]]; then
	 
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	else

	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	fi
}

install_web_server () {

	if [[ "$DISTRIBUTION" == "debian" ]]; then
        
	color_echo $COLOR_BOLD_GREEN "Започва инсталацията на уеб сървъра."
	sleep 2
	$INSTALL_PKG_DEBIAN nginx php-fpm php-gd php-curl php-xsl php-intl
	cp $INSTALLER_DIR/nginx-vhost.conf /etc/nginx/sites-enabled/chitanka

	elif [[ "$DISTRIBUTION" == "ubuntu" ]]; then
	
	color_echo $COLOR_BOLD_GREEN "Започва инсталацията на уеб сървъра."
	sleep 2
	$INSTALL_PKG_DEBIAN nginx php-fpm php-gd php-curl php-xsl php-intl
	cp $INSTALLER_DIR/nginx-vhost.conf /etc/nginx/sites-enabled/chitanka

	fix_ubuntu_issues
	
	elif [[ "$DISTRIBUTION" == "centos" ]]; then
	
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "fedora" ]]; then
	
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "opensuse" ]]; then

	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "arch" ]]; then
	
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	elif [[ "$DISTRIBUTION" == "freebsd" ]]; then
	 
	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	else

	color_echo $COLOR_BOLD_RED "За съжаление към момента инсталаторът не поддържа Вашата GNU/Linux дистрибуция."
	color_echo $COLOR_BOLD_WHITE "Следва изход."
	log "Инсталаията не може да бъде извършена, тъй като дистрибуцията не се поддържа към момента."
	exit

	fi
}

restart_web_server () {
	service nginx restart
	service php*-fpm restart
	#service apache2 restart
}

set_domain () {
	color_echo $COLOR_BOLD_WHITE "По подразбиране, в конфигурацията е заложен домейн ${DEFAULT_DOMAIN}. В случай че разполагате със собствен домейн, бихте могли да го използвате за конфигурацията на огледалото."
	echo
	color_echo $COLOR_BOLD_WHITE "Желаете ли да използвате свой домейн? Изберете (y) за да посочите свой домейн или (n) за да продължи инсталацията с домейна ${DEFAULT_DOMAIN}."

	read yn
	yn=${yn:-y}
	if [ "$yn" = "n" ]; then
		color_echo $COLOR_BOLD_GREEN "Избрахте да използвате служебното име ${DEFAULT_DOMAIN}. Инсталацията продължава."
		log "Избран домейн за инсталацията: служебно (${DEFAULT_DOMAIN})."
		set_domain_in_localhost $DEFAULT_DOMAIN
		log "Избран е заложеният по подразбиране домейн ${DEFAULT_DOMAIN}."
	else
		color_echo $COLOR_BOLD_WHITE "Моля, въведете желания домейн:"
		read own_domain_name
		color_echo $COLOR_BOLD_RED "Избрахте домейн: $own_domain_name"
		set_domain_in_webhost $own_domain_name
		set_domain_in_localhost $own_domain_name
		log "Избран е различен от заложения домейн: $own_domain_name и е добавен в конфигурационните файлове."
	fi
	restart_web_server
	log "Виртуалният хост беше създаден."
}

set_domain_in_webhost () {
	sed -i "s/${DEFAULT_DOMAIN}/$1/g" /etc/nginx/sites-enabled/chitanka
	#sed -i "s/${DEFAULT_DOMAIN}/$1/g" /etc/apache2/sites-enabled/000-default.conf
}

set_domain_in_localhost () {
	sed -i -e '1i\'"127.0.0.1	$1" /etc/hosts
}

install_db_server () {
	color_echo $COLOR_BOLD_GREEN "Инсталация на база от данни MariaDB."
	sleep 2
	debconf-set-selections <<< "mariadb-server mysql-server/root_password password $MYSQL_SERVICE_PASSWORD"
	debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $MYSQL_SERVICE_PASSWORD"
	$INSTALL_PKG_DEBIAN mariadb-server mariadb-client php-mysql
	log "Инсталирана е база от данни MariaDB със служебна парола: $MYSQL_SERVICE_PASSWORD"
}

create_chitanka_db () {
	color_echo $COLOR_BOLD_GREEN "Създаване на потребителско име и база от данни за огледалото."
	sleep 2
	$MYSQL_ROOT -e "CREATE USER '$MYSQL_CH_USER'@'localhost' IDENTIFIED BY '$MYSQL_CH_USER_PASSWORD'"
	$MYSQL_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_CH_USER'@'localhost'"
	$MYSQL_ROOT -e "FLUSH PRIVILEGES"
	$MYSQL_ROOT -e "CREATE DATABASE $MYSQL_CH_DATABASE"
	log "Създаден е MySQL потребител със служебна парола: $MYSQL_CH_USER_PASSWORD"
	log "Създадена е MySQL база от данни: $MYSQL_CH_DATABASE"

	curl $MYSQL_DB_DUMP | gunzip | $MYSQL_CHITANKA
	log "Базата от данни за огледалото е внесена."
}

install_chitanka_software () {
	color_echo $COLOR_BOLD_GREEN "Вземане на кода от хранилището в GitHub."
	sleep 2

	rm -rf $CHITANKA_DIR
	git clone --depth 1 $CHITANKA_GIT $CHITANKA_DIR
	log "Програмният код е успешно клониран от хранилището в GitHub."

	cp $INSTALLER_DIR/parameters.yml $CHITANKA_DIR/app/config

	cd $CHITANKA_DIR
	chmod -R a+w var/cache var/log var/spool web/cache
	log "Правата за директориите cache, log и spool са променени."
}

get_chitanka_content () {
	color_echo $COLOR_BOLD_GREEN "Желаете ли да свалите текстовото съдържание? Изберете y (да) или n (не)."
	echo -e "Можете да го направите и по всяко друго време, като стартирате инсталатора с командата ${COLOR_BOLD_GREEN}getcontent${COLOR_RESET}."
	read yn
	yn=${yn:-y}
	if [ "$yn" == "y" ]; then
		clear
		rsync_content
	else
		echo -e "Избрахте да ${COLOR_BOLD_RED}НЕ${COLOR_RESET} сваляте съдържание."
		log "Избрана е опция да не бъде свалено съдържанието."
	fi
}

rsync_content () {
	color_echo $COLOR_BOLD_GREEN "Сваляне на съдържанието."
	sleep 2
	log "rsync процедурата е СТАРТИРАНА"
	rsync -avz --delete ${CHITANKA_RSYNC_CONTENT}/ $CHITANKA_DIR/web/content
	log "rsync процедурата ПРИКЛЮЧИ"
}

echo_success () {
	color_echo $COLOR_BOLD_GREEN "Огледалната версия на Моята библитека беше инсталирана."
	color_echo $COLOR_BOLD_GREEN "Ако огледалото ви е публично достъпно, можете да споделите адреса му във форума на Моята библиотека:"
	color_echo $COLOR_BOLD_GREEN "https://forum.chitanka.info"
}

color_echo () {
	echo -e $1$2$COLOR_RESET
}

log () {
	logfile=${2:-$INSTALL_LOG}
	echo "[`date +"%d.%m.%Y %T"`] $1" >> $logfile
}

is_debian () {
	if [[ ! `grep 'ID=' /etc/os-release | grep debian` ]]; then return 1; fi
}
is_ubuntu () {
	if [[ ! `grep 'ID=' /etc/os-release | grep ubuntu` ]]; then return 1; fi
}
is_debian_based () {
	if [[ ! -e /etc/debian_version ]]; then return 1; fi
}
is_centos () {
	if [[ ! `grep 'ID=' /etc/os-release | grep centos` ]]; then return 1; fi
}

is_apache_installed () {
	if [[ ! `ps -A | grep 'apache\|httpd'` ]]; then return 1; fi
}

case "$1" in
	install)
		install
	;;
	getcontent)
		rsync_content
	;;
	uninstall)
		uninstall
	;;
	changedomain)
		changedomain
	;;
	addcron)
		addcron
	;;
	*)
		show_help
esac
