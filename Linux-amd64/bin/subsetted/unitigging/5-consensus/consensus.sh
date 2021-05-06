#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi



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

if [ $jobid -gt 2 ]; then
  echo Error: Only 2 partitions, you asked for $jobid.
  exit 1
fi

if [ $jobid -le 1 ] ; then
  tag="ctg"
else
  tag="utg"
  jobid=`expr $jobid - 1`
fi

jobid=`printf %04d $jobid`

if [ ! -d ./${tag}cns ] ; then
  mkdir -p ./${tag}cns
fi

if [ -e ./${tag}cns/$jobid.cns ] ; then
  exit 0
fi

#  File must exist: seqDB.v001.dat
#  File must exist: seqDB.v001.tig

#  Store must exist: unitigging/ighv1.${tag}Store/partitionedReads.gkpStore

$bin/utgcns \
  -G ../ighv1.${tag}Store/partitionedReads.gkpStore \
  -T ../ighv1.${tag}Store 1 $jobid \
  -O ./${tag}cns/$jobid.cns.WORKING \
  -maxcoverage 40 \
  -e 0.192 \
  -pbdagcon \
  -edlib    \
  -threads 4 \
&& \
mv ./${tag}cns/$jobid.cns.WORKING ./${tag}cns/$jobid.cns \

#  File is important: ${tag}cns/$jobid.cns

exit 0
