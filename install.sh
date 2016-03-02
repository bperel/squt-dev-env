#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

mariadb_version=mariadb-10.0.21
clion_version=CLion-144.4199.17

# Adding package sources for NodeJS and Java 8. The NodeJS script executes apt-get update as well
curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections && \
printf 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main\n
deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> webupd8team-java.list && \
# Installing NodeJS
apt-get -y install nodejs && \
\
# Installing node-mariasql and dependencies
apt-get -y install gcc g++ libncurses5-dev bison clang && \
mkdir -p /home/vagrant/Documents/workspace && cd $_ && \
(\
if cd node-mariasql;\
then git pull;\
else git clone https://github.com/bperel/node-mariasql.git;\
fi\
) && cd node-mariasql && \
npm install && cd .. && \
\
# Installing MariaSQL and dependencies, suppressing the warning issued by dch
(\
if cd ${mariadb_version};\
then git pull origin ${mariadb_version};\
else git clone -b ${mariadb_version} --depth 1 https://github.com/mariadb/server ${mariadb_version};\
fi\
) && cd ${mariadb_version} && \
(\
if [ ! -f debian/autobake-deb-force-distribution.sh ];\
then sed 's/^dch/dch --force-distribution/' debian/autobake-deb.sh > debian/autobake-deb-force-distribution.sh;\
fi\
) && \
chmod +x debian/autobake-deb-force-distribution.sh && \
apt-get -y install cmake zlib1g-dev libjemalloc-dev chrpath dh-apparmor dpatch libaio-dev libboost-dev libjudy-dev libpam0g-dev libreadline-gplv2-dev libssl-dev libwrap0-dev gawk hardening-wrapper devscripts && \
debian/autobake-deb-force-distribution.sh && \
\
# Installing the desktop environment
apt-get -y install xfce4 gedit && \
\
# Installing Java 8 and other CLion dependencies
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
apt-get -y install python-software-properties && \
apt-get -y --force-yes install oracle-java8-installer && \
# Cleaning up
apt-get -y autoremove && \
\
# Downloading CLion
wget http://download.jetbrains.com/cpp/${clion_version}.tar.gz && tar -xvzf ${clion_version}.tar.gz && rm ${clion_version}.tar.gz \
