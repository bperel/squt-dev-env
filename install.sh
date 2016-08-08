#!/usr/bin/env bash

set -x
su - vagrant

export DEBIAN_FRONTEND=noninteractive

clion_version=CLion-2016.2
clion_dirname=clion-2016.2
clion_download_url=https://download.jetbrains.com/cpp/${clion_version}.tar.gz
webstorm_version=WebStorm-2016.2.1
webstorm_dirname=WebStorm-162.1447.27
webstorm_download_url=https://download.jetbrains.com/webstorm/${webstorm_version}.tar.gz

node_version=4.4.7
node_dirname=node-v${node_version}
ide_archive_location=/home/vagrant/ide-archive

touch /home/vagrant/.bash_profile && \
( \
 if grep -v -q startx /home/vagrant/.bash_profile; then \
  echo "[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx" >> /home/vagrant/.bash_profile; \
 fi \
) && \
\
# Adding package sources for Java 8
echo 'oracle-java8-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections && \
( \
 if [ ! -f /etc/apt/sources.list.d/webupd8team-java.list ]; then \
  printf 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main\n\ndeb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' > /etc/apt/sources.list.d/webupd8team-java.list; \
 fi \
) && \
# Adding package sources for GCC 4.8
( \
 ( \
  if ! grep --quiet "jessie for gcc 4.8" /etc/apt/sources.list; then \
	 printf '\n\n# jessie for gcc 4.8\ndeb http://ftp.uk.debian.org/debian/ jessie main non-free contrib\n' >> /etc/apt/sources.list; \
  fi \
 ) \
) && \
\
apt-get update && \

# Installing node-mariasql and dependencies - GCC/G++
apt-get -y install -t jessie gcc-4.8 g++-4.8 && \
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50 && \
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 50 && \
\
# Installing node-mariasql and dependencies - NodeJS and related dependencies
apt-get -y install libncurses5-dev bison clang && \
( \
 mkdir -p /home/vagrant/Documents/workspace && cd $_ && \
 ( \
  if [ ! -d ${node_dirname} ]; \
   then ( \
    wget http://nodejs.org/dist/v${node_version}/${node_dirname}.tar.gz && \
    tar -xzf ${node_dirname}.tar.gz && \
    cd ${node_dirname} && \
    ./configure --debug && make && make install && \
    npm install node-gyp \
   ); \
   fi \
 ) && \
 ( \
  if [ -d node-mariasql ]; \
   then (cd node-mariasql && git pull); \
   else git clone https://github.com/bperel/node-mariasql.git; \
  fi \
 ) && \
 chown vagrant:vagrant -R node-mariasql && \
 (cd node-mariasql && npm install) && \
 \
 # Fetching the MariaDB server version from node-mariasql dependencies
 mariadb_version=mariadb-`cut -d'=' -f2 node-mariasql/deps/libmariadbclient/VERSION | tr '\n' '.' | sed 's/\.\+$//'` && \
 \
 # Installing MariaSQL's dependencies
 apt-get -y install cmake zlib1g-dev libjemalloc-dev chrpath dh-apparmor dpatch libaio-dev libboost-dev libjudy-dev libpam0g-dev libreadline-gplv2-dev libssl-dev libwrap0-dev gawk hardening-wrapper devscripts && \
 # Installing MariaSQL, suppressing the warning issued by dch
 ( \
  if [ -d ${mariadb_version} ]; \
   then (cd ${mariadb_version} && git pull origin ${mariadb_version}); \
   else git clone -b ${mariadb_version} --depth 1 https://github.com/mariadb/server ${mariadb_version}; \
  fi \
 ) && \
 chown vagrant:vagrant -R ${mariadb_version} && \
 (cd ${mariadb_version} && \
  ( \
   if [ ! -f debian/autobake-deb-force-distribution.sh ]; \
    then sed 's/^dch/dch --force-distribution/' debian/autobake-deb.sh > debian/autobake-deb-force-distribution.sh; \
   fi \
  ) && \
  chmod +x debian/autobake-deb-force-distribution.sh && \
  debian/autobake-deb-force-distribution.sh \
 ) \
) && \
\
# Installing desktop environment, setting options to show icons on Desktop and run Shell scripts on icon double-click
apt-get -y install gnome-desktop-environment gedit && \
gsettings set org.gnome.desktop.background show-desktop-icons true && \
gsettings set org.gnome.nautilus.preferences executable-text-activation launch && \
\
# Installing Java 8 and other CLion dependencies
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
apt-get -y install python-software-properties && \
apt-get -y --force-yes install oracle-java8-installer && \
# Cleaning up
apt-get -y --force-yes upgrade && \
apt-get -y autoremove && \
\
# Use the cached IDE archives if available
# Downloading (if not cached) and extracting CLion
(if [ ! -d ${clion_dirname} ]; \
 then ( \
  ( \
   if [ ! -f ${ide_archive_location}/${clion_version}.tar.gz ]; \
	  then ( \
	  	echo "Downloading CLion from $clion_download_url" && \
	  	wget --no-check-certificate -O ${ide_archive_location}/${clion_version}.tar.gz ${clion_download_url}; \
		);
	 fi \
	) && \
	tar -xzf ${ide_archive_location}/${clion_version}.tar.gz && \
	chown -R vagrant:vagrant ${clion_dirname} \
 ); \
fi  \
) && \
# Downloading (if not cached) and extracting Webstorm
(if [ ! -d ${webstorm_dirname} ]; \
 then ( \
  ( \
   if [ ! -f ${ide_archive_location}/${webstorm_version}.tar.gz ]; \
	  then ( \
	  	echo "Downloading Webstorm from $webstorm_download_url" && \
	  	wget --no-check-certificate -O ${ide_archive_location}/${webstorm_version}.tar.gz ${webstorm_download_url}; \
		);
	 fi \
	) && \
	tar -xzf ${ide_archive_location}/${webstorm_version}.tar.gz && \
	chown -R vagrant:vagrant ${webstorm_dirname} \
 ); \
fi  \
)