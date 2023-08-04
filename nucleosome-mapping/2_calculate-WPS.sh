#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J make-pats

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/calculate-WPS_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/calculate-WPS_%j.err 

#SBATCH -p long
#SBATCH -c 6

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 

## Reading in arguments
echo "===== Calculating windowed protection scores (WPS) for a set of genomic regions ====="
echo ""

# Setting default parameter values
min_frag_size=120
max_frag_size=200
region_file='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/data/reference-genome/sliding-windows/sliding-windows-around-TSSs_k-120.bed'
input_dir=$PWD
output_dir=$PWD

# Reading in arguments
while getopts ":m:M:r:i:o:s:" option; 
do
	case $option in
	m | --min_frag_size)
		min_frag_size="$OPTARG"
		;;
	M | --max_frag_size)
		max_frag_size="$OPTARG"
		;;
	r | --region_file)
		region_file="$OPTARG"
		;;
	i | --input_dir)
		input_dir="$OPTARG"
		;;	
	o | --output_dir)
		output_dir="$OPTARG"
		;;
	s | --sample_list)
		sample_list_path="$OPTARG"
		;;
	*)
		echo "Usage: $0 [-m min_frag_size] [-M max_frag_size] [-r region_file] [-o output_dir] [-s sample_list]"
		exit 1
		;;
	esac
done

echo "[calculate-WPS]:	Validating arguments..."
if [[ ! -f $region_file ]]
then
        echo "[calculate-WPS]:	ERROR: Region file not found."
        exit 2
fi

if [[ ! -f $sample_list_path ]]
then
        echo "[calculate-WPS]:	ERROR: List of samples not found."
        exit 2
fi

if [[ ! -d $output_dir ]]
then
        echo "[calculate-WPS]:	ERROR: Output directory not found."
        exit 2
fi 

echo "[calculate-WPS]:	Reading sample list..."
readarray sampleList < $sample_list_path

echo "[calculate-WPS]:	Parameter values will be as follows:"
echo "[calculate-WPS]:		- Minimum fragment size: $min_frag_size bp"
echo "[calculate-WPS]:		- Maximum fragment size: $max_frag_size bp"
echo "[calculate-WPS]:		- Region file: $region_file"
echo "[calculate-WPS]:		- Input directory: $input_dir"
echo "[calculate-WPS]:		- Output directory: $output_dir"

# Setting up tmp directory
if [[ ! -d "${output_dir}/tmp" ]]
then
        mkdir "${output_dir}/tmp"
fi 

# Calcualting WPS scores
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[calculate-WPS]:	Processing sample ${sampleName}..."

## Filtering fragments by size
echo "[calculate-WPS]:	Filtering fragments by length..."
cat "${input_dir}/${sampleName}_cfDNA-end-motifs_GRCh38.tsv frag-coords.bed" | \
	awk -F '\t' '$4 > $min_frag_size && $4 < $max_frag_size {print}' | \
	awk '{print $1"\t"$2"\t"$3}' \
	> "${output_dir}/tmp/${sampleName}_selected-fragments.bed"

# Finding reads overlapping each sliding window
## All overlaps
echo "[calculate-WPS]:	Quantifying all overlaps with the regions of interest..."
/well/jknight/users/awo868/software/bedtools intersect \
	-a $slidingWindows \
	-b "${output_dir}/tmp/${sampleName}_selected-fragments.bed" \
	-c \
	> "${output_dir}/tmp/${sampleName}_all-overlaps.bed"

## Complete overlaps only
echo "[calculate-WPS]:	Quantifying any complete overlaps with the regions of interest..."
/well/jknight/users/awo868/software/bedtools intersect \
	-a $slidingWindows \
	-b "${output_dir}/tmp/${sampleName}_selected-fragments.bed" \
	-f 1 \
	-c \
	> "${output_dir}/tmp/${sampleName}_complete-overlaps.bed"

# Calculating windowed protection score (WPS) per window
## Counting partial and full overlaps
echo "[calculate-WPS]:	Computing WPS per region..."
paste "${output_dir}/tmp/${sampleName}_all-overlaps.bed" \
	"${output_dir}/tmp/${sampleName}_complete-overlaps.bed" | \
	awk '{print $1"\t"$2"\t"$3"\t"$8"\t"$4-$8}' \
	> "${output_dir}/tmp/${sampleName}_overlap-counts.bed"

## Calculating WPS
cat "${output_dir}/tmp/${sampleName}_overlap-counts.bed" | \
	awk '{print $1"\t"($2+$3)/2"\t"$4-$5}' \
	> "${output_dir}/${sampleName}_WPS.bed"

# Cleaning up
echo "[calculate-WPS]:	Cleaning up..."
rm "${output_dir}/tmp/${sampleName}_.*$"

echo "[calculate-WPS]:	...done!"

