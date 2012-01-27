#!/usr/bin/env bash
# Ubuntu 11.10 bootstrap
LOGF=$HOME/install.log
read -d '' GREETING <<EOF
This script will do something good to your server.
Sit back and enjoy!
EOF

echo "$GREETING"

date > ~/bootstrap_build_time
echo "$(date) - Begin server bootstraping" > $LOGF

echo "Setup sudo to allow no-password sudo for \"admin\""
echo "This is the only time I need your sudo password"
sudo cp /etc/sudoers /etc/sudoers.orig
sudo sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sudo sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

echo "Apt-install various things necessary for Ruby, guest additions,"
echo "etc., and remove optional things."
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install linux-headers-$(uname -r) build-essential \
  wget curl git-core openssl automake libtool bison autoconf \
  zlib1g zlib1g-dev libssl-dev libreadline6 libreadline6-dev libc6-dev libpcre3-dev \
  libxslt-dev libxml2-dev libyaml-dev libssl-dev \
  libsqlite3-0 libsqlite3-dev sqlite3 ncurses-dev \
  libcurl4-openssl-dev
  >> $LOGF
sudo apt-get clean
##
## Install RVM
##
echo "Installing RVM..."
bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer ) >> $LOGF
. $HOME/.profile
rvmoutput="rvm is a function"
if [[ `type rvm | head -n1` != "$rvmoutput" ]]; then
echo "Something went wrong. RVM must be a function!"
  exit 1
fi
echo "  RVM activated"
echo "  Create sane .gemrc..."
touch $HOME/.gemrc
cat <<EOF > ~/.gemrc
:verbose: true
:sources:
- http://gems.rubyforge.org/
- http://gems.github.com/
:update_sources: true
:backtrace: false
:bulk_threshold: 1000
:benchmark: false
gem: --no-ri --no-rdoc

EOF
echo "done"
##
## Install ruby 1.9.2 and make it the default
##
echo "Installing Ruby 1.9.2 (this may take awhile)..."
rvm install 1.9.2
rvm --default ruby-1.9.2
echo "done"
##
## Install rails gem
##
echo "Installing rails gem..."
gem install rails
echo "done"
##
## Install passenger and grab gem
##
echo "Installing Phusion Passenger gem..."
rvm 1.9.2 --passenger
gem install passenger
echo "done"
##
## Install nginx with Phusion Passenger support
##
echo "Installing Nginx + Phusion Passenger..."
echo "  Keep in mind: this script assumes that you WILL install nginx"
echo "  to default location (/opt/nginx). Do not change it please."
# Let Passenger installer to download nginx for us...
rvmsudo passenger-install-nginx-module
sudo wget -O /etc/init.d/nginx https://raw.github.com/Dashrocket/setuppers/master/nginx-init-script
sudo chmod +x /etc/init.d/nginx
sudo /usr/sbin/update-rc.d -f nginx defaults
echo "done"
##
## Create Rack testapp & start Nginx
##
echo "Create testapp and setup sample Rack application..."
cd /tmp
rails new testapp
cd -
# mkdir -p /tmp/testapp/public
# mkdir -p /tmp/testapp/tmp
# touch /tmp/testapp/config.ru
# cat <<EOF > /tmp/testapp/config.ru
# app = proc do |env|
#     [200, { "Content-Type" => "text/html" }, ["hello <b>world</b>"]]
# end
# run app
#
# EOF

echo "  get sample nginx config..."
NGINX_CONF=/opt/nginx/conf/nginx.conf
sudo wget -O $NGINX_CONF https://raw.github.com/Dashrocket/setuppers/master/nginx-sample-config
# passenger_gem=`cd $GEM_HOME/gems && ls -al | grep 'passenger' | awk '{ print $9}'`
passenger_gem=`passenger-config --root`
passenger_ruby=`which ruby`
sudo sed -i -e 's|<passenger_root>|passenger_root '$passenger_gem';|g' $NGINX_CONF
sudo sed -i -e 's|<passenger_ruby>|passenger_ruby '$passenger_ruby';|g' $NGINX_CONF

sudo service nginx stop && sleep 5
sudo service nginx start
echo "  now you should be able to see mega-site at http://localhost"
echo "done"

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
sudo echo "pre-up sleep 2" >> /etc/network/interfaces
exit