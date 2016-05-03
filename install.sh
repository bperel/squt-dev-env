#!/usr/bin/env bash

set -x
su - vagrant

export DEBIAN_FRONTEND=noninteractive

mariadb_version=mariadb-10.0.21
clion_version=CLion-2016.1-1

touch /home/vagrant/.bash_profile && \
(if grep -v -q startx /home/vagrant/.bash_profile; then echo "[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx" >> /home/vagrant/.bash_profile; fi) && \
\
# Adding package sources for NodeJS and Java 8. The NodeJS script executes apt-get update as well
curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections && \
(if [ ! -f /etc/apt/sources.list.d/webupd8team-java.list ]; then \
printf 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main\n\ndeb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list.d/webupd8team-java.list; fi) && \
# Installing NodeJS
apt-get -y install nodejs && \
\
# Installing node-mariasql and dependencies
apt-get -y install gcc g++ libncurses5-dev bison clang && \
(mkdir -p /home/vagrant/Documents/workspace && cd $_ && \
 ( \
  if [ -d node-mariasql ]; \
   then (cd node-mariasql && git pull); \
   else git clone https://github.com/bperel/node-mariasql.git; \
  fi \
 ) && \
 chown vagrant:vagrant -R node-mariasql
 (cd node-mariasql && npm install) && \
 \
 # Installing MariaSQL's dependencies
 apt-get -y install cmake zlib1g-dev libjemalloc-dev chrpath dh-apparmor dpatch libaio-dev libboost-dev libjudy-dev libpam0g-dev libreadline-gplv2-dev libssl-dev libwrap0-dev gawk hardening-wrapper devscripts && \
 # Installing MariaSQL and dependencies, suppressing the warning issued by dch
 ( \
  if [ -d ${mariadb_version} ]; \
   then (cd ${mariadb_version} && git pull origin ${mariadb_version}); \
   else git clone -b ${mariadb_version} --depth 1 https://github.com/mariadb/server ${mariadb_version}; \
  fi \
 ) && \
 chown vagrant:vagrant -R ${mariadb_version}
 (cd ${mariadb_version} && \
  ( \
   if [ ! -f debian/autobake-deb-force-distribution.sh ]; \
    then sed 's/^dch/dch --force-distribution/' debian/autobake-deb.sh > debian/autobake-deb-force-distribution.sh; \
   fi \
  ) && \
  chmod +x debian/autobake-deb-force-distribution.sh && \
  debian/autobake-deb-force-distribution.sh
 )
) && \
\
# Installing desktop environment
apt-get -y install gnome-desktop-environment gedit && \
\
# Installing Java 8 and other CLion dependencies
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
apt-get -y install python-software-properties && \
apt-get -y --force-yes install oracle-java8-installer && \
# Cleaning up
apt-get -y upgrade && \
apt-get -y autoremove && \
\
# Downloading and extracting CLion
(if [ ! -d ${clion_version} ]; \
 then ( \
	wget http://download.jetbrains.com/cpp/${clion_version}.tar.gz && \
	tar -xvzf ${clion_version}.tar.gz && \
	chown vagrant:vagrant ${clion_version} && \
	rm ${clion_version}.tar.gz; \
 ); \
fi  \
)