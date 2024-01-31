#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J mrkdup

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/sort-and-markdup_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/sort-and-markdup_%j.err 
#SBATCH -p long 
#SBATCH -c 6
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
referenceGenome='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/methyl-dackel/reference-genome/GRCh38-reference_with-spike-in-sequences.fasta.gz'
output_format='methylKit'

# Reading in arguments
while getopts r:w:s:o:g:h opt
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
	f)
		output_format=$OPTARG
		;;
	h)
		echo "Usage:	methyl-dackel.sh [-i input_dir] [-o output_dir] [-s sample_list_path] [-g reference_genome_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing sorted BAM files for for methylation bias estimation [defaults to the working directory]"
		echo "-o		Path to output directory where to store methylation bias plots [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-g		Path to the reference genome file to be used (in FASTA format) [defaults to the human GRCh38 reference genome with added TAPS-specific spike-in sequences]"
		echo "-f		Type of output format required. This must be either 'bedGraph' or 'methylKit' [defaults to methylKit]"
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[methyl-dackel]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[methyl-dackel]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[methyl-dackel]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[methyl-dackel]:	ERROR: Sample list file not found"
        exit 2
fi

if [[ ! -f $reference_genome ]]
then
        echo "[methyl-dackel]:	ERROR: Reference genome file not found"
        exit 2
fi

if [[ $output_format != 'bedGraph' ]] && [[ $output_format != 'methylKit' ]]
then
	echo "[methyl-dackel]:	ERROR: Output type not recognised. This must be either 'bedGraph' or 'methylKit'."
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
echo "[methyl-dackel]:	Loading required modules..."
module load Anaconda3/2022.05

echo "[methyl-dackel]:	Loading virtual environment..."
eval "$(conda shell.bash hook)"
conda activate methylDackel

# Parsing input file
echo "[methyl-dackel]:	Reading sample list..."
readarray sampleList < $1

## Loading required modules and virtual environments
echo "[methyl-dackel]:	Loading required modules..."
module load Anaconda3/2022.05

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Running MethylDackel
echo "[methyl-dackel]:	Calling methylation events with MethylDackel ($sampleName)..."

if [[ $output_format == 'bedGraph' ]]
then
	echo "[methyl-dackel]:	Output set to 'bedGraph'..."
	MethylDackel extract \
		-q 10 \
		-p 10 \
		-t 4 \
		--mergeContext \
		-o "${output_dir}/${sampleName}" \
		--OT 5,135,5,115 \
		--OB 20,145,35,145 \
		$referenceGenome \
		"${input_dir}/${sampleName}.qced.sorted.markdup.bam"
fi

if [[ $output_format == 'methylKit' ]]
then
	echo "[methyl-dackel]:	Output set to 'methylKit'..."
	MethylDackel extract \
		-q 10 \
		-p 10 \
		-t 4 \
		--methylKit \
		-o "${output_dir}/${sampleName}" \
		--OT 5,135,5,115 \
		--OB 20,145,35,145 \
		$referenceGenome \
		"${input_dir}/${sampleName}.qced.sorted.markdup.bam"
fi

echo "[methyl-dackel]: 	...done!"
