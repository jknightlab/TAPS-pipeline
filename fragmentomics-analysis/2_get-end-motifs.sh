#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J end-motifs

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/get-end-motifs_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/get-end-motifs_%j.err 

#SBATCH -p short 
#SBATCH -c 4

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 


##########################################################################################
# General processing
## Reading in arguments
echo "===== Fragmentomics pipeline: Obtaining mapping coordinates for cfDNA fragments ====="
echo ""
echo "[end-motifs]:	Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[end-motifs]:	ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[end-motifs]:	ERROR: Output directory not found."
        exit 2
fi 

## Loading required modules and files
echo "[end-motifs]:	Reading sample list..."
readarray sampleList < $1
outDir=$2

# Defining path variables
twoBitReference='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/data/reference-genome/twoBit/GRCh38-reference_with-spike-in-sequences.2bit'

# Per-task processing 
## Defining input names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Fetching 5' end motifs
echo "[end-motifs]:	Fetching 5' fragment end motifs for top strand ($sampleName)..."
/well/jknight/users/awo868/software/ucsc/twoBitToFa \
	-bed="${sampleName}_fragment-coordinates.bed" \
	$twoBitReference \
	stdout | \
	awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' | \
	grep -v '^>' | \
	cut -c-4 \
	> "${outDir}/${sampleName}_5-prime-end-motifs_top-strand.tsv"
	
echo "[end-motifs]:	Fetching 5' fragment end motifs for bottom strand ($sampleName)..."
/well/jknight/users/awo868/software/ucsc/twoBitToFa \
	-bed="${sampleName}_fragment-coordinates.bed" \
	$twoBitReference \
	stdout | \
	awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' | \
	grep -v '^>' | \
	grep -o '....$' | \
	tr ACGTacgt TGCAtgca | \
	rev \
	> "${outDir}/${sampleName}_5-prime-end-motifs_bottom-strand.tsv"
	
echo "[end-motifs]:	...done!"
