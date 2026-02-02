process FLAGSTAT{
    tag "${meta.id}"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*flastat.txt")
    tuple val("${task.process}"), val('samtools'), eval('samtools --version 2>&1 | sed -e "s/samtools //g"'), emit: versions_samtools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools flagstat ${bam} > ${prefix}.flagstat.txt
    """
}