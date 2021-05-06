#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi


#  Store must exist: correction/ighv1.gkpStore

#  Discover the job ID to run, from either a grid environment variable and a
#  command line offset, or directly from the command line.
#
if [ x$CANU_LOCAL_JOB_ID = x -o x$CANU_LOCAL_JOB_ID = xundefined -o x$CANU_LOCAL_JOB_ID = x0 ]; then
  baseid=$1
  offset=0
else
  baseid=$CANU_LOCAL_JOB_ID
  offset=$1
fi
if [ x$offset = x ]; then
  offset=0
fi
if [ x$baseid = x ]; then
  echo Error: I need CANU_LOCAL_JOB_ID set, or a job index on the command line.
  exit
fi
jobid=`expr $baseid + $offset`
if [ x$CANU_LOCAL_JOB_ID = x ]; then
  echo Running job $jobid based on command line options.
else
  echo Running job $jobid based on CANU_LOCAL_JOB_ID=$CANU_LOCAL_JOB_ID and offset=$offset.
fi

if [ $jobid -gt 1 ]; then
  echo Error: Only 1 partitions, you asked for $jobid.
  exit 1
fi

if [ $jobid -eq 1 ] ; then
  bgn=1
  end=484
fi

jobid=`printf %04d $jobid`

if [ -e "./results/$jobid.cns" ] ; then
  echo Job finished successfully.
  exit 0
fi

if [ ! -d "./results" ] ; then
  mkdir -p "./results"
fi

#  Store must exist: correction/ighv1.gkpStore

#  Store must exist: correction/ighv1.ovlStore

#  File must exist: ighv1.readsToCorrect

#  File must exist: ighv1.globalScores

gkpStore="../ighv1.gkpStore"


$bin/falconsense \
  -G $gkpStore \
  -C ../ighv1.corStore \
  -b $bgn -e $end -r ./ighv1.readsToCorrect \
  -t  4 \
  -cc 4 \
  -cl 300 \
  -oi 0.9 \
  -ol 300 \
  -p ./results/$jobid.WORKING \
  > ./results/$jobid.err 2>&1 \
&& \
mv ./results/$jobid.WORKING.cns ./results/$jobid.cns \

#  File is important: results/$jobid.cns

exit 0
