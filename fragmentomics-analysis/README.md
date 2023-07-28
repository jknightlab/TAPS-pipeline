# Fragmentomics analysis of TAPS data

Author:		Eddie Cano-Gamez

Email:		ecg@well.ox.ac.uk


## Overview

This directory contains codes to extract fragmentomic information from aligned reads derived from TAPS sequencing.

Fragmentomic variables of interest include fragment size distributions and fragment 5' end motif sequences.


## Repository structure

The codes contained within this repository are written in bash and ordered as follows:

```
./
 |-- 1_get-fragment-coordinates.sh	Retrieves the start and end coordinates of each properly mapped, unique pair of sequencing reads.
 `-- 2_get-end-motifs.sh		Identifies 5' end motif sequences (k = 4 bp) for each read pair. This is achieved by retrieving reference genome sequences for the first 4 bp in the top strand and reverse complement reference genome sequences for the last 4 bp in the bottom strand.
```

