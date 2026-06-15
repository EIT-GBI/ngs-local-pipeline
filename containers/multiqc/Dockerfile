FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq multiqc"
LABEL org.opencontainers.image.description="MultiQC 1.33 for the NGS sequencing pipeline"

# Mirror the conda spec from conf/modules.config (withLabel: multiqc)
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        multiqc=1.33 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
