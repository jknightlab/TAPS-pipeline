#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J mbias

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/mbias_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/mbias_%j.err 
#SBATCH -p long 
#SBATCH -c 6
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
reference_genome='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/reference-genome/methyldackel/GRCh38-reference_with-spike-in-sequences.fasta.gz'

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
		echo "Usage:	mbias-plot.sh [-i input_dir] [-o output_dir] [-s sample_list_path] [-g reference_genome_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing sorted BAM files for for methylation bias estimation [defaults to the working directory]"
		echo "-o		Path to output directory where to store methylation bias plots [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-g		Path to the reference genome file to be used (in FASTA format) [defaults to the human GRCh38 reference genome with added TAPS-specific spike-in sequences]"
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[mbias-plot]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[mbias-plot]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[mbias-plot]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[mbias-plot]:	ERROR: Sample list file not found"
        exit 2
fi

if [[ ! -f $reference_genome ]]
then
        echo "[mbias-plot]:	ERROR: Reference genome file not found"
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
echo "[mbias-plot]:	Loading required modules..."
module load Anaconda3/2022.05

echo "[mbias-plot]:	Loading virtual environment..."
eval "$(conda shell.bash hook)"
conda activate methylDackel

# Parsing input file
echo "[mbias-plot]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

# Running MethylDackel's methylation bias estimation function
echo "[mbias-plot]:	Checking for methylation bias with MethylDackel ($sampleName)..."
MethylDackel mbias \
	$reference_genome \
	"${input_dir}/${sampleName}.qced.sorted.markdup.bam" \
	"${output_dir}/${sampleName}"

echo "[mbias-plot]: ...done!"
