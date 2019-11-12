#!/bin/sh

get_memsize()
{
   echo "# HELP ${KRYPT}_total_ram ${KRNAME} Total RAM"
   echo "# TYPE ${KRYPT}_total_ram gauge"
   RAM=$(cat /proc/meminfo |grep MemTotal|awk '{print $2/1024/1024}'); echo "${KRYPT}_total_ram $RAM";
   echo "# HELP ${KRYPT}_size_of_statedb ${KRNAME} size of statedb database"
   echo "# TYPE ${KRYPT}_size_of_statedb gauge"
   DBSIZE=$(ls -la $DATADIR/state/shared_memory.bin | awk '{ print $5 }'); DBSIZE=$(echo "scale=2; $DBSIZE / 1073741824" | bc); echo "${KRYPT}_size_of_statedb $DBSIZE";
   echo "# HELP ${KRYPT}_usage_of_state ${KRNAME} usage of database"
   echo "# TYPE ${KRYPT}_usage_of_state gauge"
   DBUSAGE=$(du  $DATADIR/state/shared_memory.bin | awk '{print $1}'); DBUSAGE=$(echo "scale=4; $DBUSAGE / 1048576" | bc); echo "${KRYPT}_usage_of_state $DBUSAGE";
   echo "# HELP ${KRYPT}_free_bytes_of_statedb ${KRNAME} free bytes of statedb database"
   echo "# TYPE ${KRYPT}_free_bytes_of_statedb gauge"
   DBSIZE=$(ls -la $DATADIR/state/shared_memory.bin | awk '{ print $5 }'); DBUSAGE=$(du  $DATADIR/state/shared_memory.bin | awk '{print $1*1024}'); FREE=$(echo "scale=2; ($DBSIZE - $DBUSAGE) / 1073741824" | bc); echo "${KRYPT}_free_bytes_of_statedb $FREE"
   #FREE=$(curl -s http://127.0.0.1:8888/v1/db_size/get | jq ".free_bytes" | sed -e  's/"//g'); FREE=$(echo "scale=2; $FREE / 1073741824" | bc); echo "eos_free_bytes_of_statedb $FREE"
   echo "# HELP ${KRYPT}_size_of_blocklog ${KRNAME} Size of blocks log"
   echo "# TYPE ${KRYPT}_size_of_blocklog gauge"
   BLOCK=$(ls -la  $DATADIR/blocks/blocks.log | awk ' { print $5/1073741824 } '); echo "${KRYPT}_size_of_blocklog $BLOCK"
   echo "# HELP ${KRYPT}_size_of_reversibledb ${KRNAME} Size of reversible database"
   echo "# TYPE ${KRYPT}_size_of_reversibledb gauge"
   REVERS=$(ls -la  $DATADIR/blocks/reversible/shared_memory.bin | awk ' { print $5/1073741824 } '); echo "${KRYPT}_size_of_reversibledb $REVERS"
   echo "# HELP ${KRYPT}_usage_of_reversibledb ${KRNAME} usage of reversible database"
   echo "# TYPE ${KRYPT}_usage_of_reversibledb gauge"
   REVERSUSAGE=$(du  $DATADIR/blocks/reversible/shared_memory.bin | awk '{print $1}'); REVERSUSAGE=$(echo "scale=4; $REVERSUSAGE / 1048576" | bc); echo "${KRYPT}_usage_of_reversibledb $REVERSUSAGE";
   echo "# HELP ${KRYPT}_free_bytes_of_reversibledb ${KRNAME} free bytes of reversible database"
   echo "# TYPE ${KRYPT}_free_bytes_of_reversibledb gauge"
   REVERS=$(ls -la $DATADIR/blocks/reversible/shared_memory.bin | awk '{ print $5 }'); REVERSUSAGE=$(du  $DATADIR/blocks/reversible/shared_memory.bin | awk '{print $1*1024}'); FREE=$(echo "scale=2; ($REVERS - $REVERSUSAGE) / 1073741824" | bc); echo "${KRYPT}_free_bytes_of_reversibledb $FREE"
   echo "# HELP ${KRYPT}_free_space_of_disk ${KRNAME} Free space of disk"
   echo "# TYPE ${KRYPT}_free_space_of_disk gauge"
   FREESPACEDISK=`df $MOUNTP | grep -v "Available" | awk '{print $4}'`; FREESPACEDISK=$(echo "scale=2; $FREESPACEDISK * 1024 / 1073741824" | bc); echo "${KRYPT}_free_space_of_disk $FREESPACEDISK"
}

