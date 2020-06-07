#!/bin/bash

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



SequentialWrite1loops()
{
	local TestName=$1
	local DEV=$2
	local bs=$3
	local DRIVEBASE=$(basename $DEV)
	
	echo Start Sequential write 1 loops

	$FIO --output=${outputfile}.${TestName}.${DRIVEBASE}${bs}BSequentialWrite1loops --name=SequentialWrite1loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --size=100% --loops=1 --blocksize=${bs} --rw=write --iodepth=128 --numjobs=1 --overwrite=1 --log_avg_msec=1000

	CheckError

	echo Finished sequential write conditioning.
}

SequentialWrite2loops()
{
	local TestName=$1
	local DEV=$2
	local bs=$3
	local DRIVEBASE=$(basename $DEV)
	
	echo Start Sequential write 2 loops

	$FIO --output=${outputfile}.${TestName}.${DRIVEBASE}${bs}BSequentialWrite2loops --name=SequentialWrite2loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --size=100% --loops=2 --blocksize=${bs} --rw=write --iodepth=128 --numjobs=1 --overwrite=1 --log_avg_msec=1000 --write_iops_log=${TestName}.${DRIVEBASE}.${bs}.Seq.write.QD_128.iops.log --ba=4k

	CheckError
	echo Finished sequential write conditioning.
}

RandomWrite8hours()
{
	local DEVType=$1
	local DEV=$2
	local bs=$3
	local DRIVEBASE=$(basename $DEV)
	echo Start Random write 8 hours

	if [ ${DEVType} = "nvme" ]; then 
		$FIO --output=${outputfile}.${DRIVEBASE}${bs}BRandomWrite1loops --name=RandomWrite1loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --time_based --runtime=8h --blocksize=${bs} --rw=randwrite --iodepth=128 --numjobs=16 --overwrite=1 --log_avg_msec=1000
	elif [ ${DEVType} = "sas" ]; then 
		$FIO --output=${outputfile}.${DRIVEBASE}${bs}BRandomWrite1loops --name=RandomWrite1loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --time_based --runtime=8h --blocksize=${bs} --rw=randwrite --iodepth=32 --numjobs=4 --overwrite=1 --log_avg_msec=1000
	else
		$FIO --output=${outputfile}.${DRIVEBASE}${bs}BRandomWrite1loops --name=RandomWrite1loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --time_based --runtime=8h --blocksize=${bs} --rw=randwrite --iodepth=32 --numjobs=1 --overwrite=1 --log_avg_msec=1000
	fi

	CheckError
	echo Finished random write conditioning.
}

RandomWrite1loops()
{
	local TestName=$1
	local DEV=$2
	local bs=$3
	local DRIVEBASE=$(basename $DEV)

	echo Start Random write 1 loops

	$FIO --output=${outputfile}.${TestName}.${DRIVEBASE}${bs}BRandomWrite1loops --name=RandomWrite1loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --size=100% --loops=1 --blocksize=${bs} --rw=randwrite --iodepth=64 --numjobs=16 --overwrite=1 --log_avg_msec=1000 --write_iops_log=${TestName}.${DRIVEBASE}.${bs}.Ran.write.QD_64.iops.log --ba=4k

	CheckError
	echo Finished random write conditioning.
}

RandomWrite2loops()
{
	local TestName=$1
	local DEV=$2
	local bs=$3
	local DRIVEBASE=$(basename $DEV)

	echo Start Random write 2 loops

	$FIO --output=${outputfile}.${TestName}.${DRIVEBASE}${bs}BRandomWrite2loops --name=RandomWrite2loops --filename=${DEV} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --size=100% --loops=2 --blocksize=${bs} --rw=randwrite --iodepth=64 --numjobs=16 --overwrite=1 --log_avg_msec=1000 --write_iops_log=${TestName}.${DRIVEBASE}.${bs}.Ran.write.QD_64.iops.log --ba=4k

	CheckError
	echo Finished random write conditioning.
}

RandomRead()
{
	local DEV=$1
	local bs=$2
	local DRIVEBASE=$(basename $DEV)
	echo Start Random Read

	$FIO --output=${outputfile}.RandomRead --name=RandomRead --filename=${DEV} --ioengine=libaio --iodepth=64 --direct=1 --threads=1 --iodepth_batch=16 --iodepth_batch_complete=32 --time_based --norandommap --randrepeat=0 --blocksize=${bs} --rw=randread --numjobs=16 --timeout=6000 --runtime=600 --size=1G --nrfiles=1 --overwrite=1 --log_avg_msec=1000 --rate=16m,

	CheckError
	echo Finished random read.
}


