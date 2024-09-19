#!/bin/bash

# obtain the last 3 level dir names by default
LAYERS=3

# check the parameters if provided.
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path> [number_of_layers]"
    exit 1
fi

# obtain the input path
PATH_INPUT="$1"

# if the second parameter is provided, use it as the number of layers
if [ $# -eq 2 ] && [[ "$2" =~ ^[0-9]+$ ]]; then
    LAYERS=$2
fi

# obtain the last n level dirs by awk
result=$(echo "$PATH_INPUT" | awk -F'/' '{
    path = "";
    for (i = NF - '"$LAYERS"' + 1; i <= NF; i++) {
        if (i > NF - '"$LAYERS"' + 1) path = path "/";
        path = path $i;
    }
    print path;
}')

# print
echo "$result"