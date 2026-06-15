# NGS Sequencing Local Pipeline

## What is this?
Nextflow (DSL2) pipeline for Illumina paired-end bacterial sequencing analysis
with conda environments. Originally a local bash script (run_pipeline.sh), being
migrated to Nextflow to run on an OCI Slurm cluster. Pipeline is still under
construction — local execution and conda profiles work, cluster config is not yet in place.

## Pipeline steps
FASTQC (raw) → FASTP (trimming) → FASTQC (trimmed) → BWA MEM (alignment) →
FLAGSTAT → VARIANT_CALLING_FILTERING (bcftools mpileup/call/filter, haploid) →
BCF2VCF + BCF2CSV + BCF_CONSENSUS → MULTIQC

## Project structure
- main.nf — workflow definition, channel wiring, publish/output blocks
- modules/local/<tool>/main.nf — one process per module
- conf/modules.config — conda envs and process labels
- nextflow.config — params (samplesheet, filtering thresholds, paths)
- assets/samplesheet.csv — input: sample_id, ref_genome columns
- assets/multiqc_config.yaml — MultiQC report customisation
- run_pipeline.sh — legacy bash version (kept for reference)

## Key conventions
- Each module uses process labels for conda env assignment (e.g. `label 'bcftools'`)
- Samples can use different reference genomes — refs are deduplicated before indexing
- Workflow `output {}` block handles publishing (not `publishDir` in modules)
- Haploid variant calling (`--ploidy 1`)
- Filtering params: min_qmap, min_depth, min_qual

## Running
```
nextflow run main.nf -profile conda -resume               # conda environments (local)
nextflow run main.nf -profile docker -resume              # public container images (local)
nextflow run main.nf -profile apptainer,slurm -resume     # HPC cluster (Apptainer + Slurm)
```

## Profiles
- Profiles are composable: container runtime (`conda`/`docker`/`apptainer`) + executor (`slurm`)
- `docker` and `apptainer` mutually disable each other; conda is NOT globally enabled — the active profile decides
- `slurm` profile: `process.queue = { params.partition }`, `process.clusterOptions = { params.clusteropts }` (closures, null = cluster default)

## Containers
- Images are pulled directly from PUBLIC registries — no building or pushing (no `containers/` dir)
- Each label has a `container` in `conf/modules.config`: single tools → `quay.io/biocontainers/...` (exact versions)
- Alignment (`bwa_samtools` label) uses nf-core's public Wave image `community.wave.seqera.io/library/bwa_htslib_samtools` (bwa 0.7.19 / samtools 1.22.1 — not the pinned 0.7.18/1.20, since no public image has the exact combo)
- BigWig was split into `BEDTOOLS_GENOMECOV` (label `bedtools`) + `BEDGRAPH_TO_BIGWIG` (label `ucsc_bedgraphtobigwig`) so each uses a single-tool biocontainer (old combined `bigwig` module/label removed)
- Label-less script steps (CHROM_SIZES, PARSE_ALIGNMENT_LOG) use `params.base_container` (`quay.io/nf-core/ubuntu:22.04`)
- Strict Nextflow config grammar: no `if` statements in config — use closures (`{ params.x }`) for param-driven directives

## Gotchas
- `FLAGSTAT` main output has no `emit:` name — reference it as `FLAGSTAT.out[0]`
- Avoid `log` as an input variable name — it's a Nextflow reserved keyword
- The `parse_alignment_log` module is pure bash (no conda label needed)
