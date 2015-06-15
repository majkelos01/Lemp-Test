Scrips based on https://github.com/okor/LEMPress
About This LEPM Stack
==============

I based this one on LEMPPress script availabe on GitHub. The other one was perfect, just was missing couple of features I found useful:
* fastcgi caching (probably overkill together with varnish) 
* HHVM  - php processor developed by facebook - this one have the fallback going to PHP-FPM in case something goes wrong
* PHPMyadmin - it's configured to be accessed on the 5011 port
* 

The script was tested on Ubuntu 12.04 and 14.04 

Blog Comments
=============
Because  of caching via Varnish, it will break Wordpress comments. The solution is to use Disqus. It's free, it's good, use it.


To Do
=======
* Cleanup the nginx configs 
* Setup wordpress W3-Total Cache 

How to Use:
========

Create the "deployer" user

        sudo useradd -d /home/deployer -s /bin/bash -G sudo -m deployer
        sudo passwd deployer
        su deployer
        cd ~

Install Git

        yes | sudo apt-get install git-core

Download LEMPress

        git clone https://github.com/majkelos01/Lemp-Test.git
        cd Lemp-Test

Setup the server

        bash build_server.sh

Add a Wordpress site

        bash add_site.sh


The `build_server.sh` script will guide you though the WordPress and LEMPress stack install. Once you've set up a WordPress caching plugin (WP Total Cache is recommended), you'll have a highly optimized WordPress site ready for viral loads.
