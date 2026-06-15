FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq fastp"
LABEL org.opencontainers.image.description="fastp 0.23.4 for the NGS sequencing pipeline"

# Mirror the conda spec from conf/modules.config (withLabel: fastp)
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        fastp=0.23.4 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
