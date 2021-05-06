#!/bin/bash

while getopts i: flag
do
    case "${flag}" in
        i) input=${OPTARG};;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

export PATH="$DIR:$PATH"

echo $DIR

#python $DIR/NanoIgset.py $input $DIR

#$DIR/Setcorr.sh

#while read p; do
#  $p
#done <$DIR/bashexec.txt

python $DIR/collage.py $input

python $DIR/NanoIgRep.py $input

