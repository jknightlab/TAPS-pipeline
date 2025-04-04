#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J collect-abundances

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/collect-abundances_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/collect-abundances_%j.err 
#SBATCH -p short 
#SBATCH -c 1
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD

# Reading in arguments
while getopts i:o:s:h opt
do
	case $opt in
	i)
		input_dir=$OPTARG
		;;
	o)
		output_dir=$OPTARG
		;;
	s)
		sample_list_path=$OPTARG
		;;
	h)
		echo "Usage:	collect-genus-level-abundances.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing kraken2 report files [defaults to the working directory]"
		echo "-o		Path to output directory where to write the final, combined kraken2 report with genus level abundance estimates [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[collect-abundances]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[collect-abundances]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[collect-abundances]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[collect-abundances]:	ERROR: Sample list file not found"
        exit 2
fi

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 


# Parsing input file
echo "[collect-abundances]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Collecting genus-level abundances
echo "[collect-abundances]: Collecting genus-level abundances from kraken report files..."
for sampleName in ${sampleList[@]};
do
    cat "${input_dir}/${sampleName}_kraken2-report.tsv" | \
    	awk '$2 >= 10 && $4 == "G"' | \
    	sort -k 2 -n -r | \
    	sed 's/ //g' | \
    	awk -v sampleName=$sampleName '{print sampleName"\t"$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}' \
    	>> "${output_dir}/kraken2-genus-level-abundances.tsv"
done
	
echo "[collect-abundances]: ...done!"
