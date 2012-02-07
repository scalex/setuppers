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
:update_sources: true
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
#echo "Installing rails gem..."
#gem install rails
#echo "done"
##
## Install Unicorn gem
##
echo "Installing Unicorn gem..."
#rvm use default # just to make sure
rvm use 1.9.2@global
gem install unicorn
echo "done"
##
## Prepare stuff
##
sudo mkdir -p /var/www
cd /var/www
sudo rails new test-unicorn-app -T
sudo wget -O /etc/nginx/sites-available/test-unicorn-app https://raw.github.com/Dashrocket/setuppers/master/nginx-sample-site
sudo ln -s /etc/nginx/sites-available/test-unicorn-app /etc/nginx/sites-enabled/test-unicorn-app
##
## Hope i'm done...
##
echo "Everything is done. Now please restart you server."
