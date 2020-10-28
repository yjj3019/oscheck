#!/bin/bash
#set -x

export LANG=C
export LC_ALL=C
export totime=`date +%m%d-%H%M`
outfile=/tmp/$(hostname)-$totime
num=0

echo "" > $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "\033[36m"System Info " \033[0m            " >> $outfile
echo -e "\033[36m"Hostname : $(hostname) " \033[0m            " >> $outfile
echo -e "\033[36m"OS Ver : $(cat /etc/redhat-release) " \033[0m            " >> $outfile
echo -e "\033[36m"Kernel Ver : $(uname -r) " \033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo "" >> $outfile
######################################################################################################################################
# CPU Check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "1. CPU INFO " \033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
if [ -f /usr/bin/lscpu ]
then
        /usr/bin/lscpu | egrep 'Model name|Socket|Thread|NUMA|CPU\(s\)' >> $outfile
	echo " " >> $outfile
elif [ -f /usr/sbin/dmidecode ]
then
        dmidecode -t 4 | egrep -i 'Socket Designation|core (count|enabled)|thread count|Version'| sort -n | uniq | sort >> $outfile
	echo " " >> $outfile
else
        echo " NOT FOUND CPU INFO COMMAND." >> $outfile
        echo " cat /proc/cpuinfo " >> $outfile
	echo " " >> $outfile

fi
######################################################################################################################################
# MEM Check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "2. MEM INFO "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
totmemory=$(echo "$(cat /proc/meminfo |grep MemTotal|awk '{print $2}') / 1024^2" | bc)
echo "Total Memory : $totmemory GB " >> $outfile

### Hugepage Check
cat /proc/meminfo |grep HugePages_Total|awk '{if($2>=1) print $1 $2}' > /tmp/hugepage.info
LC=`wc -l /tmp/hugepage.info|awk '{print $1}'`
if [ -s "/tmp/hugepage.info" ];then
        echo "Hugepage Enabled " >> $outfile
        echo "$(cat /tmp/hugepage.info) " >> $outfile
        echo "Detail View /proc/meminfo " >> $outfile
else
        echo -e "Hugepage Disabled   " >> $outfile
fi
rm -f /tmp/hugepage.info

### THP Check
grep "\[naver\]" /sys/kernel/mm/transparent_hugepage/enabled > /tmp/thp.info
LC=`wc -l /tmp/thp.info|awk '{print $1}'`
if [ -s "/tmp/thp.info" ];then
        echo "THP(Transparent Huge Pages) : Disabled " >> $outfile
        echo "Detail View : /sys/kernel/mm/transparent_hugepage/enabled  " >> $outfile
        echo "$(cat /tmp/thp.info) " >> $outfile
else
        echo "THP(Transparent Huge Pages) : Enabled " >> $outfile
fi
rm -f /tmp/thp.info
echo " " >> $outfile

######################################################################################################################################
# ip check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "3. Network_IP"\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

ip -4 addr|grep inet|sed -e 's/^ *//g' -e 's/ *$//g' >> $outfile
echo " " >> $outfile

########################################################################
# route check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "4. Routing Table"\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

route -n >> $outfile
echo " " >> $outfile

########################################################################
# bonding check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "5. Bonding "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

if [ -f /proc/net/bonding/bond[0-9] ]; then
	for value in $(find /proc/net/bonding/bond* -exec ls {} \;)
	do 
		echo "### $value" >> $outfile
		cat $value >> $outfile
	done
else
	echo "Bonding Not Setting"  >> $outfile
fi

echo " " >> $outfile

########################################################################
# FileSystem check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "6. FileSystem "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

df -Th >> $outfile
echo " " >> $outfile

########################################################################
# LVM check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "7. LVM "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

echo "### PVS " >> $outfile
pvs|sed -e 's/^ *//g' -e 's/ *$//g' >> $outfile
echo " " >> $outfile

echo "### VGS " >> $outfile
vgs|sed -e 's/^ *//g' -e 's/ *$//g' >> $outfile
echo " " >> $outfile

echo "### LVS " >> $outfile
lvs|sed -e 's/^ *//g' -e 's/ *$//g' >> $outfile
echo " " >> $outfile

########################################################################
# ntp check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "8. NTP, Chrony  "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
#ps -ef|grep /usr/sbin/chronyd|grep -v grep|wc -l > /tmp/chrony_check.info
ps -ef|grep /usr/sbin/chronyd|grep -v grep > /dev/null 2>&1
result1=$?
#ps -ef|grep /usr/sbin/ntpd|grep -v grep|wc -l > /tmp/ntpd_check.info
ps -ef|grep /usr/sbin/ntpd|grep -v grep  > /dev/null 2>&1
result2=$?
if [ $result1 -eq "0" ];then
	chronyc sources >> $outfile
elif [ $result2 -eq "0" ];then
	ntpq -p >> $outfile
else
	echo "Time Sync Service Not Found" >> $outfile
fi

echo " " >> $outfile

#rm -f /tmp/chrony_check.info
#rm -f /tmp/ntpd_check.info

########################################################################
# kdump check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "9. KDUMP "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

systemctl status kdump |grep active|sed -e 's/^ *//g' -e 's/ *$//g' >> $outfile
echo " " >> $outfile

########################################################################
# kernel parameter check
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile
echo -e "        \033[35m "10. sysctl -a "\033[0m            " >> $outfile
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $outfile

sysctl -a >> $outfile
echo " " >> $outfile

########################################################################
