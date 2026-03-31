process SAMTOOLS_STATS {
    tag "${meta.id}"
    label 'samtools'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.stats"), emit: stats
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | sed "s/samtools //"'), emit: versions_samtools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools stats ${bam} > ${prefix}.stats
    """
}
