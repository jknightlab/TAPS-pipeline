#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J check-identity-2

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-2_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-2_%j.err 
#SBATCH -p short 
#SBATCH -c 4
##########################################################################################



# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
fingerprint_map='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/bwa-mem/reference-genome/hg38_chr.map'

# Reading in arguments
while getopts i:o:f:h opt
do
	case $opt in
	i)
		input_dir=$OPTARG
		;;
	o)
		output_dir=$OPTARG
		;;
	f)
		fingerprint_map=$OPTARG
		;;
	h)
		echo "Usage:	add-read-groups.sh [-i input_dir] [-o output_dir] [-s sample_list_path] [-f fingerprint_map]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing BAM files, previously read grouped [defaults to the working directory]"
		echo "-o		Path to output directory where to write final LOD matrix [defaults to the working directory]"
		echo "-f		Path to fingerprint map file for the reference genome used [defaults to a map file for GRCh38]"
		echo ""
		exit 1
		;;
	esac
done

## Validating arguments
echo "[check-identity]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[check-identity]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[check-identity]:	ERROR: Output directory not found."
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

# Loading required modules
echo "[check-identity]:	Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11
module load samtools/1.8-gcc5.4.0

# Creating output directories
if [[ ! -d "${output_dir}/tmp" ]]
then
        mkdir "${output_dir}/tmp"
fi

# Defining paths

# Merging BAM files
echo "[check-identity]:		Merging BAM files..."	
samtools merge -@ 12 "${output_dir}/tmp/merged_RG.bam" "${input_dir}/*.qced.sorted.markdup.RG.bam"

echo "[check-identity]:		Cross-checking fingerprints..."	
java -jar $EBROOTPICARD/picard.jar CrosscheckFingerprints \
	INPUT="${output_dir}/tmp/merged_RG.bam" \
	HAPLOTYPE_MAP="$fingerprint_map" \
	NUM_THREADS=4 \
	OUTPUT="${output_dir}/crosscheck-metrics.txt" \
	MATRIX_OUTPUT="${output_dir}/crosscheck_LOD-matrix.txt"

if [[ -f "${output_dir}/crosscheck-metrics.txt" ]]
then
	echo "[check-identity]:		Cleaning up..."
	rm "${input_dir}/*.qced.sorted.markdup.RG.bam"
	rm "${output_dir}/tmp/merged_RG.bam"
	
	echo "[check-identity]:		...done!"	
fi
