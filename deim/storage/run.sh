#!/bin/bash

NVDIMM_DIR=/mnt/pmem0/tanakams/oltp-benchmark
CMD_DIR=/home/tanakams/1216/oltp-benchmark-tools/pmem/build/src

ps=$((1024 * 1024 * 1024))
ls=$((512 * 1024))
#gdef='1 2 4 8 12 16 20 24 28 32 40 48 56 64 80 96 112 128'
#gdef="1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072"
#gdef="1 2 4 8 16 32 64 128 256 512 1024 2048"
gdef="1 4 16 64"
node_list='0 2'
thread_list='1 2 3'
cmd_list='writeLog'
repeat=1

rm_touch_truncate() {
    rm -f $1
    touch $1
    truncate --size ${2:-0} $1
}

for dn in ${NVDIMM_DIR}
do
    mkdir -p $dn
done

for node in $node_list
do

    for cmd in $cmd_list
    do

    for threads in $thread_list
    do

        result_file=result_${cmd}_${node}_$((${ls} / 1024))_${threads}
        rm_touch_truncate ${result_file}

        for dn in ${NVDIMM_DIR}
        do
            log_file_name=$dn/log_file
            for g in ${gdef}
            do
                for i in $(seq $repeat); do
                rm -f ${log_file_name}*
                c="numactl --cpunodebind ${node} --localalloc ${CMD_DIR}/${cmd} -log_file ${log_file_name} -pmem_size ${ps} -log_size ${ls} -group_size ${g}  -threads ${threads}"
                echo $c >&2
                echo -n "${cmd},${node},${ls},${g}, "
                $c
                sleep 1
                done
            done

        done | tee -a ${result_file}

    done
    done

done
