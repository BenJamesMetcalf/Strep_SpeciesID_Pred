#!/bin/bash -l

#This program takes in a species contig file, reference path list, and output directory and name and outputs the predicted species

while getopts :i:o:n: option
do
    case $option in
        i) input=$OPTARG;;
        o) output=$OPTARG;;
        n) outName=$OPTARG;;
    esac
done

if [[ -z "$input" ]]
then
    echo "No query species contig file supplied"
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

if [[ ! -z "$outName" ]]
then
    echo "The output file name prefix: $outName"
else
    date_now=$(date "+%F_%s")
    outName="RESULT_FastANI-b_"$date_now".txt"
fi
echo "Sample,ANI_Match,ANI" >> "$outDir/$outName"

##START DOING STUFF##
while read line
do
    #echo "Line is: $line"
    sample=$(echo $line | cut -d, -f1)
    path=$(echo $line | cut -d, -f2)
    echo "Sample: $sample || Path: $path"
    bash speciesID_predictr_ANI_v1.0.sh -i "$path" -r /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/Strep_FastANI_RefDB_10-26-2023.txt -n ${sample}_output -o "$outDir" -s "$sample"    
    match=$(cat "$outDir/${sample}_output" | head -n1 | cut -d$'\t' -f2 | xargs -I{} basename {})
    ANI=$(cat "$outDir/${sample}_output" | head -n1 | cut -d$'\t' -f3)
    echo "$sample,$match,$ANI"
    echo "$sample,$match,$ANI" >> "$outDir/$outName"
done < "$input"

