# NGS Sequencing Pipeline (Nextflow DSL2)

Nextflow pipeline for Illumina paired-end bacterial sequencing analysis — from raw reads to variants, consensus sequences, and QC reports. Uses conda environments for dependency management.

## Pipeline steps

```
FASTQC (raw) → FASTP (trimming) → FASTQC (trimmed) → BWA MEM (alignment + sort + index)
  → FLAGSTAT / SAMTOOLS_STATS / SAMTOOLS_COVERAGE
  → VARIANT_CALLING_FILTERING (bcftools mpileup/call/filter, haploid)
  → BCF2VCF + BCF2CSV + BCF_CONSENSUS
  → BIGWIG (coverage track for IGV)
  → MULTIQC (aggregated report with software versions)
```

## Outputs

| Directory                | Content                              |
|--------------------------|--------------------------------------|
| `alignment/`             | Sorted BAM + BAI                     |
| `variants/bcf/`          | Filtered BCF + index                 |
| `variants/vcf/`          | VCF.gz + tabix index                 |
| `variants/csv/`          | Variant summary CSV                  |
| `consensus/`             | Consensus FASTA                      |
| `bigwig/`                | BigWig coverage tracks               |
| `qc/fastqc/raw/`        | FastQC reports on raw reads          |
| `qc/fastqc/trimmed/`    | FastQC reports on trimmed reads      |
| `qc/fastp/`             | Fastp trimming reports               |
| `qc/flagstat/`          | Samtools flagstat                    |
| `qc/samtools_stats/`    | Samtools stats                       |
| `qc/samtools_coverage/` | Samtools coverage                    |
| `qc/bcftools_stats/`    | Bcftools variant stats               |
| `qc/multiqc/`           | MultiQC aggregated report            |
| `logs/`                  | Alignment and variant calling logs   |

## Requirements

- [Nextflow](https://www.nextflow.io/) (>= 22.10)
- **Either** Conda **or** Docker for dependency management (pick a profile when running)

No manual tool installation needed. Every tool (FastQC, fastp, BWA, samtools, bcftools,
bedtools, ucsc-bedGraphToBigWig, MultiQC) is provided through:
- conda environments (`-profile conda`), managed automatically via `conf/modules.config`, or
- Docker images (`-profile docker`), one per tool — see [Docker](#docker).

## Input

Prepare a samplesheet CSV with two columns (see `assets/samplesheet.csv` for an example):

```csv
sample_id,ref_genome
sample_A,reference.fa
sample_B,another_reference.fa
```

- Paired-end reads are matched by `{sample_id}*_R1*.fastq.gz` / `*_R2*.fastq.gz` in the reads directory
- Each sample can use a different reference genome — references are deduplicated before indexing

## Usage

```bash
nextflow run main.nf -profile conda -resume \
    --samplesheet /path/to/samplesheet.csv \
    --reads_dir /path/to/fastq/files \
    --ref_dir /path/to/reference/genomes \
    --publish_dir /path/to/output \
    --analysis_name my_analysis
```

Results will be published to `/path/to/output/my_analysis/`.

### Docker

The pipeline ships one Docker image per tool, built from the same pinned versions as the
conda specs. Dockerfiles live under `containers/<tool>/`, plus a small `base` image for the
label-less helper steps.

**1. Build the images** (one-time, or whenever a tool version changes):

```bash
./containers/build.sh
```

This tags the images under the `ngs-seq/` namespace (e.g. `ngs-seq/fastqc:0.12.1`), matching
`params.container_registry` in `nextflow.config`.

**2. Run with the docker profile:**

```bash
nextflow run main.nf -profile docker -resume \
    --samplesheet /path/to/samplesheet.csv \
    --reads_dir /path/to/fastq/files \
    --ref_dir /path/to/reference/genomes \
    --publish_dir /path/to/output \
    --analysis_name my_analysis
```

**Remote registry (e.g. GHCR).** To build, push, and run against a remote registry:

```bash
REGISTRY=ghcr.io/my-org/ngs-seq PUSH=1 ./containers/build.sh
nextflow run main.nf -profile docker --container_registry ghcr.io/my-org/ngs-seq ...
```

### Required parameters

| Parameter         | Description                                      |
|-------------------|--------------------------------------------------|
| `--samplesheet`   | Path to the input samplesheet CSV                |
| `--reads_dir`     | Directory containing paired-end FASTQ files      |
| `--ref_dir`       | Directory containing reference genome FASTA files |
| `--publish_dir`   | Parent directory for output                      |
| `--analysis_name` | Name of the output folder (e.g. the analysis/run name) |

### Optional parameters

| Parameter     | Default | Description                          |
|---------------|---------|--------------------------------------|
| `--min_depth` | 10      | Minimum read depth for variant calls |
| `--min_qmap`  | 20      | Minimum mapping quality              |
| `--min_qual`  | 20      | Minimum variant quality              |

## Project structure

```
main.nf                        # Workflow definition and channel wiring
modules/local/<tool>/main.nf   # One process per module
conf/modules.config            # Conda envs, container images, and process labels
nextflow.config                # Params and profiles (standard / conda / docker)
containers/<tool>/Dockerfile   # One image per tool (mirrors the conda specs)
containers/build.sh            # Build/push helper for the Docker images
assets/samplesheet.csv         # Example samplesheet for testing
assets/multiqc_config.yaml     # MultiQC report customisation
```
