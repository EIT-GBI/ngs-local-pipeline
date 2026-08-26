process FLAGSTAT{
    tag "${meta.id}"
    label 'samtools'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*flagstat.txt")
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | sed "s/samtools //"'), emit: versions_samtools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools flagstat ${bam} > ${prefix}.flagstat.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf '20000 + 0 in total (QC-passed reads + QC-failed reads)\n19500 + 0 mapped (97.50%% : N/A)\n' > ${prefix}.flagstat.txt
    """
}
