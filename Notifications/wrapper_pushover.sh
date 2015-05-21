#!/bin/bash
#cd /usr/local/share/zabbix/alertscripts
# To do:
# Add the Application Token
# 
App_Token = XXXX

# The command
./pushover.sh -d Iphone -T $App_Token -s classical -U $1 -t $2 $3