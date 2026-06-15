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
nextflow run main.nf -profile conda -resume     # conda environments
nextflow run main.nf -profile docker -resume    # Docker images (build first: ./containers/build.sh)
```

## Containers (Docker)
- Each conda label has a matching `container` in `conf/modules.config`; tags mirror the pinned versions
- Dockerfiles live in `containers/<label>/` (micromamba base, installs the same bioconda spec)
- `containers/base/` is the default image for label-less script steps (CHROM_SIZES, PARSE_ALIGNMENT_LOG)
- `params.container_registry` (default `ngs-seq`) prefixes all image tags; build/push via `containers/build.sh`
- conda is no longer globally enabled in `modules.config` — the active profile (`conda`/`docker`) decides

## Gotchas
- `FLAGSTAT` main output has no `emit:` name — reference it as `FLAGSTAT.out[0]`
- Avoid `log` as an input variable name — it's a Nextflow reserved keyword
- The `parse_alignment_log` module is pure bash (no conda label needed)
