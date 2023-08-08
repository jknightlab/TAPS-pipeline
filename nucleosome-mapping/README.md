# Mapping of nucleosome positions around genes using cfDNA

Author:		Eddie Cano-Gamez

Email:		ecg@well.ox.ac.uk


## Overview

This directory contains codes to infer nucleosome positions around TSS regions.

To do so, 5 kb windows centred at the TSS are constructed for each transcript in gencode. Next, a sliding window approach is used to generate windows of size k (e.g. 120 bp) that can be used to scan the entire region.

Fragmentomic information (i.e. fragment sizes for each paired-end read) is first used to identify mononucleosomal cfDNA fragments (i.e. 120 - 200 bp). Next, the intersection between these fragments and each sliding window is quantified.

Nucleosome positioning is finally inferred using windowed protection scores (WPS), an approach proposed by Snyder et al. (https://doi.org/10.1016/j.cell.2015.11.050). In brief, the WPS of a window is defined as the number of cfDNA fragments completely encompassing that region minus the number of cfDNA fragments with breakpoints (i.e. beginning or end sites) within the same region. High WPS values indicate a region is protected from nuclease cutting, which indicates a nucleosome is positioned on it. Low WPS values indicate higher nuclease cutting rates, which suggest the genomic position in question is not bound by a nucleosome.



## Repository structure

The codes contained within this repository are written in bash and ordered as follows:

```
./
 |-- 1_create-sliding-windows.sh	Creates sliding windows of size 'k', with an sliding step size 's' for the region around the TSS of each transcript reported in gencode.
 |-- 2_calculate-WPS.sh			Calculates WPS scores for each sliding window using bedtools intersect. This is done by substracting the number of intersections with 100% overlap (i.e. -f 1) minus the number of incomplete intersections (i.e. overlap < 100%)
 `-- 3_fetch-WPS-per-chromosome.sh	Takes the outputs from step 2 and summarises them by chromosome and gene. This code parallelises the analysis on a per chromosome basis, with each chromosome being analysed using the 'fetch-WPS-per-gene.R' code in this directory.
```

