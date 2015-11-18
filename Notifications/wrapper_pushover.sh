#!/bin/bash

#=====================================================================
#
# ZABBIX pushover notification wrapper
# Steve DESTIVELLE
#
# Modifications : 
# ---le--- -----par----- ---------------objet---------------
# 2015/06/12 S. DESTIVELLE   Creation of the script
# 2015/11/18 S. DESTIVELLE   Modification of the script (add device variable). Thanks to Marco
#
#=====================================================================

#cd /usr/local/share/zabbix/alertscripts
# To do:
# Add the Application Token
# Add the name of your device declared at "https://pushover.net"
# 
App_Token = XXXX
Device = XXX

# The command
./pushover.sh -d $Device -T $App_Token -s classical -U $1 -t $2 $3