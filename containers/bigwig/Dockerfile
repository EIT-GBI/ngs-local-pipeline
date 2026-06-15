FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="ngs-seq bigwig"
LABEL org.opencontainers.image.description="bedtools 2.31.1 + ucsc-bedGraphToBigWig 482 for the NGS sequencing pipeline (BigWig tracks)"

# Mirror the conda spec from conf/modules.config (withLabel: bigwig)
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        bedtools=2.31.1 ucsc-bedgraphtobigwig=482 && \
    micromamba clean --all --yes

# Nextflow runs commands without activating the env, so expose binaries on PATH
ENV PATH="/opt/conda/bin:${PATH}"
