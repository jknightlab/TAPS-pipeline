#!/usr/bin/bash

## Author:      Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission

#SBATCH -A jknight.prj 
#SBATCH -J reformat-end-motifs

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/format-end-motifs.%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/format-end-motifs.%j.err 

#SBATCH -p short 
#SBATCH -c 1
##########################################################################################

# Set default parameter values
frag_coord_dir=$PWD
end_motif_dir=$PWD
output_dir=$PWD

# Read in arguments
while getopts s:f:e:o:h opt
do
	case $opt in
	s)
		sample_list_file=$OPTARG
		;;
	f)
		frag_coord_dir=$OPTARG
		;;
	e)
		end_motif_dir=$OPTARG
		;;
	o)
		output_dir=$OPTARG
		;;
	h)
		echo "Usage:	reformat-end-motif-data.sh [-s sample_list_file] [-f frag_coord_dir] [-e end_motif_dir] [-o output_dir]"
		echo ""
		echo "Where:"
		echo "-s		Text file containing a list of sample names (one per line) to be aligned. These names should match the naming convention of end-motif and fagment coordinate files"
		echo "-f		Input directory where BED files containing cfDNA fragment mapping coordinates are located [defaults to the working directory]"
		echo "-e		Input directory where TSV files containing end motif sequences for each cfDNA fragemnt and strand are located [defaults to the working directory]"
		echo "-o		Directory where output report files will be written [defaults to the working directory]"
		echo ""
		exit 1
		;;
	esac
done

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 

# Validate arguments
echo "[format-end-motifs]:       Validating arguments..."
if [[ ! -f $sample_list_file ]]
then
        echo "[format-end-motifs]:       ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $frag_coord_dir ]]
then
        echo "[format-end-motifs]:       ERROR: Fragment coordinate (BED file) directory not found."
        exit 2
fi 

if [[ ! -d $end_motif_dir ]]
then
        echo "[format-end-motifs]:       ERROR: End-motif (TSV file) directory not found."
        exit 2
fi 

if [[ ! -d $output_dir ]]
then
        echo "[format-end-motifs]:       ERROR: Output directory not found."
        exit 2
fi 

# Defining sample of interest from sample list
echo "[format-end-motifs]:	Reading in sample list..."
readarray sample_list < $sample_list_file
sample_name=$(echo ${sample_list[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[format-end-motifs]:       Processing sample $sample_name..."	

if [[ ! -d "${output_dir}/tmp" ]]
then
        mkdir "${output_dir}/tmp"
fi

echo "[format-end-motifs]:       Collating fragment coordinate and end-motif information in a single output file..."	
paste "${frag_coord_dir}/${sample_name}_fragment-coordinates.bed" \
	"${end_motif_dir}/${sample_name}_5-prime-end-motifs_top-strand.tsv" \
	"${end_motif_dir}/${sample_name}_5-prime-end-motifs_bottom-strand.tsv" | \
	awk '{print $1"\t"$2"\t"$3"\t"$3-$2"\t"$4"\t"$5"\t"$6}' \
	> "${output_dir}/tmp/${sample_name}_cfDNA-end-motifs_GRCh38.tsv"  

echo "[format-end-motifs]:       Adding file header..."
echo -e "chr\tstart\tend\tlength\tfragment_id\tend_motif_top_strand\tend_motif_bottom_strand" | \
	cat - "${output_dir}/tmp/${sample_name}_cfDNA-end-motifs_GRCh38.tsv" | \
	gzip > "${output_dir}/${sample_name}_cfDNA-end-motifs_GRCh38.tsv.gz"

echo "[format-end-motifs]:       Cleaning up..."	
rm "${output_dir}/tmp/${sample_name}_cfDNA-end-motifs_GRCh38.tsv"

echo "[format-end-motifs]:       ...done!"

