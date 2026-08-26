process BCFTOOLS_STATS {
    tag "${meta.id}"
    label 'bcftools'

    input:
    tuple val(meta), path(bcf), path(bcf_index)

    output:
    tuple val(meta), path("*.bcftools_stats.txt"), emit: stats
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version | head -1 | sed "s/bcftools //"'), emit: versions_bcftools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools stats ${bcf} > ${prefix}.bcftools_stats.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf 'SN\t0\tnumber of records:\t3\nSN\t0\tnumber of SNPs:\t3\n' > ${prefix}.bcftools_stats.txt
    """
}
