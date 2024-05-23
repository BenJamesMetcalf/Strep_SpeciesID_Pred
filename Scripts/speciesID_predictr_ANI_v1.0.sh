#!/bin/bash -l

#This program takes in a species contig file, reference path list, and output directory and name and outputs the predicted species

krakn='false'
while getopts :i:r:o:n:s:k option
do
    case $option in
        i) input=$OPTARG;;
	r) aniREF=$OPTARG;;
        o) output=$OPTARG;;
	n) outName=$OPTARG;;
	s) smpl=$OPTARG;;
	k) krakn='true';;
    esac
done

if [[ -z "$input" ]]
then
    echo "No query species contig file supplied"
    exit 1
fi

if [[ -e "$aniREF" ]]
then
    echo "The FastANI reference list file is in the following location: $aniREF"
else
    echo "The FastANI reference list file given by the -r option is not in the correct format or doesn't exist."
    echo "Make sure you provide the full directory path (/root/path/file)."
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
    outName="RESULT_FastANI_"$date_now".txt"
fi

smplName="smpl_Unk"
if [[ -z "$smpl" ]]
then
    echo "The sample name is: $smplName"
else
    smplName="$smpl"
    echo "The sample name is: $smplName"
fi


##START DOING STUFF##
cd "$output"

#Run FastANI Test Run
~/tool_install_testing/test_FastANI/FastANI-master/fastANI -q $input --rl $aniREF -o TEMP_FastANI_query_vs_RefDB.txt

#Process FastANI Output
bstMatch=$(cat TEMP_FastANI_query_vs_RefDB.txt | awk -F"\t" '{print $3}' | sort -nr | head -n1)
echo "Best Match: $bstMatch"
if (( $(echo "$bstMatch >= 95.0" | bc -l) )); #95.0
then
    echo "FastANI found a match >= 95%"
    awk '$3 >= "94.5" {print $0}' TEMP_FastANI_query_vs_RefDB.txt > $outName
    if ${krakn}
	then
	echo "Run Kraken in addition to FastANI"
	#Create Kraken input file
	echo "$smplName,$input" > temp_kraken_path.txt
	bash /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/kraken_speciesID.sh -f ./temp_kraken_path.txt -o $outDir
	fi
elif (( $(echo "$bstMatch >= 80.0" | bc -l) )); #95.0
then
    echo "FastANI found a match >= 80%"
    awk '$3 >= "80.0" {print $0}' TEMP_FastANI_query_vs_RefDB.txt > $outName

    echo "Run 16S Extraction"
    module load BEDTools/2.27.1
    #/scicomp/home-pure/ycm6/tool_install_testing/barrnap/barrnap-0.9/bin/barrnap "$input" --outseq "$smplName"_rrna.fa
    /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/barrnap-0.9/bin/barrnap "$input" --outseq "$smplName"_rrna.fa
    module purge
    #module load ncbi-blast+/2.2.29
    #module load BEDTools/2.17.0
    #module load Python/2.7
    #module load prodigal/2.60
    #perl /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/LoTrac_target2.pl -c $input -q /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/strep_vulneris_16SrRNA.fna -o $outDir -n $smplName -L 0.50 -I 0.50 -S 2.0M -f
    #module purge

    echo "Run Kraken in addition to FastANI"
    #Create Kraken input file
    echo "$smplName,$input" > temp_kraken_path.txt
    bash /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/kraken_speciesID.sh -f ./temp_kraken_path.txt -o $outDir -n $smplName
else
    echo "FastANI did not find a match >= 80%. Will run Kraken for additional information"
    printf "$input\tNA\tKraken_Report\tNA\tNA\n" > $outName

    echo "Run 16S Extraction"
    module load BEDTools/2.27.1
    #/scicomp/home-pure/ycm6/tool_install_testing/barrnap/barrnap-0.9/bin/barrnap "$input" --outseq "$smplName"_rrna.fa
    /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/barrnap-0.9/bin/barrnap "$input" --outseq "$smplName"_rrna.fa
    module purge

    #module load ncbi-blast+/2.2.29
    #module load BEDTools/2.17.0
    #module load Python/2.7
    #module load prodigal/2.60
    #perl /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/LoTrac_target2.pl -c $input -q /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/strep_vulneris_16SrRNA.fna -o $outDir -n $smplName -L 0.50 -I 0.50 -S 2.0M -f
    #module purge

    #Create Kraken input file
    echo "$smplName,$input" > temp_kraken_path.txt
    bash /scicomp/home-pure/ycm6/PROJECTS_StrepLab/2023/Strep_SpeciesID_Pred_1-23-2023/scripts/kraken_speciesID.sh -f ./temp_kraken_path.txt -o $outDir -n $smplName
fi

rm TEMP_FastANI_query_vs_RefDB.txt
rm temp_kraken_path.txt
rm TEMP*
