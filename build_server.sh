#! /bin/bash

source './lib/main.sh'

echo           '-----------------------------------\n'
read -n1 -rsp $'-----UPGRADING THE SYSTEM ---------\n'
echo           '-----------------------------------\n'
upgrade

install_tools
#install_new_tmux
#install_nginx
echo           '-----------------------------------\n'
read -n1 -rsp $'-----------COMPILING NGINX --------\n'
echo           '-----------------------------------\n'
compile_nginx
configure_nginx
#install_mysql
echo           '-----------------------------------\n'
read -n1 -rsp $'---------INSTALLING MARIADB--------\n'
echo           '-----------------------------------\n'
install_mariadb
#install_php
echo           '-----------------------------------\n'
read -n1 -rsp $'---------INSTALLING PHP-FPM--------\n'
echo           '-----------------------------------\n'
install_php_fpm
install_memcached
#echo           '-----------------------------------\n'
#read -n1 -rsp $'---------INSTALLING VARNISH--------\n'
#echo           '-----------------------------------\n'
#install_varnish
echo           '-----------------------------------\n'
read -n1 -rsp $'----------INSTALLING HHVM----------\n'
echo           '-----------------------------------\n'
install_HHVM
echo           '-----------------------------------\n'
read -n1 -rsp $'---------OTHER TOOLS---------------\n'
echo           '-----------------------------------\n'
install_locust
install_f2b

echo           '-----------------------------------\n'
read -n1 -rsp $'---------CONFIGURE FAST-CGI--------\n'
echo           '-----------------------------------\n'
configure_fastcgi
#configure_tmux
#configure_bash
#echo           '-----------------------------------\n'
#read -n1 -rsp $'---------CONFIGURE VARNISH---------\n'
#echo           '-----------------------------------\n'
#configure_varnish
configure_memcached


#install_firewall
start_servers
echo           '-----------------------------------\n'
read -n1 -rsp $'--------INSTALLING PHPMYADMIN------\n'
echo           '-----------------------------------\n'
install_phpmyadmin
start_servers
#install_firewall


echo           '-----------------------------------\n'
read -n1 -rsp $'--------INSTALLING PYDIO     ------\n'
echo   
install_pydio

echo -e "\033[32m Your server is set up and ready to start adding Wordpress sites. Just run 'bash add_site.sh' to add 1 or more sites. \033[0m"
