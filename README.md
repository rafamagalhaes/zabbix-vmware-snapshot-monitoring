# zabbix-vmware-snapshot-monitoring
Script and template to vmware's snapshot monitor with Zabbix.

Download and import the tamplate "TEMPLATE_VMWARE_SNAPSHOT.xml" to your Zabbix.
#

Download the monitor script "vmssnapshotmonitor.sh" in externalscripts path on your Zabbix Server or Zabbix Proxy.
# wget https://github.com/rafamagalhaes/zabbix-vmware-snapshot-monitoring/raw/master/vmssnapmonitor.sh

On template, configure the macros {$user} and {$pass} with your vmware's username and password.
