process SAMTOOLS_COVERAGE {
    tag "${meta.id}"
    label 'samtools'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.coverage.txt"), emit: coverage
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | sed "s/samtools //"'), emit: versions_samtools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools coverage ${bam} > ${prefix}.coverage.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf '#rname\tstartpos\tendpos\tnumreads\tcovbases\tcoverage\tmeandepth\tmeanbaseq\tmeanmapq\n' > ${prefix}.coverage.txt
    printf 'stub_chr\t1\t1000\t500\t1000\t100.00\t25.0\t35.0\t60.0\n' >> ${prefix}.coverage.txt
    """
}
