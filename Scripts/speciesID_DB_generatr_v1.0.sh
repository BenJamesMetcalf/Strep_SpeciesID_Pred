#!/bin/bash -l

#This program takes a species linelist file containing assemblies and copies and renames them for the species DB
while getopts :i:o: option
do
    case $option in
        i) input=$OPTARG;;
        o) output=$OPTARG;;
    esac
done

if [[ -z "$input" ]]
then
    echo "No Species linelist file supplied"
    exit 1
fi

outDir="./"
if [[ -z "$output" ]]
then
    echo "The files will be saved to current directory"
elif [[ ! -d "$output" ]]
then
    outDir="$output"
    mkdir "$outDir"
    echo "The files will be saved to the following directory: $outDir"
else
    outDir="$output"
    echo "The files will be saved to the following directory: $outDir"
fi

cd "$output"
while read line
do
    #echo "Line is: $line"
    labid=$(echo $line | cut -d',' -f1 | sed -e 's/^[ \t]*//' -e 's/\ *$//g')
    species=$(echo $line | cut -d',' -f3 | sed -e 's/^[ \t]*//' -e 's/\ *$//g')
    cPath=$(echo $line | cut -d',' -f5 | sed -e 's/^[ \t]*//' -e 's/\ *$//g')
    aName=$(basename $cPath | sed -e 's/^[ \t]*//' -e 's/\ *$//g')
    newName="${labid}_${species}.fna"
    echo "Name is: $newName"
    cp "$cPath" "$output"
    mv "$aName" "$newName"
done < "$input"
