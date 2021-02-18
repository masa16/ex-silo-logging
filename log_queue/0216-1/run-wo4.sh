#! /bin/bash

silo_d='/home/tanakams/ccbench/silo'
extime=8
repeat=5
node_num=8
node_list='0,1,2,3,4,5,6,7'
core_nums='1 2 4 8 12 16 20 24 28'
#core_nums=28
logger_nums='0 1 2 3'
#logger_nums=4
#buffer_nums='2 4 8 16'
buffer_nums=4
#buffer_sizes='64 128 256 512 768 1024 1280 1536 2048'
buffer_sizes=512
#devices='ssd pmem'
devices='pmem'
blktr="sudo blktrace -w ${extime} -d /dev/sda -o sda"
#perf="perf stat -x, -o perf.log -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses"
#epoch_diffs='0 2 3 4'
#epoch_times='1 2 0.5'
epoch_diffs='0'
epoch_times='40'

exe_dir() {
  local b=$1
  local s
  if [ $logger_per_node -eq 0 ]; then
    s="0log"
  else
    case "$b" in
     *-ed2) s="nlog_diff2";;
     *-ed3) s="nlog_diff3";;
     *-ed4) s="nlog_diff4";;
     *)     s="nlog_deqmin";;
    esac
  fi
  exe_d=test_$s
}

run() {
  local b=$1
  mkdir -p $b
  opt="-extime ${extime} -clocks_per_us 2095 -rratio 0 -epoch_time ${epoch_time}"
  for w in $core_nums; do
    i=0
    for j in $(seq $((repeat*3))); do
      if [ $w -ge $((logger_per_node*2)) ]; then
        local d=l$logger_per_node-w$((w*node_num))-bn$buffer_num-bs$buffer_size-r$j
        exe_dir $b
        if [ $logger_per_node -gt 0 ]; then
          rm -rf log*
          local numa="$silo_d/numa.rb $node_list $((w-logger_per_node)) $logger_per_node"
          echo $numa | tee -a $b.log
          local a=$($numa)
          local c="numactl --cpunodebind=$node_list --interleave=$node_list $silo_d/$exe_d/silo.exe $opt -buffer_num $buffer_num -buffer_size $buffer_size -affinity $a"
        else
          local c="numactl --cpunodebind=$node_list --interleave=$node_list $silo_d/$exe_d/silo.exe $opt -thread_num $((w*node_num))"
          ((i++))
        fi
        echo $perf $c | tee -a $b.log
        $perf $c |& tee -a $b.log
        if [ -f perf.log ]; then
          awk -F, '$3~/^LLC-/ {print $3,$1}' perf.log |& tee -a $b.log
          rm perf.log
        fi
        echo "=== end_of_exec ===" |& tee -a $b.log
        if [ -f latency.dat ]; then
          mv latency.dat $b/latency-$d.dat
          ((i++))
        fi
        rm -f log*/*
        sleep $((extime))
        if [ $i -eq $repeat ]; then break; fi
      fi
    done
  done
}

log2csv() {
  local b=$1
  echo "thread_num,logger_num,buffer_num,buffer_size,clocks_per_us,epoch_time,extime,max_ope,rmw,rratio,tuple_num,ycsb,zipf_skew,throughput[tps],abort_rate,durabule_latency,log_throughput[B/s],write_latency_rate,write_count,buffer_count,byte_count,txn_latency,log_queue_latency,write_latency,notify_latency,backpressure_latency,wait_depoch_latency,mean_depoch_diff,sdev_depoch_diff,max_depoch_diff,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses" | tee $b.csv
  awk '
  /#FLAGS_clocks_per_us:/ {c1=$2;
    c2=c3=c4=c5=c6=c7=c8=c9=c10=c11=c12=c13=c14=d5=t=b=x=w=n=f=s=r=d1=d2=d3=d4=d5=d6=d7=e1=e2=e3=l1=l2=l3=l4="";}
  /#FLAGS_epoch_time:/ {c2=$2}
  /#FLAGS_extime:/ {c3=$2}
  /#FLAGS_max_ope:/ {c4=$2}
  /#FLAGS_rmw:/ {c5=$2}
  /#FLAGS_rratio:/ {c6=$2}
  /#FLAGS_thread_num:/ {c7=$2}
  /#FLAGS_logger_num:/ {c8=$2}
  /#FLAGS_buffer_num:/ {c9=$2}
  /#FLAGS_buffer_size:/ {c10=$2}
  /#FLAGS_tuple_num:/ {c11=$2}
  /#FLAGS_ycsb:/ {c12=$2}
  /#FLAGS_zipf_skew:/ {c13=$2}
  /^abort_rate:/ {a=$2}
  /^mean_depoch_diff:/ {e1=$2}
  /^sdev_depoch_diff:/ {e2=$2}
  /^max_depoch_diff:/  {e3=$2}
  /^txn_latency\[.s\]:/ {d1=$2}
  /^log_queue_latency\[.s\]:/ {d2=$2}
  /^write_latency\[.s\]:/ {d3=$2}
  /^notify_latency\[.s\]:/ {d4=$2}
  /^durable_latency\[.s\]:/ {d5=$2}
  /^backpressure_latency\[.s\]:/ {d6=$2}
  /^wait_depoch_latency\[.s\]:/ {d7=$2}
  /^throughput\(elap\)\[B\/s\]:/ {t=$2}
  /^wait_time\[s\]:/ {x=$2}
  /^write_time\[s\]:/ {w=$2}
  /^write_count:/ {n=$2}
  /^buffer_count:/ {f=$2}
  /^byte_count\[B\]:/ {s=$2}
  /^throughput\[tps\]:/ {c14=$2}
  /^LLC-loads / {l1=$2}
  /^LLC-load-misses / {l2=$2}
  /^LLC-stores / {l3=$2}
  /^LLC-store-misses / {l4=$2}
  /^=== end_of_exec ===$/ {
    if(x+w>0) {r=w/(x+w)};
    printf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
           c7,c8,c9,c10,c1,c2,c3,c4,c5,c6,c11,c12,c13,c14,a,d5,t,r,n,f,s,d1,d2,d3,d4,d6,d7,e1,e2,e3,l1,l2,l3,l4);}
' $b.log | tee -a $b.csv
}

b=$(basename ${0%.sh})
b=${b#run-}

for epoch_time in $epoch_times; do

  base=$b-nolog-et$epoch_time
  for logger_per_node in $logger_nums; do
    if [ $logger_per_node -eq 0 ]; then
      run $base
      log2csv $base
    fi
  done

  for device in $devices; do
    for epoch_diff in $epoch_diffs; do
      base=$b-$device-et$epoch_time-ed$epoch_diff
      for logger_per_node in $logger_nums; do
        if [ $logger_per_node -gt 0 ]; then
          for buffer_num in $buffer_nums; do
            for buffer_size in $buffer_sizes; do
              run $base
            done
          done
        fi
      done
      log2csv $base
    done
  done

done

#sudo chown -R $USER .
