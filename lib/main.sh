# Don't change these
TIME_NOW=`date +%s`
LEMPress="$HOME/Lemp-Test"
DEFAULT_URL="new-wordpress-site.com"
URL=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
DB_SALT=""
DB_PREFIX=""
DEFAULT_USER="deployer"
PUBLIC_IP=`curl -s http://checkip.dyndns.org | awk '{print $6}' | awk -F '<' '{print $1}'`

if [ "$USER" == "root" ]
  then
    echo -e "\033[32m Don't run this script at root. \033[0m"
    exit
  fi


# Change these if you have alternate configuration files
TMUX_CONFIG="$LEMPress/configs/tmux.conf"
FASTCGI_INIT="$LEMPress/configs/fastcgi-init.sh"

function get_website_url() {
  echo -ne "\033[32m Enter website URL [DEFAULT:new-wordpress-site.com]: \033[0m"
  read USER_URL
  if [ -z $USER_URL ]
  then
    URL=$DEFAULT_URL
  else
    URL=$USER_URL
  fi
  echo -e "\033[32m URL set to: $URL \033[0m"
}


# Upgrade

function upgrade() {
  sudo apt-get -y update
  sudo apt-get -y --force-yes upgrade
}

# Install

function install_tools() {
  sudo apt-get -y install openssh-server tmux rsync iptables wget curl build-essential python-software-properties unzip htop pwgen git-core nano siege
}

function install_new_tmux() {
  sudo apt-get -y install build-essential debhelper diffstat dpkg-dev \
  fakeroot g++ g++-4.4 html2text intltool-debian libmail-sendmail-perl \
  libncurses5-dev libstdc++6-4.4-dev libsys-hostname-long-perl po-debconf \
  quilt xz-utils libevent-1.4-2 libevent-core-1.4-2 libevent-extra-1.4-2 libevent-dev

  DOWNLOAD_URL="http://sourceforge.net/projects/tmux/files/tmux/tmux-1.6/tmux-1.6.tar.gz"
  wget -P "$HOME/tmp" $DOWNLOAD_URL
  cd "$HOME/tmp"
  tar xvvf tmux-1.6.tar.gz
  cd tmux-1.6/
  sudo ./configure --prefix=/usr
  sudo make
  sudo make install
}

function install_nginx() {
  sudo apt-get -y install nginx
}

function compile_nginx() {

	sudo apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev
	sudo apt-get -y install linux-kernel-headers
	sudo apt-get -y install build-essential

	sudo mkdir /opt/pagespeed
	cd /opt/pagespeed

	NPS_VERSION=1.9.32.2
	sudo wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
	sudo unzip release-${NPS_VERSION}-beta.zip

	cd ngx_pagespeed-release-${NPS_VERSION}-beta/
	sudo wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
	sudo tar -xzvf ${NPS_VERSION}.tar.gz  # extracts to psol/
	# Gives us directory /opt/pagespeed/ngx_pagespeed-release-1.9.32.2-beta

	sudo mkdir /opt/cachepurge
	cd /opt/cachepurge
	sudo wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz
	sudo tar -xzf ngx_cache_purge-2.3.tar.gz
	
	
	sudo mkdir /opt/rebuildnginx
	cd /opt/rebuildnginx

	sudo wget http://nginx.org/download/nginx-1.9.1.tar.gz
	sudo tar -xvzf nginx-1.9.1.tar.gz

	sudo rm -f nginx-1.9.1.tar.gz
	cd nginx-1.9.1
	# Attention - Here the version is hard coded
	sudo ./configure --user=$DEFAULT_USER --group=$DEFAULT_USER --prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock  \
	--with-http_geoip_module \
	--with-google_perftools_module \
	--add-module=/opt/pagespeed/ngx_pagespeed-release-1.9.32.2-beta \
	--add-module=/opt/cachepurge/ngx_cache_purge-2.3

	sudo make
	sudo make install
	
	#Setup Default Sites
	sudo mkdir -p /etc/nginx/sites-available
	sudo mkdir -p /etc/nginx/sites-enabled
	sudo mkdir -p /etc/nginx/conf.d


	sudo rsync "$LEMPress/configs/LEMPress-virtualhost.txt" "/etc/nginx/sites-available"	
}

