# TAPS data processing pipeline

Author:		Eddie Cano-Gamez
Email:		ecg@well.ox.ac.uk


## Overview

This repository contains a collection of codes to process methylation data using the TET-assisted pyridine borane sequencing (TAPS) method.
Codes are based on the analysis pipeline previously published in Science Advances (), and were developped with assistance from Masato Ioue (masato.inoue@linacre.ox.ac.uk) and Dr Chunxiao-Song.


## Repository structure

The codes contained within this repository are written in bash and ordered as follows:

./
 |-- 1_trim-galore.sh			Adapter trimming and read clipping with TrimGalore! (i.e. cutadapt, followed by FastQC quality assessment)
 |-- 2_bwa-mem.sh			Alignment of reads to the reference genome using bwa mem
 |-- 3_sort_and_markdup.sh		Quality filtering and sorting of mapped reads with samtools, followed by marking of duplicated reads by picard
 `-- 4_methyl-dackel.sh			Calling of methylation events using methylDackel
