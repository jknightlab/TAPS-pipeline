#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J WPS

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/calculate-WPS_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/calculate-WPS_%j.err 

#SBATCH -p short
#SBATCH -c 3
##############################################################################

## Reading in arguments
echo "===== Calculating windowed protection scores (WPS) for a set of genomic regions ====="
echo ""

# Setting default parameter values
min_frag_size=120
max_frag_size=200
region_file='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/reference-genome/sliding-windows/sliding-windows-around-TSSs_k-120.bed.gz'
input_dir=$PWD
output_dir=$PWD

# Reading in arguments
while getopts m:M:r:i:o:s:h opt 
do
	case $opt in
	m)
		min_frag_size="$OPTARG"
		;;
	M)
		max_frag_size="$OPTARG"
		;;
	r)
		region_file="$OPTARG"
		;;
	i)
		input_dir="$OPTARG"
		;;	
	o)
		output_dir="$OPTARG"
		;;
	s)
		sample_list_path="$OPTARG"
		;;
	h)
		echo "Usage:	calculate-WPS.sh [-m min_frag_size] [-M max_frag_size] [-r region_file] [-o output_dir] [-s sample_list]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing end-motif files (as outputted from code 3 in the fragmentomics-analysis section of this repository) [defaults to the working directory]"
		echo "-o		Path to output directory where to write final BED files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-m		Minimum fragment length. Fragments shorter than this value will be discarded from analysis [defaults to 120 bp (i.e. mononucleosomes)]"
		echo "-M		Maximum fragment length. Fragments longer than this value will be discarded from analysis [defaults to 200 bp (i.e. mononucleosomes)]"
		echo "-r		Path to a region file, containing a list of genomic regions for which to calcualte windowed protection scores (WPS) [defaults to a region file derived using code 1 in this repository]"
		echo ""
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

# Outputing relevant information on how the job was run
echo "------------------------------------------------"
echo "Run on host: "`hostname`
echo "Operating system: "`uname -s`
echo "Username: "`whoami`
echo "Started at: "`date`    
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 

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
zcat "${input_dir}/${sampleName}_cfDNA-end-motifs_GRCh38.tsv.gz" | \
	awk -F '\t' '$4 > '$min_frag_size' && $4 < '$max_frag_size' {print}' | \
	awk '{print $1"\t"$2"\t"$3}' | \
	gzip \
	> "${output_dir}/tmp/${sampleName}_selected-fragments.bed.gz"

# Finding reads overlapping each sliding window
## All overlaps
echo "[calculate-WPS]:	Quantifying all overlaps with the regions of interest..."
/well/jknight/users/awo868/software/bedtools intersect \
	-a "${region_file}" \
	-b "${output_dir}/tmp/${sampleName}_selected-fragments.bed.gz" \
	-c \
	> "${output_dir}/tmp/${sampleName}_all-overlaps.bed"

## Complete overlaps only
echo "[calculate-WPS]:	Quantifying any complete overlaps with the regions of interest..."
/well/jknight/users/awo868/software/bedtools intersect \
	-a "${region_file}" \
	-b "${output_dir}/tmp/${sampleName}_selected-fragments.bed.gz" \
	-f 1 \
	-c \
	> "${output_dir}/tmp/${sampleName}_complete-overlaps.bed"

# Calculating windowed protection score (WPS) per window
## Counting partial and full overlaps
echo "[calculate-WPS]:	Computing WPS per region..."
paste "${output_dir}/tmp/${sampleName}_all-overlaps.bed" \
	"${output_dir}/tmp/${sampleName}_complete-overlaps.bed" | \
	awk '{print $1"\t"$2"\t"$3"\t"$8"\t"$4-$8}' | \
	gzip \
	> "${output_dir}/tmp/${sampleName}_overlap-counts.bed"

## Calculating WPS
zcat "${output_dir}/tmp/${sampleName}_overlap-counts.bed" | \
	awk '{print $1"\t"($2+$3)/2"\t"$4-$5}' | \
	gzip \
	> "${output_dir}/${sampleName}_WPS.bed.gz"

# Cleaning up
echo "[calculate-WPS]:	Cleaning up..."
find  "${output_dir}/tmp/" -name "${sampleName}*" -exec rm {} \;

echo "[calculate-WPS]:	...done!"