function install_firewall() {

	sudo apt-get install ufw
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	
	sudo ufw allow 22/tcp #ssh
	ufw allow 80/tcp
	sudo ufw allow 21/tcp
	sudo ufw allow 8089/tcp
	
	sudo ufw enable
	sudo ufw status
}

function install_locust() {

	sudo apt-get install python-dev python-pip libevent
	sudo pip install locustio

	sudo pip install pyzmq gevent-zeromq

}

function configure_memcached() {
  sudo sed -i "s/-m 64/-m 64/g" "/etc/memcached.conf"

}



function install_f2b() {
	sudo apt-get update
	sudo apt-get install fail2ban
	sudo rsync /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	
	sudo sed -i "s/bantime  = 600/bantime = 3600/d" "/etc/fail2ban/jail.local"
	sudo sed -i "s/findtime = 600/findtime = 3600/d" "/etc/fail2ban/jail.local"
	sudo sed -i "s/maxretry = 3/maxretry = 2/d" "/etc/fail2ban/jail.local"
	
}


function install_mariadb() {
	sudo apt-get install -y software-properties-common 
	sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
	sudo add-apt-repository 'http://nyc2.mirrors.digitalocean.com/mariadb/repo/5.5/ubuntu/'
	sudo apt-get update
	sudo apt-get install -y mariadb-server mariadb-client
	sudo /usr/bin/mysql_secure_installation
}

function install_php() {
  sudo apt-get -y install php5-common php5-cli php5-cgi php5-mcrypt \
  php5-mysql libssh2-php php5-xcache php5-curl php5-memcache php5-tidy
  # php5-dev
  # sudo pecl install apc
}

function install_php_fpm() {
	sudo apt-get install php5-fpm php5-cli php5-mysql -y
	#ensure Cli and FPM have same php.ini configuration 
	cd /etc/php5/cli
	sudo mv php.ini php.ini.backup
	sudo ln -s ../fpm/php.ini
	
	
	sudo sed -i "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|" "/etc/php5/fpm/php.ini"
	sudo sed -i "s|expose_php = On|expose_php = Off|" "/etc/php5/fpm/php.ini"
	
	sudo sed -i "s|post_max_size = 8M|post_max_size = 80M|" "/etc/php5/fpm/php.ini"
	sudo sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 50M|" "/etc/php5/fpm/php.ini"

	sudo sed -i "s|;opcache.enable=0|opcache.enable=1|" "/etc/php5/fpm/php.ini"
	
	sudo sed -i "s|;emergency_restart_threshold = 0|emergency_restart_threshold = 10|" "/etc/php5/fpm/php-fpm.conf"
	sudo sed -i "s|;emergency_restart_interval = 0|emergency_restart_interval = 1m|" "/etc/php5/fpm/php-fpm.conf"
	sudo sed -i "s|;process_control_timeout = 0|process_control_timeout = 10|" "/etc/php5/fpm/php-fpm.conf"
	#backup copy of the www config
	
	sudo cp /etc/php5/fpm/pool.d/www.conf{,.orig}
	sudo tee /etc/php5/fpm/pool.d/www.conf <<EOF
[php-serve]
	listen = 127.0.0.1:9001
	;listen = /var/run/php-fpm.socket
	user = deployer
	group = deployer
	request_slowlog_timeout = 5s
	slowlog = /var/log/php5-fpm.log
	listen.allowed_clients = 127.0.0.1
	pm = dynamic
	pm.max_children = 10
	pm.start_servers = 3
	pm.min_spare_servers = 2
	pm.max_spare_servers = 4
	pm.max_requests = 400
	listen.backlog = -1
	pm.status_path = /status
	request_terminate_timeout = 120s
	rlimit_files = 131072
	rlimit_core = unlimited
	catch_workers_output = yes
	php_value[session.save_handler] = files
	;php_value[session.save_path] = /var/lib/php/session
	php_admin_value[error_log] = /var/log/php5-fpm-error.log
	php_admin_flag[log_errors] = on
EOF
	

	sudo service php5-fpm restart

}

