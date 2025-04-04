#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J kraken2

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/kraken-2_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/kraken-2_%j.err 
#SBATCH -p short 
#SBATCH -c 10
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
kraken2_db='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/metagenomic-references/kraken2-db'

# Reading in arguments
while getopts i:o:s:d:h opt
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
	d)
		kraken2_db=$OPTARG
		;;
	h)
		echo "Usage:	run-kraken2-classification.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing FASTQ files to be used for read classification with kraken2 [defaults to the working directory]"
		echo "-o		Path to output directory where to write kraken2 reports and classified read files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-d		Path to a database of sequences in kraken2 format [defaults to a previously built kraken2 data base containing RefSeq sequences for archaea, bacteria, viruses, fungi, protozoans, known plasmids and vectors, and the human genome]"
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[run-kraken2]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[run-kraken2]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[run-kraken2]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[run-kraken2]:	ERROR: Sample list file not found"
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
echo "[run-kraken2]:	Loading modules..."
module load Kraken2/2.1.3-gompi-2023a

# Parsing input file
echo "[run-kraken2]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

# Extracting unmapped reads
echo "[run-kraken2]: Classifying sequences into taxonomies with kraken2 ($sampleName)..."
kraken2 \
	--paired \
	--use-names \
	--db $kraken2_db \
	--classified "${output_dir}/${sampleName}_classified-reads#.fastq.gz" \
	--report "${output_dir}/${sampleName}_kraken2-report.tsv" \
	--output "${output_dir}/${sampleName}_kraken2-output.tsv" \
	"${input_dir}/${sampleName}_unmapped-reads_1.fastq.gz" "${input_dir}/${sampleName}_unmapped-reads_2.fastq.gz"
	
echo "[run-kraken2]: ...done!"
