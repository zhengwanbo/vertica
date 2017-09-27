#!/bin/bash

DATA_DIR="/data"

CurDir=$(pwd)
ScriptDir=$(cd "$(dirname $0)"; pwd)

if [ "X$1" = "X" ]; then
  LOGFILE=$CurDir/diagnostics-`date +%Y%m%d%H%M%S`.log
else
  LOGFILE="$1"
fi

showcmd ()
{
  echo "" >>$LOGFILE
  echo "*********************" >>$LOGFILE
  echo "*" "$*">>$LOGFILE
  echo "*********************" >>$LOGFILE
}

runcmd ()
{
  showcmd $*

  `$* >>$LOGFILE`
}


runscript ()
{
  showcmd $*
  
  echo "$*" > $ScriptDir/_tmpcmd.sh
  .  $ScriptDir/_tmpcmd.sh >>$LOGFILE 2>&1
  rm -rf $ScriptDir/_tmpcmd.sh
}


cat /dev/null > $LOGFILE

echo Diagnostics beginning...

#########################
# Host
#########################
echo get host information ...

runcmd /bin/hostname
runcmd uname -a

runscript "if [ -f '/etc/redhat-release' ]; then /bin/cat /etc/redhat-release; fi"

runcmd /bin/cat /proc/cpuinfo
runcmd /bin/cat /proc/meminfo
runcmd /bin/cat /proc/sys/vm/swappiness

runcmd /bin/cat /etc/sysctl.conf
runcmd ulimit -a
runcmd /bin/cat /etc/security/limits.conf

runscript "if [ -e /etc/modprobe.conf ]; then /bin/cat /etc/modprobe.conf; else echo '/etc/modprobe.conf not found'; fi"
runscript "if [ -d /etc/modprobe.d ]; then for mod in \`ls /etc/modprobe.d/*\`;do echo [$""mod]; /bin/cat $""mod; done; fi"

runcmd /bin/cat /etc/rc.local

runscript "if [ -f '/etc/grub.conf' ]; then /bin/cat /etc/grub.conf; fi"

runscript "set"

runscript "if [ -f '/etc/profile' ]; then /bin/cat /etc/profile; fi"
runscript "if [ -f '/root/.bash_profile' ]; then /bin/cat /root/.bash_profile; fi"
runscript "if [ -f '/home/dbadmin/.bash_profile' ]; then /bin/cat /home/dbadmin/.bash_profile; fi"

#########################
# CPU
#########################
echo get cpu scaling info ...

runcmd $ScriptDir/vcpuperf -q

#########################
# MEM
#########################
echo test memory ...

for i in 2 4 8 16 32 64 128 256 1024 ; do
  runscript "echo test memory on $i MB; $ScriptDir/vmemperf $i 10"; 
done
FreeMemMB=`cat /proc/meminfo | grep MemFree | awk '{ print int($2/1024*2/3)}'`
runscript "echo test memory on ${FreeMemMB} MB; $ScriptDir/vmemperf ${FreeMemMB} 1"; 

#########################
# Disk
#########################
echo get disk information ...

runcmd df -h

runscript "if [ -e /usr/sbin/hpacucli ]; then /usr/sbin/hpacucli ctrl all show config detail; else echo '/usr/sbin/hpacucli not found'; fi"
runscript "if [ -e /opt/MegaRAID/storcli/storcli64 ]; then /opt/MegaRAID/storcli/storcli64 /call show; /opt/MegaRAID/storcli/storcli64 /call/vall show all; else echo '/opt/MegaRAID/storcli/storcli64'; fi"

bs=256K
count=40000 
runscript "mkdir -p $DATA_DIR/disktest; echo 'test disk writing...'; sync; echo 3 > /proc/sys/vm/drop_caches; dd of=$DATA_DIR/disktest/test.dat if=/dev/zero bs=$bs count=$count oflag=direct ; sync; echo 3 > /proc/sys/vm/drop_caches; echo 'test disk reading...'; sleep 3; time dd if=$DATA_DIR/disktest/test.dat of=/dev/null bs=$bs count=$count iflag=direct; rm -rf $DATA_DIR/disktest"

runcmd $ScriptDir/vioperf --duration=10m --condense-log $DATA_DIR

echo summary for vioperf ...

# for test in Write ReWrite Read SkipRead ; do counter=$(grep -w ${test} ${LOGFILE} | grep -v ': ' | grep -v count | awk '{print$5}' | sort -u) ; printf '\t%s' ${test}\(${counter}\) ; done ; printf '\n'; for test in Write ReWrite Read SkipRead ; do ave=$(grep -w ${test} ${LOGFILE} | grep -v ':' | grep -v count | awk -F '|' 'BEGIN{sum=0; n=0} {sum+=$4; n+=1} END{print sum/n}') ; printf '\t%s' ${ave}; done; printf '\n'
runscript "for test in Write ReWrite Read SkipRead ; do counter=\$(grep -w \${test} ${LOGFILE} | grep -v ': ' | grep -v count | awk '{print \$5}' | sort -u) ; printf '\t%s' \${test}\(\${counter}\) ; done ; printf '\n'; for test in Write ReWrite Read SkipRead ; do ave=\$(grep -w \${test} ${LOGFILE} | grep -v ':' | grep -v count | awk -F '|' 'BEGIN{sum=0; n=0} {sum+=\$4; n+=1} END{print sum/n}') ; printf '\t%s' \${ave}; done; printf '\n'"


