<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-rnaseqseminar_logo_dark.png">
    <img alt="nf-core/rnaseqseminar" src="docs/images/nf-core-rnaseqseminar_logo_light.png">
  </picture>
</h1>

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A524.10.5-green?style=flat&logo=nextflow&logoColor=white)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

---

## Introduction

**nf-core/rnaseqseminar** is a reproducible and modular RNA-seq analysis pipeline built using Nextflow and nf-core standards.  
It processes raw sequencing reads (FASTQ files) to perform quality control, trimming, alignment, and transcript quantification.  
The pipeline generates gene expression estimates along with comprehensive quality control reports using MultiQC.

---

## Pipeline overview

The pipeline performs the following main steps:

1. Quality control of raw reads using FastQC  
2. Adapter trimming and quality filtering using TrimGalore  
3. Genome alignment using STAR  
4. Transcript quantification using Salmon  
5. Alignment quality control using DupRadar and Qualimap  
6. Aggregation of results using MultiQC  

---

## Pipeline workflow

The pipeline follows a structured workflow:

**Input → Quality Control → Trimming → Alignment & Quantification (parallel) → QC → MultiQC report**

---

## Usage

### Requirements

- Nextflow (>= 24.10.5)  
- Docker or Singularity  

If you are new to Nextflow, see: https://nf-co.re/docs/usage/installation

---

### Input

Prepare a samplesheet (`samplesheet.csv`) with the following format:

```csv
sample,fastq_1,fastq_2
SAMPLE_1,reads_1.fastq.gz,reads_2.fastq.gz
```
---

## Run the pipeline

```bash
nextflow run albabernal03/nf-core-rnaseqseminar \
   -profile test,singularity \
   --input assets/samplesheet_seminar.csv \
   --outdir results
```
---
## Output

The pipeline generates:

- Quality control reports (FastQC, MultiQC)  
- Alignment files (BAM)  
- Transcript quantification results (Salmon)  
- Duplication and alignment QC metrics  
- Execution reports and logs  

Example output structure:

```bash
results/
├── fastqc/
├── trimgalore/
├── star/
├── salmon/
├── dupradar/
├── qualimap/
├── multiqc/
└── pipeline_info/
```
