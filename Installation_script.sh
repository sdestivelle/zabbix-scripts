#!/bin/bash

#=====================================================================
#
# ZABBIX : Script d'installation de Zabbix version 2.0.7
# Copyright (c) 2010 Steve DESTIVELLE pour SOMONE
#
# Modifications : 
# ---le--- -----par----- ---------------objet---------------
# 15/10/12 S. DESTIVELLE   Création du script
#
#=====================================================================


#=====================================================================
#
# Si nécessaire, éditer les paramètres pour les adapter à votre configuration
#
#=====================================================================

DBUSER='root'
DBPASS='somepassword'
DBHOST='localhost'

DBZABBIX='zabbix'
DBZABBIXPWD='zabbix'

ZBX_VER='2.4.4'
SRC='/usr/src'

# Test machine x64 ou 32
MACHINE_TYPE=`uname -m`

#=====================================================================
#
# NE PAS EDITER EN DESSOUS DE CETTE LIGNE
#
#=====================================================================

function checkReturn {
  if [ $1 -ne 0 ]; then
     echo "fail: $2"
     echo "$3"
     exit
  else
     echo "pass: $2"
  fi
  sleep 3
}


# DEBUT SCRIPT
cat << "eof"

=== RUN AT YOUR OWN RISK ===

DO NOT RUN ON EXISTING INSTALLATIONS, YOU *WILL* LOSE DATA

This script:
 * Installs Zabbix 2.4.4 on CentOS
 * Drops an existing zabbix database
 * Does not install zabbix packages, it uses source from zabbix.com

Press Ctrl-C now if you want to exit

Wait 20 seconds...
eof
sleep 20
# FIN SCRIPT



##############################
# INSTALLATION DES PAQUETS 1 #
##############################

#
# Basic dependencies for the system
#
yum -y update
RETVAL=$?
checkReturn $RETVAL "Basic package install"

##############################
# INSTALLATION DES PAQUETS 2 #
##############################

#
# dependenices for curl: e2fsprogs-devel zlib-devel libgssapi-devel krb5-devel openssl-devel
#
yum -y install wget vim gcc libcurl mysql-server httpd php php-mysql openssl-devel ca-certificates glib2 libidn libidn-devel krb5-devel php-ldap libssh2 libssh2-devel pkgconfig OpenIPMI-perl perl lm_sensors-devel lm_sensors-libs net-snmp-devel net-snmp libsysfs libsysfs-devel net-snmp-perl fontconfig fontconfig-devel php-gd dejavu-fonts-common OpenIPMI OpenIPMI-devel mlocate mysql-libs mysql-devel libcurl libcurl-devel make php-mbstring php-bcmath net-snmp-utils patch php-xml php-pear java java-devel libxml2 libxml2-devel crontabs
RETVAL=$?
checkReturn $RETVAL "Package install"

#
# Système 64 ou 32
#
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  #
  # Installation de FPING 64
  #
  cd $SRC
  wget http://pkgs.repoforge.org/fping/fping-3.9-1.el6.rf.x86_64.rpm
  wait
  rpm -ivh fping-3.9-1.el6.rf.x86_64.rpm
  wait
  RETVAL=$?
  checkReturn $RETVAL "Fping install"
else
  cd $SRC
  wget http://pkgs.repoforge.org/fping/fping-3.9-1.el6.rf.i686.rpm
  wait
  rpm -ivh fping-3.9-1.el6.rf.i686.rpm
  wait
  RETVAL=$?
  checkReturn $RETVAL "Fping install"
fi

chmod 4755 /usr/sbin/fping

##############################
# Partie supervision BDD     #
##############################

# MYSQL
yum -y install mysql-connector-odbc

# POSTGRESQL
yum -y install postgresql-odbc.x86_64

# ORACLE
cd $SRC

# PATH ORACLE /usr/lib/oracle/12.1/client64
#
# export ORACLE_HOME=/usr/lib/oracle/12.1/client64
# export ORACLE_HOME_LISTNER=/usr/lib/oracle/12.1/client64/bin
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH :/usr/lib/oracle/12.1/client64/lib
# export SQLPATH=/usr/lib/oracle/12.1/client64/lib
# export TNS_ADMIN=/usr/lib/oracle/12.1/client64/bin

