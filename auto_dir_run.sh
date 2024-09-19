#!/bin/bash

# check the numbers of parameters
if [ $# -lt 1 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <directory_path> [dataset_name] [TP]"
    exit 1
fi


# obtain the dir path, dataset names, and TP
directory_path="$1"
dataset_name=""
TP=""

# check the second or third parameters provided.
if [ $# -eq 2 ]; then
    # if there are only two parameters, determine if it is dataset_name or TP
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        TP="$2"  # if the second is a number, it is TP
    else
        dataset_name="$2"  # else, it is dataset_name
    fi
elif [ $# -eq 3 ]; then
    dataset_name="$2"
    TP="$3"
fi


# traverse all folders in the directory
for folder in "$directory_path"/*/; do
    if [ -d "$folder" ]; then
        echo "Processing folder: $folder"
        # execute the command based on the passed parameters
        if [ -n "$dataset_name" ] && [ -n "$TP" ]; then
            bash scripts/run_eval.sh "$folder" "$dataset_name" "$TP"
        elif [ -n "$dataset_name" ]; then
            bash scripts/run_eval.sh "$folder" "$dataset_name"
        elif [ -n "$TP" ]; then
            bash scripts/run_eval.sh "$folder" "$TP"
        else
            bash scripts/run_eval.sh "$folder"
        fi
    fi
done


echo "Finished processing all folders in $directory_path"