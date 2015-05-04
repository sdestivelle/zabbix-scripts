#!/bin/bash

#=====================================================================
#
# ZABBIX : Script d'installation de Zabbix version 2.4.5
# Copyright (c) 2010 Steve DESTIVELLE
#
#=====================================================================


#=====================================================================
#
# If necessary, modify the following variable to sweet your configuration
#
#=====================================================================

DBUSER='root'
DBPASS='somepassword'
DBHOST='localhost'

DBZABBIX='zabbix'
DBZABBIXPWD='somepassword'

ZBX_VER='2.4.5'
SRC='/usr/src'

# Test machine x86_64 ou i386
MACHINE_TYPE=`uname -m`

#=====================================================================
#
# Do not edit under this line
#
#=====================================================================

# DEBUT SCRIPT
cat << "eof"

=== RUN AT YOUR OWN RISK ===

DO NOT RUN ON EXISTING INSTALLATIONS, YOU *WILL* LOSE DATA

This script:
 * Installs Zabbix 2.4.5 on CentOS 7
 * Drops an existing zabbix database
 * Does not install zabbix packages, it uses source from zabbix.com

Press Ctrl-C now if you want to exit

Wait 20 seconds...
eof
sleep 20
# FIN SCRIPT


# Basic dependencies for the system
#
yum -y update
RETVAL=$?
checkReturn $RETVAL "Basic package install"

yum -y install wget vim gcc libcurl mariadb-server httpd php php-mysql openssl-devel ca-certificates glib2 libidn libidn-devel krb5-devel php-ldap libssh2 libssh2-devel pkgconfig OpenIPMI-perl perl lm_sensors-devel lm_sensors-libs net-snmp-devel net-snmp libsysfs libsysfs-devel net-snmp-perl fontconfig fontconfig-devel php-gd dejavu-fonts-common OpenIPMI OpenIPMI-devel mlocate mysql-libs mysql-devel libcurl libcurl-devel make php-mbstring php-bcmath net-snmp-utils patch php-xml php-pear java java-devel libxml2 libxml2-devel crontabs

if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  #
  # Installation de FPING 64
  #
  cd $SRC
  wget http://pkgs.repoforge.org/fping/fping-3.9-1.el6.rf.x86_64.rpm
  wait
  rpm -ivh fping-3.9-1.el6.rf.x86_64.rpm
  wait
else
  cd $SRC
  wget http://pkgs.repoforge.org/fping/fping-3.9-1.el6.rf.i686.rpm
  wait
  rpm -ivh fping-3.9-1.el6.rf.i686.rpm
  wait
fi

chmod 4755 /usr/sbin/fping

##############################
# Installation of Zabbix     #
##############################

#
# Zabbix download
#
cd /usr/src
rm -rf zabbix-$ZBX_VER
rm zabbix-$ZBX_VER.tar.gz
wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$ZBX_VER/zabbix-$ZBX_VER.tar.gz

#
# Extract et compillation
#
tar xzf zabbix-$ZBX_VER.tar.gz
cd zabbix-$ZBX_VER
./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --enable-java --with-openipmi --with-ssh2 --with-libxml2

# --with-jabber
# ipmi
# ldap
# support vmware libcurl + libxml2

make install

#############
# SELINUX   #
#############

#
# Disable selinux
#
cd /etc/selinux

sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

#
# Starting Mariadb
#
systemctl enable mariadb
systemctl start mariadb.service

#
# Configuration of Mariadb
#
/usr/bin/mysql_secure_installation

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
# Configuration of Apache    #
##############################

#
# Configuration of /etc/httpd/conf/httpd.conf, config of the variable ServerName
#
echo "ServerName zabbix" >> /etc/httpd/conf/httpd.conf
systemctl start httpd.service
systemctl enable httpd.service

##############################
# ZABBIX SERVER CONF         #
##############################

#
# Edit your /etc/zabbix/zabbix_server.conf
#
cp $SRC/zabbix-$ZBX_VER/conf/zabbix_server.conf /etc/zabbix/zabbix_server.conf

#
# ZABBIX_SERVER
# Grab the zabbix-server.service from my Github (https://github.com/sdestivelle/zabbix-scripts/tree/master/zabbix-2.4.5)
systemctl start zabbix-server.service
systemctl enable zabbix-server.service

##############################
# ZABBIX AGENT CONF          #
##############################

#
# Edit your /etc/zabbix/zabbix_agentd.conf
#
cp $SRC/zabbix-$ZBX_VER/conf/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf

#
# ZABBIX_AGENT
# Grab the zabbix-agent.service from my Github (https://github.com/sdestivelle/zabbix-scripts/tree/master/zabbix-2.4.5)
systemctl start zabbix-agent.service
systemctl enable zabbix-agent.service

chmod 400 /usr/local/etc/zabbix_*.conf 
chown zabbix /usr/local/etc/zabbix_*.conf

#################
# Web interface #
#################

rm -rf /var/www/html/zabbix
mkdir -p /var/www/html/zabbix
cd $SRC/zabbix-$ZBX_VER/frontends/php/
cp -a . /var/www/html/zabbix/
chown -R apache:apache /var/www/html/zabbix

# Edit the php.ini file with your configuration
#
cd /etc
sed -i 's/^max_execution_time.*/max_execution_time=600/' /etc/php.ini
sed -i 's/^max_input_time.*/max_input_time=600/' /etc/php.ini
sed -i 's/^memory_limit.*/memory_limit=512M/' /etc/php.ini
sed -i 's/^post_max_size.*/post_max_size=32M/' /etc/php.ini
sed -i 's/^upload_max_filesize.*/upload_max_filesize=16M/' /etc/php.ini
sed -i "s/^\;date.timezone.*/date.timezone=\'Europe\/Paris\'/" /etc/php.ini


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
$ZBX_SERVER_NAME		= 'zabbix';

$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
?>

eof

chmod 400 /var/www/html/zabbix/conf/zabbix.conf.php
chown apache /var/www/html/zabbix/conf/zabbix.conf.php

sed "s/_dbhost_/${DBHOST}/g" /var/www/html/zabbix/conf/zabbix.conf.php > /usr/src/mytmp393; mv /usr/src/mytmp393 /var/www/html/zabbix/conf/zabbix.conf.php
sed "s/_dbuser_/${DBZABBIX}/g" /var/www/html/zabbix/conf/zabbix.conf.php > /usr/src/mytmp393; mv /usr/src/mytmp393 /var/www/html/zabbix/conf/zabbix.conf.php
sed "s/_dbpass_/${DBZABBIXPWD}/g" /var/www/html/zabbix/conf/zabbix.conf.php > /usr/src/mytmp393; mv /usr/src/mytmp393 /var/www/html/zabbix/conf/zabbix.conf.php

systemctl reload httpd.service

##############################
# SNMP                       #
##############################

# Configuration of SNMP
cd /etc/snmp
sed -i 56i"view all    included  .1                               80" /etc/snmp/snmpd.conf
sed "s/exact  systemview none none/exact  all none none/g" /etc/snmp/snmpd.conf > /usr/src/mytmp395; mv /usr/src/mytmp395 /etc/snmp/snmpd.conf


systemctl restart snmpd.service
systemctl enable snmpd.service

cd 
#clear
echo "*****************************"
echo "Load http://localhost/zabbix/"
echo "username: admin"
echo "password: zabbix"
echo "*****************************"
