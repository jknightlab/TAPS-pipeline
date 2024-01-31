#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J region-filter

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/filter-regions-and-flip-calls_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/filter-regions-and-flip-calls_%j.err 
#SBATCH -p short 
#SBATCH -c 2
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
regions_directory='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/methyl-dackel/reference-genome/blacklisted-regions'

# Reading in arguments
while getopts i:o:s:r:h opt
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
	r)
		regions_directory=$OPTARG
		;;
	h)
		echo "Usage:	filter-and-flip-methylation-calls.sh [-i input_dir] [-o output_dir] [-s sample_list_path] [-r regions_directory]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing mehtylation call files in the methylKit format [defaults to the working directory]"
		echo "-o		Path to output directory where to write filtered methylKit files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-r		Path to the a directory with region lists to be substracted from the file [defaults to a directory contailists of known GRCh38 problematic regions]"
		echo ""
		exit 1
		;;
	esac
done

## Validating arguments
echo "[remove-problematic-regions]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[[remove-problematic-regions]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[remove-problematic-regions]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[remove-problematic-regions]:	ERROR: Sample list file not found"
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
echo "[remove-problematic-regions]:	Reading sample list..."
readarray sampleList < $sample_list_path

## Creating output directories
echo "[mapping-stats]:	Setting up output directory structure..."
if [[ ! -d "${output_dir}/tmp" ]]
then
        mkdir "${output_dir}/tmp"
fi

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[remove-problematic-regions]:       Processing sample $sampleName..."	

echo "[remove-problematic-regions]:       Removing centromeres, blacklisted regions, gaps, and common SNPs..."	
cat "${input_dir}/${sampleName}_CpG.methylKit" | \
	awk '{print $2"\t"$3"\t"$3+1"\t"$4"\t"$5"\t"$6"\t"$7"\t"$1}' | \
	tail -n +2 | \
	/well/jknight/users/awo868/software/bedtools subtract -A -a stdin -b "${regions_directory}/centromeres_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -A -a stdin -b "${regions_directory}/blacklisted-regions_encode_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -A -a stdin -b "${regions_directory}/gaps_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -A -a stdin -b "${regions_directory}/common-snps_dbsnp-v155_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -A -a stdin -b "${regions_directory}/repeat-masker_grch38.bed" \
	> "${output_dir}/tmp/${sampleName}_CpG.qced.methylKit"

echo "[remove-problematic-regions]:       Flipping methylation calls to map TAPS chemistry..."	
cat "${output_dir}/tmp/${sampleName}_CpG.qced.methylKit" | \
	awk '{print $8"\t"$1"\t"$2"\t"$4"\t"$5"\t"$7"\t"$6}' > \
	"${output_dir}/tmp/${sampleName}_CpG.qced.flipped.methylKit"
	
echo "[remove-problematic-regions]:       Adding file header..."
echo -e "chrBase\tchr\tbase\tstrand\tcoverage\tfreqC\tfreqT" | \
	cat - "${output_dir}/tmp/${sampleName}_CpG.qced.flipped.methylKit" \
	> "${output_dir}/${sampleName}_CpG.qced.flipped.methylKit"

echo "[remove-problematic-regions]:       Cleaning up..."	
rm "${output_dir}/tmp/${sampleName}_CpG.qced.methylKit"
rm "${output_dir}/tmp/${sampleName}_CpG.qced.flipped.methylKit"

echo "[remove-problematic-regions]:       ...done!"