# UNIXODBC
yum -y install unixODBC unixODBC-devel

# JAVA GATEWAY
#/*
#wget http://download.oracle.com/otn-pub/java/jdk/7u55-b13/jdk-8u20-linux-x64.gz
#tar zxvf jdk-7u55-linux-x64.tar.gz -c /usr/local
#ln -s /usr/local/jdk1.7.0_55 /usr/local/jdk
#echo 'JAVA_HOME=/usr/local/jdk' >> /etc/bashrc
#echo 'PATH=${JAVA_HOME}/bin/:$PATH' >> /etc/bashrc
#echo 'export JAVA_HOME PATH' >> /etc/bashrc
#source /etc/bashrc
#*/


##############################
# INSTALLATION DE ZABBIX     #
##############################

#
# Téléchargement de Zabbix
#
cd /usr/src
rm -rf zabbix-$ZBX_VER
rm zabbix-$ZBX_VER.tar.gz
#wget http://superb-east.dl.sourceforge.net/sourceforge/zabbix/zabbix-$ZBX_VER.tar.gz
#wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Development/$ZBX_VER/zabbix-$ZBX_VER.tar.gz
# http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/2.0.0/zabbix-2.0.0.tar.gz/download
wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$ZBX_VER/zabbix-$ZBX_VER.tar.gz
RETVAL=$?
checkReturn $RETVAL "downloading source" "check ZBX_VER variable or mirror might be down"

#
# Décompression et installation
#
tar xzf zabbix-$ZBX_VER.tar.gz
cd zabbix-$ZBX_VER
./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --enable-java --with-openipmi --with-ssh2 --with-unixodbc --with-libxml2
RETVAL=$?
checkReturn $RETVAL "Configure"
# --with-jabber
# ipmi
# ldap
# support vmware libcurl + libxml2

#make
#RETVAL=$?
#checkReturn $RETVAL "Compile"

make install
RETVAL=$?
checkReturn $RETVAL "make install"

##############################
# SELINUX, IPTABLES, MYSQL   #
##############################

#
# Disable selinux
#
cd /etc/selinux

sed "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config > /usr/src/mytmpselinux; mv /usr/src/mytmpselinux /etc/selinux/config 
setenforce 0

#
# Disable iptables
#
/etc/init.d/iptables stop
chkconfig iptables off

#
# Démarrage de MySQL
#
chkconfig mysqld on
/etc/init.d/mysqld start

#
# Configuration de MySQL
#
/usr/bin/mysql_secure_installation

#
# Test MySQL
#
mysql -h${DBHOST} -u${DBUSER} --password=${DBPASS} > /dev/null << eof
status
eof
RETVAL=$?
checkReturn $RETVAL "basic mysql access" "Install mysql server packages or fix mysql permissions"

echo "DROP DATABASE IF EXISTS zabbix;" | mysql -h${DBHOST} -u${DBUSER} --password=${DBPASS}

(
echo "CREATE DATABASE zabbix character set utf8;"
echo "USE zabbix;"
echo "grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by 'D54q6jlerF';"
cat $SRC/zabbix-$ZBX_VER/database/mysql/schema.sql
cat $SRC/zabbix-$ZBX_VER/database/mysql/images.sql
cat $SRC/zabbix-$ZBX_VER/database/mysql/data.sql
) | mysql -h${DBHOST} -u${DBUSER} --password=${DBPASS}

##############################
# CONFIGURATION APACHE       #
##############################

#
# Configuration de httpd, config de la variable ServerName
#
echo "ServerName zabbix.demo.somone.fr" >> /etc/httpd/conf/httpd.conf
/etc/init.d/httpd start
chkconfig httpd on

##############################
# CONFIGURATION ZABBIX       #
##############################

