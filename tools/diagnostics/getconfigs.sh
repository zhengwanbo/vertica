#!/bin/bash

CurDir=$(cd "$(dirname $0)"; pwd)

CONFIGPATH=$CurDir/_config

getconfigfile ()
{
  filename=$1
  
  lpath=$CONFIGPATH/$(cd "$(dirname $filename)"; pwd)
  
  mkdir -p $lpath
  cp $filename $lpath
}


echo config files beginning...

if [ -d $CONFIGPATH ] ; then
  rm -rf $CONFIGPATH
fi

#########################
# Host
#########################
echo get host information ...

getconfigfile /etc/sysctl.conf
getconfigfile /etc/security/limits.conf


if [ -e /etc/modprobe.conf ]; then 
  getconfigfile /etc/modprobe.conf 
fi

getconfigfile /etc/rc.local

getconfigfile /etc/profile

if [ -f /etc/grub.conf ]; then 
  getconfigfile /etc/grub.conf
fi

if [ -f /etc/sysconfig/clock ]; then 
  getconfigfile /etc/sysconfig/clock
fi


if [ -f /root/.profile ]; then 
  getconfigfile /root/.profile
fi

if [ -f /root/.bash_profile ]; then 
  getconfigfile /root/.bash_profile
fi


if [ -f /home/dbadmin/.profile ]; then 
  getconfigfile /home/dbadmin/.profile
fi

if [ -f /home/dbadmin/.bash_profile ]; then 
  getconfigfile /home/dbadmin/.bash_profile
fi

#########################
# Disk
#########################
getconfigfile /etc/fstab



#########################
# Network
#########################
echo get network information ...

getconfigfile /etc/hosts
getconfigfile /etc/sysconfig/network

getconfigfile /etc/resolv.conf

getconfigfile /sbin/ifconfig

if [ -d /etc/sysconfig/network-scripts ]; then
  for nic in /etc/sysconfig/network-scripts/ifcfg* ; do
    getconfigfile $nic
  done
fi


#########################
# ODBC
#########################
echo get odbc information ...

if [ -e /etc/odbc.ini ]; then 
  getconfigfile /etc/odbc.ini
fi

if [ -e /etc/odbcinst.ini ]; then 
  getconfigfile /etc/odbcinst.ini
fi


if [ -d $CONFIGPATH ] ; then
  cd $CONFIGPATH
  tar czvf $CurDir/configs-`date +%Y%m%d%H%M%S`.tgz * 2>&1 > /dev/null
  cd $CurDir
  rm -rf $CONFIGPATH
fi


echo end config files
