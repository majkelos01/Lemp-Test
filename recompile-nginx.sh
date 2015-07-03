#! /bin/bash

source './lib/main.sh'

echo           '-----------------------------------\n'
echo           '-----------COMPILING NGINX --------\n'
echo           '-----------------------------------\n'
compile_nginx
configure_nginx

start_servers

