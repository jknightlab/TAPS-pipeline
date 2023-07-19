#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J check-identity-2

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-2_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-2_%j.err 

#SBATCH -p short 
#SBATCH -c 4

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "------------------------------------------------" 


##########################################################################################


# Reading in arguments
echo "===== TAPS pipeline: Checking sample identity with Picard (2) ====="
echo ""
echo "[check-identity]:		Validating arguments..."
if [[ ! -d $1 ]]
then
        echo "[check-identity]:		ERROR: Output directory not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[check-identity]:		ERROR: Output directory not found."
        exit 2
fi 

echo "[check-identity]:		Reading sample list..."
inputDir=$1
outputDir=$2

# Loading required modules
echo "[check-identity]:	Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11
module load samtools/1.8-gcc5.4.0

# Creating output directories
if [[ ! -d "${outputDir}/tmp" ]]
then
        mkdir "${outputDir}/tmp"
fi

# Defining paths
fingerprintMap='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/bwa-mem/reference-genome/hg38_chr.map'

# Merging BAM files
echo "[check-identity]:		Merging BAM files..."	
samtools merge -@ 12 ${outputDir}/tmp/merged_RG.bam ${inputDir}/*.qced.sorted.markdup.RG.bam 

echo "[check-identity]:		Cross-checking fingerprints..."	
java -jar $EBROOTPICARD/picard.jar CrosscheckFingerprints \
	INPUT="${outputDir}/tmp/merged_RG.bam" \
	HAPLOTYPE_MAP="$fingerprintMap" \
	NUM_THREADS=4 \
	OUTPUT="${outputDir}/crosscheck-metrics.txt" \
	MATRIX_OUTPUT="${outputDir}/crosscheck_LOD-matrix.txt"

if [[ -f "${outputDir}/crosscheck-metrics.txt" ]]
then
	echo "[check-identity]:		Cleaning up..."
	rm ${inputDir}/*.qced.sorted.markdup.RG.bam
	rm ${outputDir}/tmp/merged_RG.bam
	
	echo "[check-identity]:		...done!"	
fi
