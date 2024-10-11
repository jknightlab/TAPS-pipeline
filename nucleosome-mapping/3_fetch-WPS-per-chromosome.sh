#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J fetch-WPS

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/fetch-WPS-per-chr.%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/fetch-WPS-per-chr.%j.err 

#SBATCH -p short 
#SBATCH -c 8

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 

# Setting default parameter values
region_size=5000
output_dir=$PWD

# Reading in arguments
while getopts i:r:w:s:o:g:h opt
do
	case $opt in
	i)
		input_file=$OPTARG
		;;
	r)
		region_size=$OPTARG
		;;
	o)
		output_dir=$OPTARG
		;;
	h)
		echo "Usage:	fetch-WPS-per-chromosome.sh [-i input_file] [-r region_size] [-o output_dir]"
		exit 1
		;;
	esac
done

echo "===== Fetching WPS values around each gene's TSS ====="
echo ""

echo "[fetch-WPS]:	Validating arguments..."
if [[ ! -f $input_file ]]
then
        echo "[fetch-WPS]:	ERROR: Input file not found."
        exit 2
fi 

if [[ ! -d $output_dir ]]
then
        echo "[fetch-WPS]:	ERROR: Output directory not found."
        exit 2
fi 

echo "[fetch-WPS]:	Parameter values will be as follows:"
echo "[fetch-WPS]:		- Region size: $(($region_size/1000)) kb"
echo "[fetch-WPS]:		- Output directory: $output_dir"

# Loading required modules
echo "[fetch-WPS]:	Loading required modules..."
module load R/4.3.2-gfbf-2023a R-bundle-Bioconductor/3.18-foss-2023a-R-4.3.2

#  Running analysis in parallel for each chromosome
pathToScript='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/analysis/TAPS-pipeline/nucleosome-mapping/fetch-WPS-per-gene.R'
fileName=""

echo "[calculate-WPS]:	Parallelising by chromosome..."
chromosomes=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")
chr=${chromosomes[$((${SLURM_ARRAY_TASK_ID}-1))]}

echo "[calculate-WPS]:	Running analysis for ${chr}..."
Rscript $pathToScript \
	-f $input_file \
	-c $chr \
	-r $region_size \
	-o $output_dir
	
echo "[calculate-WPS]:	...done!"

