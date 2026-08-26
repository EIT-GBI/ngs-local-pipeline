process BEDTOOLS_GENOMECOV {
    tag "${meta.id}"
    label 'bedtools'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.bedgraph"), emit: bedgraph
    tuple val("${task.process}"), val('bedtools'), eval('bedtools --version | sed "s/bedtools v//"'), emit: versions_bedtools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # BAM to bedgraph (sorted, ready for bedGraphToBigWig)
    bedtools genomecov -ibam ${bam} -bg \\
        | sort -k1,1 -k2,2n > ${prefix}.bedgraph
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf 'stub_chr\t0\t1000\t25\n' > ${prefix}.bedgraph
    """
}
