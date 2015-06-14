#! /bin/bash

source './lib/main.sh'



upgrade

install_tools
#install_new_tmux
#install_nginx
compile_nginx
configure_nginx
#install_php
install_php_fpm
install_memcached
install_varnish
install_HHVM
install_mysql
install_locust
install_f2b

configure_fastcgi
#configure_tmux
#configure_bash
configure_varnish
configure_memcached


#install_firewall
start_servers
install_phpmyadmin
start_servers

echo -e "\033[32m Your server is set up and ready to start adding Wordpress sites. Just run 'bash add_site.sh' to add 1 or more sites. \033[0m"
