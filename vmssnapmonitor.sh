#!/bin/bash

##----------------------------------------------------------------------------##
## Zabbix monitor Snapshots's VMs on vmware host.                             ##
##                                                                            ##
## Requirements:                                                              ##
##  * SSHPASS installed.                                                      ##
##  * root password registered in zabbix's macro.                             ##
##  * /usr/lib/zabbix/externalscripts/vmssnapmonitor.sh to exist              ##
##  * Zabbix 2.2+                                                             ##
##                                                                            ##
## Created: 03 Jan 2020   Rafael Magalhães      Unknown changes               ##
##----------------------------------------------------------------------------##

print_usage() {
  echo ""
  echo "If you need to make a VMs discovery:"
  echo "Usage: $0 [discovery] [esxi_hostname] [ssh_password]"
  echo ""
  echo "If you need to return snapshot age:"
  echo "Usage: $0 [age] [esxi_hostname] [ssh_password] [vmware_id] [snapshot_name]"
  echo ""
  echo "If you need to return snapshot total:"
  echo "Usage: $0 [total] [esxi_hostname] [ssh_password]"
  echo ""
  exit 3
}

vms_discovery() {
OldIFS=$IFS
IFS="
"

echo '{"data":['

for vm in "${vms[@]}"; do
  id=`echo $vm |awk -F: '{print $1}'`
  vmname=`echo $vm |awk -F: '{print $2}'`
  snapshotnum=`sshpass -p "$pass" ssh -o 'StrictHostKeyChecking=no' $user@$host vim-cmd vmsvc/snapshot.get $id |grep "Snapshot Name" |wc -l`
  if [ "$snapshotnum" -gt 0 ]; then
    snapshotsname=(`sshpass -p "$pass" ssh -o 'StrictHostKeyChecking=no' $user@$host vim-cmd vmsvc/snapshot.get $id |grep "Snapshot Name" | awk -F': ' '{print $2}'`);
    for snapname in ${snapshotsname[@]}; do
      if [ $i -gt 0 ]; then
        printf  ','
        echo
      fi
      printf '{"{#ID}":"%s", "{#VMNAME}":"%s", "{#SNAPNAME}":"%s"}' "$id" "$vmname" "$snapname"
      let i++;
    done
  fi
done

echo
echo ']}'

IFS=$OldIFS
}

snap_age() {
# Convert actual date to unix time
datenow=`date '+%Y-%m-%d'`
convertdatenow=$(date --date=$datenow "+%s")
snapshotdate=`sshpass -p $pass ssh -o 'StrictHostKeyChecking=no' $user@$host vim-cmd vmsvc/snapshot.get $vmid | grep -A3 "$snapname" | grep Created | awk -F': ' '{print $2}' | awk -F' ' '{print $1}'`
convertstrtodate=$(date --date=$snapshotdate "+%Y-%m-%d")
convertdatetounix=$(date --date=$convertstrtodate "+%s")
let "uptime=$convertdatenow-$convertdatetounix";
echo "$uptime"
}

snap_total() {
for vm in "${vms[@]}"; do
  id=`echo $vm |awk -F: '{print $1}'`
  snapshotnum=`sshpass -p "$pass" ssh -o 'StrictHostKeyChecking=no' $user@$host vim-cmd vmsvc/snapshot.get $id |grep "Snapshot Name" |wc -l`
  if [ "$snapshotnum" -gt 0 ]; then
    let "snaptotal=$snaptotal+$snapshotnum";
  fi
done
echo "$snaptotal"
}

## Global Variables
vms=(`sshpass -p "$4" ssh -o 'StrictHostKeyChecking=no' $3@$2 vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' | awk '$1 ~ /^[0-9]+$/ {print  $1":"substr($0,8,80)}'|sort`);
let i=0;
let snapshotnum=0;
let snaptotal=0;
let uptime=0;

## Call functions

case "$1" in
  --help)
    print_usage
  ;;
  -h)
    print_usage
  ;;
esac

case "$1" in
  discovery)
    host=$2
	user=$3
    pass=$4
    vms_discovery
  ;;
esac

case "$1" in
  age)
    host=$2
	user=$3
    pass=$4
    vmid=$5
    snapname=$6
    snap_age
  ;;
esac

case "$1" in
  total)
    host=$2
	user=$3
    pass=$4
    snap_total
  ;;
esac

exit 0
