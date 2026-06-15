FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq bwa+samtools"
LABEL org.opencontainers.image.description="BWA 0.7.18 + samtools 1.20 for the NGS sequencing pipeline (alignment step)"

# Mirror the conda spec from conf/modules.config (withLabel: bwa_samtools)
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        bwa=0.7.18 samtools=1.20 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