#
#### BEGIN ZABBIX SERVER & AGENT PROCESS INSTALL & START
#
mkdir -p /usr/local/etc/zabbix_alert.d
mkdir -p /var/log/zabbix-server
mkdir -p /var/log/zabbix-agent
mkdir -p /var/run/zabbix-server
mkdir -p /var/run/zabbix-agent
useradd -b /var/run/zabbix-server -m -s /bin/bash zabbix
chown zabbix:zabbix /var/run/zabbix*
chown zabbix:zabbix /var/log/zabbix*
chown zabbix:zabbix /usr/local/sbin/zabbix*



##############################
# ZABBIX SERVER CONF         #
##############################

#
# Edition de /usr/local/etc/zabbix_server.conf
#

cd /usr/local/etc/

# CONF avec SED
sed "s/LogFile=\/tmp\/zabbix_server.log/LogFile=\/var\/log\/zabbix-server\/zabbix_server.log/g" /usr/local/etc/zabbix_server.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_server.conf
sed "s/\# PidFile=\/tmp\/zabbix_server.pid/PidFile=\/var\/run\/zabbix-server\/zabbix_server.pid/g" /usr/local/etc/zabbix_server.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_server.conf
sed "s/DBUser=root/DBUser=${DBZABBIX}/g" /usr/local/etc/zabbix_server.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_server.conf
sed "s/\# DBPassword=/DBPassword=${DBZABBIXPWD}/g" /usr/local/etc/zabbix_server.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_server.conf
sed "s/\# AlertScriptsPath=\$\{datadir\}\/zabbix\/alertscripts/AlertScriptsPath=\/usr\/local\/etc\/zabbix\/alertscripts/g" /usr/local/etc/zabbix_server.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_server.conf
#
# FIN ZABBIX_SERVER.CONF

#
# ZABBIX_SERVER
cp $SRC/zabbix-$ZBX_VER/misc/init.d/fedora/core5/zabbix_server /etc/init.d/zabbix_server

#
# FIN ZABBIX_SERVER

chmod 400 /usr/local/etc/zabbix_server.conf 
chown zabbix /usr/local/etc/zabbix_server.conf

##############################
# ZABBIX AGENT CONF          #
##############################

#
# Edition de /usr/local/etc/zabbix_agentd.conf
#
cp $SRC/zabbix-$ZBX_VER/conf/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf

cd /usr/local/etc/

# CONF avec SED
sed "s/LogFile=\/tmp\/zabbix_agentd.log/LogFile=\/var\/log\/zabbix-server\/zabbix_agentd.log/g" /usr/local/etc/zabbix_agentd.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_agentd.conf
sed "s/\# PidFile=\/tmp\/zabbix_agentd.pid/PidFile=\/var\/run\/zabbix-agent\/zabbix_agentd.pid/g" /usr/local/etc/zabbix_agentd.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_agentd.conf
sed "s/\# EnableRemoteCommands=0/EnableRemoteCommands=1/g" /usr/local/etc/zabbix_agentd.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_agentd.conf
sed "s/\# Timeout=3/Timeout=10/g" /usr/local/etc/zabbix_agentd.conf > /usr/src/tmp; mv /usr/src/tmp /usr/local/etc/zabbix_agentd.conf

#
# FIN ZABBIX_AGENTD.CONF

#
# ZABBIX_AGENTD
cp $SRC/zabbix-$ZBX_VER/misc/init.d/fedora/core5/zabbix_agentd /etc/init.d/zabbix_agentd

cd /etc/init.d

sed "s/ZABBIX_BIN=\"\/usr\/local\/sbin\/zabbix_agentd\"/progdir=\"\/usr\/local\/sbin\/zabbix_agentd\"/g" /etc/init.d/zabbix_server > /usr/src/tmp; mv /usr/src/tmp /etc/init.d/zabbix_server

#
# FIN ZABBIX_AGENTD

chmod 755 /etc/init.d/zabbix_*

##############################
# CHKCONFIG                  #
##############################

# Modif des script de démarrage Zabbix pour chkconfig
sed -i 1i"# chkconfig: 2345 55 25" /etc/init.d/zabbix_agentd
sed -i 1i"# chkconfig: 2345 55 25" /etc/init.d/zabbix_server