function install_HHVM() {

	if [ -f /etc/lsb-release ]; then
	    . /etc/lsb-release
	fi
	
	sudo apt-get -y install software-properties-common
	sudo add-apt-repository ppa:mapnik/boost
	sudo wget --tries=3 http://dl.hhvm.com/conf/hhvm.gpg.key 
	sudo apt-key add *.key
	sudo add-apt-repository 'http://dl.hhvm.com/ubuntu'
	sudo sed -i -e 's|deb-src http://dl.hhvm.com/ubuntu|#deb-src http://dl.hhvm.com/ubuntu|g' /etc/apt/sources.list
	sudo apt-get -y update
	sudo apt-get -y install hhvm
	
	sudo /usr/share/hhvm/install_fastcgi.sh
	sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60
	sudo update-rc.d hhvm defaults
	
	#sudo sed -i '/hhvm.server.port = 9000/a hhvm.server.file_socket=/var/run/hhvm/hhvm.sock' /etc/hhvm/server.ini
	sudo sed -i "s|hhvm.server.port = 9000|hhvm.server.port = 9003|" "/etc/hhvm/server.ini"
	
	#sudo sed -i 's|#RUN_AS_USER="www-data"|RUN_AS_USER="deployer"|' "/etc/default/hhvm"
	#sudo sed -i 's|#RUN_AS_GROUP="www-data"|RUN_AS_GROUP="deployer"|' "/etc/default/hhvm"

	sudo tee -a "/etc/hhvm/php.ini" <<EOF
	;max_execution_time = 300
	;max_input_time = 60
	memory_limit = 128M
	post_max_size = 120M
	upload_max_filesize = 120M
	EOF

	sudo tee -a "/etc/default/hhvm" <<EOF
	RUN_AS_USER="deployer"
	RUN_AS_GROUP="deployer"
EOF
			

	sudo service hhvm stop
	sudo service hhvm start
}

function install_varnish() {
  sudo apt-get -y install varnish
}

function install_phpmyadmin(){
	sudo apt-get -y install phpmyadmin
	sudo ln -s /usr/share/phpmyadmin /home/deployer/sites/phpmyadmin
	sudo php5enmod mcrypt
	sudo rsync "$LEMPress/configs/phpmyadmin" "/etc/nginx/sites-available/phpmyadmin"
	sudo ln -s "/etc/nginx/sites-available/phpmyadmin" "/etc/nginx/sites-available/phpmyadmin"
	
	sudo service nginx reload && sudo service nginx restart && sudo service varnish restart \
	 && sudo service php5-fpm restart && sudo service hhvm restart
}

function install_memcached() {
  sudo apt-get -y install memcached
  # php5-memcache
}


function install_wordpress() {
  mkdir "$HOME/tmp"
  mkdir "$HOME/sites"
  mkdir "$HOME/sites/$URL/"
  wget -P "$HOME/tmp" http://wordpress.org/latest.zip
  unzip -d "$HOME/tmp/wordpress-$TIME_NOW" "$HOME/tmp/latest.zip"
  rsync -av --progress "$HOME/tmp/wordpress-$TIME_NOW/wordpress/" "$HOME/sites/$URL/"
  mkdir "$HOME/sites/$URL/logs"
}




# Configure

function configure_virtualhost() {
  sudo rsync "$LEMPress/configs/LEMPress-virtualhost.txt" "/etc/nginx/sites-available/$URL"
  sudo sed -i "s/URL/$URL/g" "/etc/nginx/sites-available/$URL"
  sudo ln -s "/etc/nginx/sites-available/$URL" "/etc/nginx/sites-enabled/$URL"
  sudo rm "/etc/nginx/sites-enabled/default"
  sudo mkdir -p  "/etc/nginx/cache/$URL"
}

