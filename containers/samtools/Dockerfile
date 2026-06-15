FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq samtools"
LABEL org.opencontainers.image.description="samtools 1.20 for the NGS sequencing pipeline"

# Mirror the conda spec from conf/modules.config (withLabel: samtools)
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        samtools=1.20 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