chkconfig zabbix_agentd on
chkconfig zabbix_server on
chmod +x /etc/init.d/zabbix_server
chmod +x /etc/init.d/zabbix_agentd
/etc/init.d/zabbix_server restart
/etc/init.d/zabbix_agentd restart

#### END ZABBIX SERVER & AGENT PROCESS INSTALL & START

##############################
# INTERFACE WEB #
##############################

#### BEGIN WEB

rm -rf /var/www/html/zabbix
mkdir -p /var/www/html/zabbix
cd $SRC/zabbix-$ZBX_VER/frontends/php/
cp -a . /var/www/html/zabbix/
chown -R apache:apache /var/www/html/zabbix


cd /etc
sed -e "s/max_execution_time = 30/max_execution_time = 600/g" /etc/php.ini > /usr/src/mytmpphp; mv /usr/src/mytmpphp /etc/php.ini
sed -e "s/max_input_time = 60/max_input_time = 600/g" /etc/php.ini > /usr/src/mytmpphp1; mv /usr/src/mytmpphp1 /etc/php.ini
sed -e "s/memory_limit = 128M/memory_limit = 512M/g" /etc/php.ini > /usr/src/mytmpphp2; mv /usr/src/mytmpphp2 /etc/php.ini
sed -e "s/post_max_size = 8M/post_max_size = 32M/g" /etc/php.ini > /usr/src/mytmpphp3; mv /usr/src/mytmpphp3 /etc/php.ini
sed -e "s/upload_max_filesize = 2M/upload_max_filesize = 16M/g" /etc/php.ini > /usr/src/mytmpphp4; mv /usr/src/mytmpphp4 /etc/php.ini
sed -e "s/;date.timezone =/date.timezone = Europe\/Paris/g" /etc/php.ini > /usr/src/mytmpphp5; mv /usr/src/mytmpphp5 /etc/php.ini


cat > /var/www/html/zabbix/conf/zabbix.conf.php << "eof"
<?php
// Zabbix GUI configuration file
global $DB;

$DB['TYPE']			= 'MYSQL';
$DB['SERVER']			= '_dbhost_';
$DB['PORT']			= '0';
$DB['DATABASE']		= 'zabbix';
$DB['USER']			= '_dbuser_';
$DB['PASSWORD']		= '_dbpass_';

// SCHEMA is relevant only for IBM_DB2 database
$DB['SCHEMA']			= '';

$ZBX_SERVER				= 'localhost';
$ZBX_SERVER_PORT		= '10051';
$ZBX_SERVER_NAME		= 'zabbix.demo.somone.fr';

$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
?>

eof

chmod 400 /var/www/html/zabbix/conf/zabbix.conf.php
chown apache /var/www/html/zabbix/conf/zabbix.conf.php

sed "s/_dbhost_/${DBHOST}/g" /var/www/html/zabbix/conf/zabbix.conf.php > /usr/src/mytmp393; mv /usr/src/mytmp393 /var/www/html/zabbix/conf/zabbix.conf.php
sed "s/_dbuser_/${DBZABBIX}/g" /var/www/html/zabbix/conf/zabbix.conf.php > /usr/src/mytmp393; mv /usr/src/mytmp393 /var/www/html/zabbix/conf/zabbix.conf.php
sed "s/_dbpass_/${DBZABBIXPWD}/g" /var/www/html/zabbix/conf/zabbix.conf.php > /usr/src/mytmp393; mv /usr/src/mytmp393 /var/www/html/zabbix/conf/zabbix.conf.php

/etc/init.d/httpd reload

##############################
# SNMP                       #
##############################

# Configuration de SNMP
cd /etc/snmp
sed -i 56i"view all    included  .1                               80" /etc/snmp/snmpd.conf
sed "s/exact  systemview none none/exact  all none none/g" /etc/snmp/snmpd.conf > /usr/src/mytmp395; mv /usr/src/mytmp395 /etc/snmp/snmpd.conf


/etc/init.d/snmpd restart
chkconfig snmpd on

cd 
#clear
echo "*****************************"
echo "Load http://localhost/zabbix/"
echo "username: admin"
echo "password: zabbix"
echo "*****************************"
