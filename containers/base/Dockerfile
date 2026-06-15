FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq base"
LABEL org.opencontainers.image.description="Default base image for label-less, script-based processes (CHROM_SIZES, PARSE_ALIGNMENT_LOG). Provides bash + coreutils + gawk + grep + sed."

# Guarantee the GNU text-processing tools the pure-bash modules rely on,
# independent of what the slim base image ships with.
RUN micromamba install -y -n base -c conda-forge \
        bash coreutils gawk grep sed && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
