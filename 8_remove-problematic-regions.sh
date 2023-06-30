#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/remove-problematic-regions_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/remove_problematic-regions_%j.err 

#SBATCH -p long 
#SBATCH -c 2

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
echo "===== TAPS pipeline: Removing blacklisted and problematic regions from methylKit files ====="
echo ""
echo "[remove-problematic-regions]:       Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[remove-problematic-regions]:        ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[remove-problematic-regions]:        ERROR: Output directory not found."
        exit 2
fi 

echo "[remove-problematic-regions]:        Reading sample list..."
readarray sampleList < $1
outDir=$2

# Per-task processing 
## Defining input and output names
referenceGenomeDir='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/methyl-dackel/reference-genome/'

sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[remove-problematic-regions]:       Processing sample $sampleName..."	

if [[ ! -d "${outDir}tmp" ]]
then
        mkdir "${outDir}/tmp"
fi

echo "[remove-problematic-regions]:       Removing centromeres, blacklisted regions, gaps, and common SNPs..."	
cat "${sampleName}_CpG.methylKit" | \
	awk '{print $2"\t"$3"\t"$3+1"\t"$4"\t"$5"\t"$6"\t"$7"\t"$1}' | \
	tail -n +2 | \
	/well/jknight/users/awo868/software/bedtools subtract -a stdin -b "${referenceGenomeDir}/blacklisted-regions/centromeres_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -a stdin -b "${referenceGenomeDir}/blacklisted-regions/blacklisted-regions_encode_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -a stdin -b "${referenceGenomeDir}/blacklisted-regions/gaps_grch38.bed" | \
	/well/jknight/users/awo868/software/bedtools subtract -a stdin -b "${referenceGenomeDir}/blacklisted-regions/common-snps_dbsnp-v151_grch38.bed" \
	> "${outDir}/tmp/${sampleName}_CpG.qced.methylKit"

echo "[remove-problematic-regions]:       Flipping methylation calls to map TAPS chemistry..."	
cat "${outDir}/tmp/${sampleName}_CpG.qced.methylKit" | \
	awk '{print $8"\t"$1"\t"$2"\t"$4"\t"$5"\t"$7"\t"$6}' > "${outDir}/${sampleName}_CpG.qced.flipped.methylKit"
	
echo "[remove-problematic-regions]:       Cleaning up..."	
rm "${outDir}/tmp/${sampleName}_CpG.qced.methylKit"

echo "[remove-problematic-regions]:       ...done!"