get_headblock()
{
   BLOCK=`curl --insecure --connect-timeout 6 -s http://127.0.0.1:8888/v1/chain/get_info |jq -r ".head_block_num"`
   if [ -z $BLOCK ]; then
      echo "# HELP ${KRYPT}_head_block $KRNAME Head Block"
      echo "# TYPE ${KRYPT}_head_block gauge"
      echo "${KRYPT}_head_block -10"
   else
      echo "# HELP ${KRYPT}_head_block $KRNAME Head Block"
      echo "# TYPE ${KRYPT}_head_block gauge"
      echo "${KRYPT}_head_block $BLOCK"
   fi
}

get_libblock()
{
   BLOCK=`curl --insecure --connect-timeout 6 -s http://127.0.0.1:8888/v1/chain/get_info |jq -r ".last_irreversible_block_num"`
   if [ -z $BLOCK ]; then
      echo "# HELP ${KRYPT}_lib_block $KRNAME Lib Block"
      echo "# TYPE ${KRYPT}_lib_block gauge"
      echo "${KRYPT}_lib_block -10"
   else
      echo "# HELP ${KRYPT}_lib_block $KRNAME Lib Block"
      echo "# TYPE ${KRYPT}_lib_block gauge"
      echo "${KRYPT}_lib_block $BLOCK"
   fi
}

get_cpu_usage()
{
   NODEPID=`netstat -tlpn 2>/dev/null | grep "0.0.0.0:8888"|awk '{print $7}'| sed 's/\/nodeos//g'|sed 's/ //g'`
   if [ -z "$NODEPID" ]; then
      echo ""
   else
      CPUUSAGE=$(ps -p $NODEPID -o %cpu | grep -v '%CPU'|sed 's/ //g')
   fi

   if [ -z $CPUUSAGE ]; then
      echo "# HELP ${KRYPT}_cpu_usage $KRNAME Cpu Usage"
      echo "# TYPE ${KRYPT}_cpu_usage gauge"
      echo "${KRYPT}_cpu_usage -10"
   else
      echo "# HELP ${KRYPT}_cpu_usage $KRNAME Cpu Usage"
      echo "# TYPE ${KRYPT}_cpu_usage gauge"
      echo "${KRYPT}_cpu_usage $CPUUSAGE"
   fi
}

get_mem_usage()
{
   NODEPID=`netstat -tlpn 2>/dev/null | grep "0.0.0.0:8888"|awk '{print $7}'| sed 's/\/nodeos//g'|sed 's/ //g'`
   if [ -z "$NODEPID" ]; then
       echo ""
   else
      MEMUSAGE=$(ps -p $NODEPID -o %mem | grep -v '%MEM'|sed 's/ //g')
   fi

   if [ -z $MEMUSAGE ]; then
      echo "# HELP ${KRYPT}_mem_usage $KRNAME Mem Usage"
      echo "# TYPE ${KRYPT}_mem_usage gauge"
      echo "${KRYPT}_mem_usage -10"
   else
      echo "# HELP ${KRYPT}_mem_usage $KRNAME Mem Usage"
      echo "# TYPE ${KRYPT}_mem_usage gauge"
      echo "${KRYPT}_mem_usage $MEMUSAGE"
   fi
}

KRYPT="tlos"
KRNAME="TLOS"
# Dir of EOS data
DATADIR=/home/itadmin/.local/share/eosio/nodeos/data
# Dir for collector. Create this file at first
METRICDIR=/home/itadmin/node_exporter/textfile_collector
# Mount point. for choose mount point use df -h
MOUNTP="/"

   get_memsize > ${METRICDIR}/eos_metrics.prom
   get_headblock >> ${METRICDIR}/eos_metrics.prom
   get_libblock >> ${METRICDIR}/eos_metrics.prom
   get_cpu_usage >> ${METRICDIR}/eos_metrics.prom
   get_mem_usage >> ${METRICDIR}/eos_metrics.prom