#########################
# Network
#########################
echo get network information ...

runcmd /bin/cat /etc/hosts
runcmd /bin/cat /etc/resolv.conf

runcmd /sbin/ifconfig
runscript "if [ -d /etc/sysconfig/network-scripts ]; then for nic in \`ls /etc/sysconfig/network-scripts/ifcfg*\`;do echo [$""nic]; /bin/cat $""nic; done; fi"
runscript "if [ -d /proc/net/bonding ]; then for nic in \`ls /proc/net/bonding/*\`;do echo [$""nic]; /bin/cat $""nic; done; else echo 'Bonding not found'; fi"


echo "Diagnostics finished."
echo "Diagnostics result: $LOGFILE"


#########################
# check list
#########################

# check glibc
runcmd "rpm -qa glibc*"
# Note: If your version of glibc is 2.12 and does not have a .149 or later suffix, then your server may be affected by this issue. 
#   See https://rhn.redhat.com/errata/RHBA-2014-0480.html and https://rhn.redhat.com/errata/RHSA-2014-1391.html

runscript "objdump -r -d /lib64/libc-*.so | grep -C 20 _int_free | grep -C 10 cmpxchg | head -21 | grep -A 3 cmpxchg | tail -1 | (grep '%r' && echo 'Your libc is likely buggy.' || echo 'Your libc looks OK.')"


# special for GP envirment
runcmd grep vm.overcommit_memory /etc/sysctl.conf
# Action: change vm.overcommit_memory to default value, 0
#    uncomment vm.overcommit_memory line
#    cls_run "hostname; sysctl -p"


runcmd grep ^SELINUX= /etc/selinux/config
# Action: turn off SELINUX
# cls_run "sed -i 's/\s*SELINUX=\s*[^ ]*\.*/SELINUX=disabled/' /etc/selinux/config"
# cls_run setenforce 0

runcmd /sbin/chkconfig --list iptables
# Action: turn off iptables
#	cls_run "hostname; /sbin/chkconfig iptables off"

runscript "grep processor /proc/cpuinfo | wc -l; grep 'cpu cores\|siblings' /proc/cpuinfo | sort -u"
# Action: turn off HyperThread

runscript "grep MHz /proc/cpuinfo | sort -u"

runcmd grep MemTotal /proc/meminfo

runscript "rsync --version | grep version"

runcmd /usr/bin/python -V

runscript "echo \${TZ}; echo \${LANG}"

runcmd grep "^HOSTNAME=" /etc/sysconfig/network

runcmd /bin/hostname -f

runcmd df -h

runcmd /sbin/chkconfig --list ntpd
runcmd service ntpd status

runcmd /sbin/runlevel

runcmd ulimit -n
runcmd ulimit -v

runcmd date
runscript "(export TZ='UTC'; date)"

# I/O subsystem checks:

runscript "/sbin/modinfo cciss | grep description"
runscript "/sbin/modinfo cciss | grep version"
runcmd rpm -q hpacucli
if [ -e /usr/sbin/hpacucli ]; then 
  runscript "/usr/sbin/hpacucli ctrl slot=0 show | grep Firmware"
  runscript "/usr/sbin/hpacucli ctrl slot=0 show | grep 'Total Cache Size' "
  runscript "/usr/sbin/hpacucli ctrl slot=0 show | grep 'Accelerator Ratio\|Cache Ratio' "
fi

runcmd rpm -q storcli
if [ -e /opt/MegaRAID/storcli/storcli64 ]; then 
  runcmd /opt/MegaRAID/storcli/storcli64 show all
  runcmd /opt/MegaRAID/storcli/storcli64 /call show
  runcmd /opt/MegaRAID/storcli/storcli64 /call/vall show all
fi

runcmd /bin/cat /sys/block/sd*/queue/scheduler
# Action: set scheduler to "deadline"

runcmd /bin/cat /sys/kernel/mm/redhat_transparent_hugepage/enabled
# Action: set redhat_transparent_hugepage to "never"
  
runcmd /bin/cat /sys/kernel/mm/redhat_transparent_hugepage/defrag
# Action: set redhat_transparent_hugepage to "never"

runcmd /bin/cat /sys/kernel/mm/redhat_transparent_hugepage/khugepaged/defrag
# Action: set redhat_transparent_hugepage to "no"

runcmd /bin/cat /proc/sys/vm/swappiness
# Action: set swappiness to "0"

runcmd /bin/cat /proc/sys/kernel/hung_task_timeout_secs
# Action: set swappiness to "0"

runcmd /sbin/blockdev --getra /dev/sd*
# Action: set ReadAHead to 8192/4096/2048/1024

runscript "/sbin/ifconfig -a | grep eth | awk '{print  \$1}' | xargs -i ethtool {}| grep 'eth\|Speed\|Link'"