function configure_nginx() {
	sudo rsync "$LEMPress/configs/nginx.conf" "/etc/nginx/nginx.conf"
	sudo sed -i "s/www-data/$DEFAULT_USER/g" "/etc/nginx/nginx.conf"
  
 	#Copy all configs 
	sudo rsync "$LEMPress/configs/nginx" "/etc/default/nginx"
	sudo rsync "$LEMPress/configs/nginx-locations.conf" "/etc/nginx/nginx-locations.conf"
	sudo rsync "$LEMPress/configs/nginx-pagespeed.conf" "/etc/nginx/nginx-pagespeed.conf"
	sudo rsync "$LEMPress/configs/nginx-seciurity.conf" "/etc/nginx/nginx-seciurity.conf"
	#sudo sed -i "s/URL/$URL/g" "/etc/nginx/nginx-pagespeed.conf"
	
	#setup Init Script
	sudo wget https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx -O /etc/init.d/nginx
	sudo chmod +x /etc/init.d/nginx
	sudo update-rc.d nginx defaults
	
	sudo service nginx restart
}

function configure_fastcgi() {
  sudo rsync "$FASTCGI_INIT" "/etc/init.d/php-fastcgi"
  sudo chmod +x "/etc/init.d/php-fastcgi"
  sudo update-rc.d php-fastcgi defaults
}

function configure_tmux() {
  rsync "$LEMPress/configs/tmux.conf" "$HOME/.tmux.conf"
}

function configure_bash() {
  rsync "$HOME/.bashrc" "$HOME/.bashrc~backup"
  rsync "$LEMPress/configs/bashrc" "$HOME/.bashrc"

  sudo rsync /root/.bashrc /root/.bashrc~backup
  sudo rsync "$LEMPress/configs/bashrc" /root/.bashrc
}

function configure_varnish() {
  sudo rsync "$LEMPress/configs/varnish" "/etc/default/varnish"
  sudo rsync "$LEMPress/configs/default.vcl" "/etc/varnish/default.vcl"
}


function create_passwords() {
  DB_NAME="`pwgen -Bs 10 1`"
  DB_USER="`pwgen -Bs 10 1`"
  DB_PASSWORD="`pwgen -Bs 40 1`"
  DB_SALT="`pwgen -Bs 80 1`"
  DB_PREFIX="`pwgen -0 5 1`_"
  if [ -f /$LEMPress/dbinfo.txt ]; then
   echo "File exist"
   else 
    sudo touch /$LEMPress/dbinfo.txt
   fi
	sudo tee -a /$LEMPress/dbinfo.txt <<EOF
------------------------
Database for $URL
DB NAME = $DB_NAME
DB USER = $DB_USER
PASSWORD = $DB_PASSWORD
WP_PREFIX = $DB_PREFIX
------------------------

EOF
}

function create_db() {
  MYSQL=`which mysql`
  Q1="CREATE DATABASE IF NOT EXISTS $DB_NAME;"
  Q2="GRANT ALL ON *.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
  Q3="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}${Q3}"

  echo -e "\033[32m Enter the MySQL password you entered earlier.  \033[0m"
  $MYSQL -uroot -p -e "$SQL"
  
  
}

function configure_wordpress() {
  rsync "$HOME/sites/$URL/wp-config-sample.php" "$HOME/sites/$URL/wp-config.php"
  sed -i "s/database_name_here/$DB_NAME/g" "$HOME/sites/$URL/wp-config.php"
  sed -i "s/username_here/$DB_USER/g" "$HOME/sites/$URL/wp-config.php"
  sed -i "s/password_here/$DB_PASSWORD/g" "$HOME/sites/$URL/wp-config.php"
  sed -i "s/put your unique phrase here/$DB_SALT/g" "$HOME/sites/$URL/wp-config.php"
  sed -i "s/wp_/$DB_PREFIX/g" "$HOME/sites/$URL/wp-config.php"

  touch "$HOME/sites/$URL/nginx.conf"

  # Sucks, I know. I'll see what I can do about this.
  chmod 777 "$HOME/sites/$URL/nginx.conf"
}


function ip_dump() {
  echo -e "" && \
  echo -e "\033[32mOk, you're all done. Point your browser at your server (URL: $URL, IP: $PUBLIC_IP) , and you should see a new wordpress site." && \
  echo -e "" && \
  echo -e "\033[32mHere's some local network information about this machine." && \
  ifconfig | grep "inet addr" && \
  echo -e "\033[0m"
}


function start_servers() {
  #sudo service php-fastcgi start
  sudo php5-fpm start
  sudo service memcached start
  #sudo service varnish restart
  sudo service nginx reload
  sudo service nginx stop
  sudo service nginx start
  sudo service hhvm start
}


