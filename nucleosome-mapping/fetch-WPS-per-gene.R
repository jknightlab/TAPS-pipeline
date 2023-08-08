#!/usr/bin/env Rscript

cat("\n\n====	Fetching WPS scores at genomic windows centred at genes' TSS	====\n")
cat("Author:	Eddie Cano-Gamez <ecg@well.ox.ac.uk>\n\n")

# Parsing arguments
option_list <- list(
  optparse::make_option(c("-f", "--file_name"), type="character", default=NULL, help="Input file name", metavar="character"),
  optparse::make_option(c("-c", "--chr"), type="character", default="chr22", help="Chromosome of interest (e.g. chr1) [default = 'chr22']", metavar="character"),
  optparse::make_option(c("-r", "--region_size"), type="numeric", default=5000, help="Region size around TSS (bp) [default = 5000 bp]", metavar="numeric"),
  optparse::make_option(c("-o", "--output_dir"), type="character", default="./", help="Output directory [defaults to working directory]", metavar="numeric")
)
 
opt_parser <- optparse::OptionParser(option_list=option_list)
opt <- optparse::parse_args(opt_parser)

# Fetching argument values
cat("[fetch-WPS-per-gene.R]:	Parsing argument values...\n")
file_name <- opt$file_name
chromosome <- opt$chr
region_size <- opt$region_size
output_dir <- opt$output_dir

cat("[fetch-WPS-per-gene.R]:	Analysis parameters will be as follows:\n")
cat("	- Input file:",file_name,"\n")
cat("	- Chromosome:",chromosome,"\n")
cat("	- Window size:",region_size,"bp\n")
cat("	- Output directory:",output_dir,"\n\n")

# Loading libraries
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(genomation))
suppressPackageStartupMessages(library(annotables))
suppressPackageStartupMessages(library(reshape2))

# Loading input data
cat("[fetch-WPS-per-gene.R]:	Reading input file...\n")
WPS <- read_tsv(
	file = file_name,
	col_names = c("chr","pos","WPS")
)

cat("[fetch-WPS-per-gene.R]:	Retrieving gene annotations...\n")
TSS_anns <- fread(
	file="/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/data/functional-annotations/gencode-v43_grch38.bed",
	sep = "\t", 
	select = c(4,1,2,6),
	col.names = c("transcript_id","chr","tss","strand")
)

# Subsetting to chromosome of interest
cat("[fetch-WPS-per-gene.R]:	Subsetting to protein-coding genes in", chromosome, "only...\n")
WPS <- WPS %>%
	filter(chr == chromosome)

TSS_anns <- TSS_anns %>%
	filter(chr == chromosome) %>% 
	filter(!duplicated(transcript_id)) %>%
	transmute(
		chr,
		tss,
		strand,
		enstxp = gsub("\\..$","",transcript_id)
	) %>%
	left_join(grch38_tx2gene, by="enstxp") %>%
	left_join(grch38[,c("ensgene","symbol","biotype")], by="ensgene") %>%
	filter(biotype == "protein_coding") %>%
	transmute(
		chr,
		tss,
		strand,
		transcript_id = enstxp,
		gene_id = ensgene,
		gene_name = symbol
	) %>%
	filter(!duplicated(gene_name)) %>%
	filter(!is.na(gene_name))

# Extracting WPS values
cat("[fetch-WPS-per-gene.R]:	Obtaining WPS values in the TSS region of each gene and adjusting to a running mean of zero...\n")

gene_list <- TSS_anns %>% 
 	filter(!duplicated(gene_name))

