
FIO=/usr/bin/fio


helpFunction()
{
   echo ""
   echo "Usage: $0 -a outputfile"
   echo -e "\t-a Nodename to be put in outputfile"
   exit 1 # Exit script after printing help
}

while getopts "a:" opt
do
   case "$opt" in
      a ) outputfile="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$outputfile" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction

fi

BasicConsistency()
{
        local TESTNAME=$1
        local DEVICENAME=$2
        local RWRATIO=$3
        local BLOCKSIZE=$4
        local DEVICENAME_dual=$5
        local DRIVEBASE=$(basename $DEVICENAME)
        local DRIVEBASE_dual=$(basename $DEVICENAME_dual)

        if [ ${RWRATIO} = "random" ]; then
                local RdPortion="0 70 100"
                local QueueDepth="2"
                local WorkerNum="2"
                for RP in $RdPortion
                do
                        for QD in $QueueDepth
                        do
                                for WN in $WorkerNum
                                do
                                        $FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE}.${BLOCKSIZE}.Random.Read_${RP}.QD_${QD}.Worker_${WN}.output --name=${TESTNAME}.name --write_iops_log=${TESTNAME}.${DRIVEBASE}.${BLOCKSIZE}.Random.Read_${RP}.QD_${QD}.Worker_${WN}.iops.log --filename=${DEVICENAME} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=10s --blocksize=${BLOCKSIZE} --rw=randrw --rwmixread=${RP} --iodepth=${QD} --overwrite=1 --numjobs=${WN} --group_reporting --ba=4k
                                done
                        done
                done
	fi
        echo Done
}


BasicConsistency "PM1733_8TB" "/dev/nvme0n1" "random" "4k"
