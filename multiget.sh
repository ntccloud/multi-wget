#!/bin/bash
#############################################################
# Script to download multiple files concurrently using WGET #
#     (c) 2017 Scott Johnson, Emerald City IT Services      #
#              Licensed under the MIT License               #
#############################################################

pidArrray=();
failure=0;
function validateURL() {
    #takes URL and returns true or false if URL exists or not.
    if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
        return 1;
    else
        return 0;
    fi
}

function startDownload() {
    #Before starting download, we verify that the file exists
    echo $1
    validateURL $1
    if [[ $? -eq 0 ]]; then
        return 0;
    else
        #File exists so start WGET and background process while saving the PID
        if [[ -n $prefix ]]; then
            wget="$( wget -P $prefix -bx $1 )";
        else
            wget="$( wget -bx $1 )";
        fi
        pid="$( echo "${wget}" | awk '/ pid / { print 0 + $(NF); }' )";
        pidArray+=($pid);
        echo $pid
        return 1;
    fi
}

function waitForBatch() {
    pidLength=${#pidArray[@]};
    echo "Batch Start"
    while [ $pidLength -ne 0 ]; do
        echo Remaining: "$pidLength"\n
        for ((i=0;i<$pidLength;i++))
        do
            if ! ps -p "${pidArray[$i]}" > /dev/null; then
                unset pidArray[$i];
            fi
        done
        pidArray=( "${pidArray[@]}" );
        pidLength=${#pidArray[@]};
        sleep 1
    done
    echo "Batch Complete"
}

function processURLArray() {
    array=("${!1}");
    arraylen=${#array[@]};
    while [ $arraylen -ne 0 ]; do
        if [[ $arraylen -ge 10 ]]; then
            for i in {0..9}
            do
                startDownload ${array[$i]};
                if [[ $? -eq 0 ]]; then
                    failure=1;
                    array=();
                    break;
                fi
                unset array[$i];
            done
            if [[ $failure -eq 0 ]]; then
                waitForBatch;
            fi
        else
            for ((i=0;i<$arraylen;i++))
            do
                startDownload ${array[$i]};
                if [[ $? -eq 0 ]]; then
                    failure=1;
                    array=();
                    break;
                fi
                unset array[$i];
            done
            if [[ $failure -eq 0 ]]; then
                waitForBatch;
            fi
        fi;
        array=( "${array[@]}" );
        arraylen=${#array[@]};
    done
}