WPS_per_gene <- tibble()
for(i in gene_list$gene_name){

	gene_coords <- filter(gene_list, gene_name==i)

	tx_id <- gene_coords$transcript_id

	gene_TSS <- gene_coords$tss
	gene_strand <- gene_coords$strand

	region_start <- gene_TSS - region_size/2
	region_end <- gene_TSS + region_size/2

	region_wps <- filter(WPS, pos >= region_start & pos <= region_end)

	region_wps <- tibble(
		"gene_name" = i,
		region_wps
	)

	if(gene_strand == "+") {

	region_wps <- region_wps %>%
		transmute(
			transcript_id = tx_id,
			gene_name,
			chr,
			relative_pos =  pos - gene_TSS,
			WPS
		) %>%
		arrange(relative_pos)

	} else{

	region_wps <- region_wps %>%
		transmute(
			transcript_id = tx_id,
			gene_name,
			chr,
			relative_pos =  gene_TSS - pos,
			WPS
		) %>%
		arrange(relative_pos)

	}

	# Adjusting WPS to a mean of zero across each 1 kb genomic tile
	region_wps$WPS_adj <- NA
	region_wps$WPS_adj[region_wps$relative_pos <= -1500] <- region_wps$WPS[region_wps$relative_pos <= -1500] - mean(region_wps$WPS[region_wps$relative_pos <= -1500])
	region_wps$WPS_adj[region_wps$relative_pos > -1500 & region_wps$relative_pos <= -500] <- region_wps$WPS[region_wps$relative_pos > -1500 & region_wps$relative_pos <= -500] - mean(region_wps$WPS[region_wps$relative_pos > -1500 & region_wps$relative_pos <= -500])
	region_wps$WPS_adj[region_wps$relative_pos > -500 & region_wps$relative_pos <= 500] <- region_wps$WPS[region_wps$relative_pos > -500 & region_wps$relative_pos <= 500] - mean(region_wps$WPS[region_wps$relative_pos > -500 & region_wps$relative_pos <= 500])
	region_wps$WPS_adj[region_wps$relative_pos > 500 & region_wps$relative_pos <= 1500] <- region_wps$WPS[region_wps$relative_pos > 500 & region_wps$relative_pos <= 1500] - mean(region_wps$WPS[region_wps$relative_pos > 500 & region_wps$relative_pos <= 1500])
	region_wps$WPS_adj[region_wps$relative_pos > 1500 & region_wps$relative_pos <= 2500] <- region_wps$WPS[region_wps$relative_pos > 1500 & region_wps$relative_pos <= 2500] - mean(region_wps$WPS[region_wps$relative_pos > 1500 & region_wps$relative_pos <= 2500])

	WPS_per_gene <- rbind(WPS_per_gene, region_wps)

}


# Summarising WPS per position
cat("[fetch-WPS-per-gene.R]:	Calculating average WPS values for each position relative to the TSS...\n")
WPS_per_gene_wide <- dcast(
	WPS_per_gene[,c("relative_pos","gene_name","WPS_adj")],
	formula = "relative_pos ~ gene_name",
	value.var = "WPS_adj"
)

mean_WPS_per_pos <- tibble(
	relative_pos = WPS_per_gene_wide$relative_pos,
	WPS_adj = rowMeans(WPS_per_gene_wide[,-1], na.rm = T)
)

cat("[fetch-WPS-per-gene.R]:	Estimating peak WPS vwithin 500 bp of each TSS...\n")
peak_WPS_per_gene <- WPS_per_gene %>%
	filter(relative_pos >= -500 & relative_pos <= 500) %>%
	group_by(gene_name) %>%
	summarise(peak_WPS = max(WPS))

# Exporting results
cat("[fetch-WPS-per-gene.R]:	Exporting results as TSV files...\n")
file_name_root <- gsub(
	"//",
	"/",
	paste0(
		output_dir, 
		gsub("_WPS.*$","",file_name),
		"_",
		chromosome,
		"_"
	)
)

write.table(
	WPS_per_gene,
	file = paste0(file_name_root,"WPS-per-gene_adjusted.tsv"),
	sep = "\t",
	quote = F,
	row.names = F
)

write.table(
	mean_WPS_per_pos,
	file = paste0(file_name_root,"average-WPS-per-position_adjusted.tsv"),
	sep = "\t",
	quote = F,
	row.names = F
)

write.table(
	peak_WPS_per_gene,
	file = paste0(file_name_root,"peak-WPS-per-gene_adjusted.tsv"),
	sep = "\t",
	quote = F,
	row.names = F
)

cat("[fetch-WPS-per-gene.R]:	...done!\n\n")
