#!/bin/bash

while getopts ":d:i:o:C:Q:" opt; do
        case $opt in
                d)
                  db="$OPTARG"
                  ;;
                i)
                  f_in="$OPTARG"
                  ;;
                o)
                  f_out="$OPTARG"
                  ;;
                C)
                  f_ckpt="$OPTARG"
                  ;;
                Q)
                  f_pm="$OPTARG"
                  ;;
                \?)
                  echo "invalid option: -$OPTARG" >&2
                  exit 1
                  ;;
                :)
                  echo "Option -$OPTARG requires an argument" >&2
                  exit 1
                  ;;
        esac
done

echo psiblast -db $db -query $f_in -out_pssm $f_ckpt -Q