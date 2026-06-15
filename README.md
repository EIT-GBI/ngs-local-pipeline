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
- A dependency runtime — **Conda**, **Docker**, or **Apptainer** (pick a profile when running)

No manual tool installation needed. Every tool (FastQC, fastp, BWA, samtools, bcftools,
bedtools, ucsc-bedGraphToBigWig, MultiQC) is provided through:
- conda environments (`-profile conda`), managed automatically via `conf/modules.config`, or
- public container images (`-profile docker` / `-profile apptainer`), pulled directly from
  public registries — see [Containers](#containers). No building or pushing required.

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

### Containers

Container images are pulled directly from public registries — nothing to build or push.
Each process label maps to an image in `conf/modules.config`:

- single-tool steps → `quay.io/biocontainers/...` at the exact pinned versions
- alignment (BWA + samtools in one image) → nf-core's public Seqera Wave image
  `community.wave.seqera.io/library/bwa_htslib_samtools` (bwa 0.7.19 / samtools 1.22.1)
- the BigWig step is split into `bedtools genomecov` and `bedGraphToBigWig`, so each uses
  its own single-tool biocontainer
- label-less helper steps use `quay.io/nf-core/ubuntu:22.04` (`params.base_container`)

**Run locally with Docker:**

```bash
nextflow run main.nf -profile docker -resume \
    --samplesheet /path/to/samplesheet.csv \
    --reads_dir /path/to/fastq/files \
    --ref_dir /path/to/reference/genomes \
    --publish_dir /path/to/output \
    --analysis_name my_analysis
```

### HPC cluster (Apptainer + Slurm)

On the cluster, dependencies run via **Apptainer** and jobs are submitted through **Slurm**.
The `apptainer` and `slurm` profiles are composable. Apptainer pulls each public image via
`docker://` and caches the `.sif` files — point `--apptainer_cachedir` at shared storage so
all nodes reuse them.

```bash
nextflow run main.nf -profile apptainer,slurm -resume \
    --apptainer_cachedir /mnt/gbi-shared/apptainer_cache \
    --partition compute \
    --clusteropts '--account=gbi' \
    --samplesheet ... --reads_dir ... --ref_dir ... --publish_dir ... --analysis_name ...
```

Alternatively, `-profile conda,slurm` skips containers and uses conda on the nodes (requires
conda to be available on the compute nodes, not just the login node).

#### Cluster parameters

| Parameter              | Default | Description                                                        |
|------------------------|---------|--------------------------------------------------------------------|
| `--apptainer_cachedir` | _(none)_ | Shared dir where pulled `.sif` images are cached and reused across nodes |
| `--apptainer_bind`     | _(none)_ | Extra bind path(s) into containers, e.g. a shared mount (comma-separated) |
| `--partition`          | _(none)_ | Slurm partition/queue (omit to use the cluster default)            |
| `--clusteropts`        | _(none)_ | Extra options appended to every `sbatch`, e.g. `--account=gbi --qos=normal` |
| `--base_container`     | `quay.io/nf-core/ubuntu:22.04` | Image for label-less script-only steps        |

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
assets/samplesheet.csv         # Example samplesheet for testing
assets/multiqc_config.yaml     # MultiQC report customisation
```