CheckError()
{
  if [ $? != 0 ]; then
    echo ERROR
    exit 1;
  fi
}

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
		local QueueDepth="64"
		local WorkerNum="4 16" 
		for RP in $RdPortion
		do
			for QD in $QueueDepth
			do
				for WN in $WorkerNum
				do
					$FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE}.${BLOCKSIZE}.Random.Read_${RP}.QD_${QD}.Worker_${WN}.json --output-format=json --name=${TESTNAME}.name --write_iops_log=${TESTNAME}.${DRIVEBASE}.${BLOCKSIZE}.Random.Read_${RP}.QD_${QD}.Worker_${WN}.iops.log --filename=${DEVICENAME} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=600s --blocksize=${BLOCKSIZE} --rw=randrw --rwmixread=${RP} --iodepth=${QD} --overwrite=1 --numjobs=${WN} --group_reporting --ba=4k
				done
			done
		done

	elif [ ${RWRATIO} = "random_dual" ]; then 
		local RdPortion="0 70 100" 
		local QueueDepth="1 64"
		local WorkerNum="1 16" 
		for RP in $RdPortion
		do
			for QD in $QueueDepth
			do
				for WN in $WorkerNum
				do
					$FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE}.${BLOCKSIZE}.Random_dual.Read_${RP}.QD_${QD}.Worker_${WN}.output --name=${TESTNAME}.name --write_iops_log=${TESTNAME}.${DRIVEBASE}.${BLOCKSIZE}.Random_dual.Read_${RP}.QD_${QD}.Worker_${WN}.iops.log --filename=${DEVICENAME} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=120s --blocksize=${BLOCKSIZE} --rw=randrw --rwmixread=${RP} --iodepth=${QD} --overwrite=1 --numjobs=${WN} --group_reporting &
					$FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE_dual}.${BLOCKSIZE}.Random_dual.Read_${RP}.QD_${QD}.Worker_${WN}.output --name=${TESTNAME}.name2 --write_iops_log=${TESTNAME}.${DRIVEBASE_dual}.${BLOCKSIZE}.Random_dual.Read_${RP}.QD_${QD}.Worker_${WN}.iops.log --filename=${DEVICENAME_dual} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=120s --blocksize=${BLOCKSIZE} --rw=randrw --rwmixread=${RP} --iodepth=${QD} --overwrite=1 --numjobs=${WN} --group_reporting &
					wait
				done
			done
		done

	elif [ ${RWRATIO} = "sequential" ]; then 
		local RdPortion="0 100" 
		local QueueDepth="128"
		local TestSize="128k" 
		for TS in $TestSize
		do
			for QD in $QueueDepth
			do
				for RP in $RdPortion
				do
					$FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE}.Sequential.Testsize_${TS}.QD_${QD}.Read_${RP}.output --name=${TESTNAME}.name --write_iops_log=${TESTNAME}.${DRIVEBASE}.Sequential_${TS}.QD_${QD}.Read_${RP}.iops.log --filename=${DEVICENAME} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=120s --blocksize=${TS} --rw=rw --iodepth=${QD} --rwmixread=${RP} --overwrite=1 --numjobs=1 --group_reporting --ba=4k
				done
			done
		done

	elif [ ${RWRATIO} = "sequential_dual" ]; then 
		local RdPortion="0 100" 
		local QueueDepth="1 28"
		local TestSize="128 1M" 
		for TS in $TestSize
		do
			for QD in $QueueDepth
			do
				for RP in $RdPortion
				do
					$FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE}.Sequential_dual.Testsize_${TS}.QD_${QD}.Read_${RP}.output --name=${TESTNAME}.name --write_iops_log=${TESTNAME}.${DRIVEBASE}.Sequential_dual.Testsize_${TS}.QD_${QD}.Read_${RP}.iops.log --filename=${DEVICENAME} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=120s --blocksize=${TS} --rw=rw --iodepth=${QD} --rwmixread=${RP} --overwrite=1 --numjobs=1 --group_reporting &
					$FIO --output=${outputfile}.${TESTNAME}.${DRIVEBASE_dual}.Sequential_dual.Testsize_${TS}.QD_${QD}.Read_${RP}.output --name=${TESTNAME}.name2 --write_iops_log=${TESTNAME}.${DRIVEBASE_dual}.Sequential_dual.Testsize_${TS}.QD_${QD}.Read_${RP}.iops.log --filename=${DEVICENAME_dual} --ioengine=libaio --direct=1 --norandommap --randrepeat=0 --refill_buffers --time_based --ramp_time=5s --runtime=120s --offset=500G --blocksize=${TS} --rw=rw --iodepth=${QD} --rwmixread=${RP} --overwrite=1 --numjobs=1 --group_reporting &

					wait
				done
			done
		done

	fi
  	echo Done

}

## === Test Cases =========

#SequentialWrite2loops "PM1733_8TB" "/dev/nvme0n1" "128k"


#BasicConsistency "PM1733_8TB" "/dev/nvme0n1" "sequential"


#RandomWrite2loops "PM1733_8TB" "/dev/nvme0n1" "4k"


BasicConsistency "PM1733_8TB" "/dev/nvme0n1" "random" "4k"


