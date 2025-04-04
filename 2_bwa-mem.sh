#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J bwa-mem

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/bwa-mem_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/bwa-mem_%j.err 
#SBATCH -p long 
#SBATCH -c 8
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
reference_genome='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/reference-genome/bwa-mem/GRCh38-reference_with-spike-in-sequences.fasta.gz'

# Reading in arguments
while getopts i:o:s:g:h opt
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
	g)
		reference_genome=$OPTARG
		;;
	h)
		echo "Usage:	bwa-mem.sh [-i input_dir] [-o output_dir] [-s sample_list_path] [-g reference_genome_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing trimmed FASTQ files to be used for alignment [defaults to the working directory]"
		echo "-o		Path to output directory where to write bwa mem output [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-g		Path to the reference genome file that will be used for alignment (in FASTA format) [defaults to the human GRCh38 reference genome with added TAPS-specific spike-in sequences]"
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[bwa-mem]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
        echo "[bwa-mem]:	ERROR: Input directory not found."
        exit 2
fi 

if [[ ! -d $output_dir ]]
then
        echo "[bwa-mem]:	ERROR: Output directory not found."
        exit 2
fi 


if [[ ! -f $sample_list_path ]]
then
        echo "[bwa-mem]:	ERROR: Sample list file not found"
        exit 2
fi

if [[ ! -f $reference_genome ]]
then
        echo "[bwa-mem]:	ERROR: Reference genome (FASTA) file not found"
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

# Loading required module
echo "[bwa-mem]:	Loading modules..."
module load BWA/0.7.17-GCC-9.3.0
module load SAMtools/1.18-GCC-12.3.0
#module load samtools/1.8-gcc5.4.0

# Passing input file
echo "[bwa-mem]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

# Running BWA
echo "[bwa-mem]:	Aligning reads with bwa mem for sample $sampleName..."
bwa mem \
	-I 500,120,1000,20 \
	$reference_genome \
	"${input_dir}/${sampleName}_1_val_1.fq.gz" \
	"${input_dir}/${sampleName}_2_val_2.fq.gz" | \
	samtools view -b -h > "${output_dir}/${sampleName}.bam"

echo "[bwa-mem]: ...done!"

