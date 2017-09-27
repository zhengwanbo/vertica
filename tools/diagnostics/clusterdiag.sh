#!/bin/bash

CurDir=$(pwd)
ScriptDir=$(cd "$(dirname $0)"; pwd)
LOGFILE=/tmp/clusterdiag-`date +%Y%m%d%H%M%S`.log

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

if [ "X$NODE_LIST" = "X" ]; then
  NODE_LIST="v001 v002 v003 v004 v005 v006 v007 v008"
fi
SELF=`hostname`

# diagnostics 
for s in $NODE_LIST; do
  echo start diag on $s ...
  ssh -i $sshauth -n $s "nohup $ScriptDir/diagnostics.sh $LOGFILE.$s >/dev/null 2>&1" &
done
wait

# get result 
for s in $NODE_LIST; do
  showcmd diagnostics infos of $s
  ssh -i $sshauth $s "cat $LOGFILE.$s" >>$LOGFILE
done


# network bandwidth test
echo start network bandwidth test...
showcmd Network bandwidth test

SAVE_IFS=$IFS
unset IFS
showcmd $ScriptDir/vnetperf --hosts $(tr " " ","<<<$NODE_LIST) --duration 30 --condense --output-file /dev/null
$ScriptDir/vnetperf --hosts $(tr " " ","<<<$NODE_LIST) --duration 30 --condense --output-file /dev/null  2>&1 >>$LOGFILE
IFS=$SAVE_IFS

echo "Diagnostics finished."
mv $LOGFILE $CurDir/
echo "Diagnostics result: $CurDir/$(basename $LOGFILE)"
