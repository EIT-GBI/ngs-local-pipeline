FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq bcftools"
LABEL org.opencontainers.image.description="bcftools 1.20 (+ htslib tabix/bgzip) for the NGS sequencing pipeline"

# Mirror the conda spec from conf/modules.config (withLabel: bcftools).
# The bcftools package pulls in htslib, which provides tabix/bgzip used by BCF2VCF.
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        bcftools=1.20 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
