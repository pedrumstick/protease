#!/bin/bash

echo "************************************************************"
echo "Started at: "`date +"%m/%d/%Y %H:%M:%S"`
echo "************************************************************"
SECONDS=0

prosper_dir=/root/prosper

input_file=$1
output_dir=$2
input_filename=$(awk 'BEGIN {FS=OFS="|"} NR==1 {print $1"_"$5}' $1 | sed 's/>//')

if [ ! -d ${output_dir} ]; then
  echo "Output directory doesn't exist. Creating "${output_dir}""
  mkdir -p ${output_dir}
fi
cd ${output_dir}

sed 's/\*$//g' ${input_file} > temp

# PSIPRED
start=$SECONDS
runpsipredplus temp
mv temp.ss2 ${input_filename}.ss2
duration=$((SECONDS-start))
echo "Runtime of PSIPRED: $(($duration / 60)) min $((duration % 60)) sec"

# DISOPRED
start=$SECONDS
run_disopred_plus.pl temp
mv temp.diso ${input_filename}.diso
duration=$((SECONDS-start))
echo "Runtime of DISOPRED: $(($duration / 60)) min $((duration % 60)) sec"

# ACCpro
start=$SECONDS
sequence_to_acc.sh temp ${input_filename}.acc 4
sed 's/-/b/g' ${input_filename}.acc > temp.acc
mv temp.acc ${input_filename}.acc
duration=$((SECONDS-start))
echo "Runtime of ACCpro: $(($duration / 60)) min $((duration % 60)) sec"

# PROSPER
start=$SECONDS
cd ${prosper_dir}
prosper.pl ${output_dir}/temp ${output_dir}/${input_filename}.ss2  ${output_dir}/${input_filename}.acc ${output_dir}/${input_filename}.diso > ${output_dir}/${input_filename}_output.txt
duration=$((SECONDS-start))
echo "Runtime of PROSPER: $(($duration / 60)) min $((duration % 60)) sec"

# Runtime
duration=$SECONDS
echo "Total pipeline runtime: $(($duration / 60)) min $((duration % 60)) sec"
echo "Ended at: "`date +"%m/%d/%Y %H:%M:%S"`

