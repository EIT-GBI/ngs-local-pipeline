FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq fastqc"
LABEL org.opencontainers.image.description="FastQC 0.12.1 for the NGS sequencing pipeline"

# Mirror the conda spec from conf/modules.config (withLabel: fastqc)
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        fastqc=0.12.1 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
