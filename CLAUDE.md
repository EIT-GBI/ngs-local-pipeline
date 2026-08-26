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
- main.nf — thin entry point: the ONLY place that reads `params.*`, plus the
  `publish:` section and `output {}` block
- workflows/ngs/main.nf — the named `NGS` workflow: all channel wiring, every
  setting taken as a `take:` argument
- modules/local/<tool>/main.nf — one process per module
- stub-shims/ — fake tool executables, on PATH only under `-profile stub`
- conf/modules.config — conda envs and process labels
- nextflow.config — params (samplesheet, filtering thresholds, paths)
- assets/samplesheet.csv — input: sample_id, ref_genome columns
- assets/multiqc_config.yaml — MultiQC report customisation
- run_pipeline.sh — legacy bash version (kept for reference)

## Key conventions

### The entry/named-workflow split (this is load-bearing)
`main.nf` is deliberately thin and `workflows/ngs/main.nf` holds everything. The
rule that makes it work: **only the entry workflow reads `params.*`**; `NGS`
receives every setting through `take:`. That is what lets another pipeline
include `NGS` — twice in one run, even, with two different `reads_dir` values.
Reading `params.reads_dir` inside `NGS` would make both invocations see the same
value, which is the params-collision trap that stops most pipelines from being
composed. nf-seqcomp depends on this: it includes `NGS` once per sequencing
platform. The shape is nf-core/sarek's.

Consequences to respect:
- **`moduleDir`, never `projectDir`, inside `workflows/` and `modules/`.** Under
  nesting `projectDir` is the *caller's* root. The MultiQC config resolution is
  the live example — and a wrong path there fails quietly, since MultiQC treats a
  missing `--config` as "no config" rather than an error.
- **Do not introduce `channel.topic()`.** Topics are run-scoped, not
  workflow-scoped, so two invocations of `NGS` would pour into the same topic.
  `COLLECT_VERSIONS` takes explicit `.mix()`ed `.out.versions_*` channels for
  exactly this reason. The `topic:` labels on the `eval` outputs are unused.
- **Publishing belongs to the entry workflow.** `publish:` and `output {}` are
  only honoured for the entry point, so a parent pipeline including `NGS` has to
  declare its own targets from `NGS.out.*`. Keep `emit:` names stable — they are
  another pipeline's API.
- `MULTIQC` honours `task.ext.prefix` to rename its report. Unset (the standalone
  default) leaves `multiqc_report.html`. A parent including `NGS` more than once
  must set it per instance, or the two reports collide when a downstream process
  stages both.

### Reads and modules
- Reads are resolved from `--reads_dir` by glob, trying flat (`<id>*_R1*.fastq.gz`,
  Illumina bcl-convert) then a per-sample subdirectory (`<id>/*_R1*.fastq.gz`,
  Element AVITI / Bases2Fastq). A `*` glob does not cross `/`, so both patterns are
  needed; exactly one R1 and one R2 must match, so lane-split FASTQs are rejected
- Each module uses process labels for conda env assignment (e.g. `label 'bcftools'`)
- Samples can use different reference genomes — refs are deduplicated before indexing
- Workflow `output {}` block handles publishing (not `publishDir` in modules)
- Haploid variant calling (`--ploidy 1`)
- Filtering params: min_qmap, min_depth, min_qual

## Testing

There is no unit-test harness; the stub run is the regression test:

```bash
nextflow run main.nf -stub-run -profile stub \
    --samplesheet <sheet> --reads_dir <fastqs> --ref_dir <refs> \
    --publish_dir <out> --analysis_name test
```

Empty `.fastq.gz` files and one-line FASTAs are enough. Every module that shells
out to a tool has a `stub:` block; `CHROM_SIZES` (a plain `cut`),
`PARSE_ALIGNMENT_LOG` (pure awk/sed) and `COLLECT_VERSIONS` (an `exec:` task)
deliberately have none, so they run for real and their parsing stays honest — the
`ALIGNMENT_BWA` stub therefore writes a realistic BWA log rather than an empty one.

Static checks:

```bash
nextflow lint . -exclude nf-test.config
```

The exclude is required: `nf-test.config` is nf-test's own DSL, not Nextflow
config, so `nextflow lint` mis-parses it and reports a false error. Editing it to
satisfy the linter would break nf-test. Expect zero warnings otherwise — declare
closure parameters explicitly, since the implicit `it` is deprecated.

**`-profile stub` is not optional.** Every module declares `eval(...)` version
outputs, and Nextflow runs those commands even when a `stub:` block replaces the
script — a missing tool fails the task with "Unable to evaluate output" (exit
127). That is documented behaviour, not a bug. The profile puts `stub-shims/` on
PATH so the tools exist; each shim prints a version string in the exact shape its
module's `eval` command parses. Scoped to the profile, so a real run can never
shadow the containerised tools.

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
- In an awk action, `print+0` parses as `print (+0)` and prints a literal `0`,
  not the value of `$0` — write `print \$0+0`. This silently zeroed
  `insert_mean`/`insert_std` in the MultiQC BWA table until the stub run caught it
- A `def`-assigned closure cannot be called under the strict syntax parser
  (`nextflow lint` flags it; it becomes a hard error in Nextflow 26.04). The
  FASTQ-glob helper is a top-level `findMate()` function for this reason
