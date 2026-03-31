process CHROM_SIZES {
    tag "${fai.baseName}"

    input:
    tuple path(ref_genome), path(fai)

    output:
    tuple val("${ref_genome.getFileName()}"), path("*.chrom.sizes"), emit: sizes

    script:
    def prefix = ref_genome.baseName
    """
    cut -f1,2 ${fai} > ${prefix}.chrom.sizes
    """
}
