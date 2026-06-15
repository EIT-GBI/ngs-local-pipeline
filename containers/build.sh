#!/usr/bin/env bash
#
# Build (and optionally push) the per-tool Docker images for the NGS pipeline.
# One image per conda label in conf/modules.config, built from the same pinned specs.
#
# Usage:
#   ./containers/build.sh                       # build, tagged under "ngs-seq/"
#   REGISTRY=ngs-seq ./containers/build.sh       # custom local namespace
#   REGISTRY=ghcr.io/my-org/ngs-seq PUSH=1 ./containers/build.sh   # build + push to GHCR
#
# REGISTRY must match params.container_registry in nextflow.config so Nextflow
# pulls the images these tags produce.

set -euo pipefail

REGISTRY="${REGISTRY:-ngs-seq}"
PUSH="${PUSH:-0}"

# Resolve the directory this script lives in (the containers/ dir).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# label_dir  ->  image_name:tag   (tag mirrors the pinned tool version[s])
IMAGES=(
    "base:base:1.0"
    "fastqc:fastqc:0.12.1"
    "fastp:fastp:0.23.4"
    "bwa:bwa:0.7.18"
    "bwa_samtools:bwa_samtools:0.7.18-1.20"
    "samtools:samtools:1.20"
    "bcftools:bcftools:1.20"
    "bigwig:bigwig:2.31.1"
    "multiqc:multiqc:1.33"
)

for entry in "${IMAGES[@]}"; do
    dir="${entry%%:*}"
    rest="${entry#*:}"
    name="${rest%%:*}"
    tag="${rest#*:}"
    image="${REGISTRY}/${name}:${tag}"

    echo "==> Building ${image}"
    docker build -t "${image}" "${SCRIPT_DIR}/${dir}"

    if [[ "${PUSH}" == "1" ]]; then
        echo "==> Pushing ${image}"
        docker push "${image}"
    fi
done

echo "==> Done. Run the pipeline with: nextflow run main.nf -profile docker -resume"
