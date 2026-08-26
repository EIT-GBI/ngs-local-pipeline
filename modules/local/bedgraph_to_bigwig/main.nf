process BEDGRAPH_TO_BIGWIG {
    tag "${meta.id}"
    label 'ucsc_bedgraphtobigwig'

    input:
    tuple val(meta), path(bedgraph)
    path chrom_sizes

    output:
    tuple val(meta), path("*.bw"), emit: bigwig
    tuple val("${task.process}"), val('bedGraphToBigWig'), eval('bedGraphToBigWig 2>&1 | head -1 | sed "s/bedGraphToBigWig v //; s/ .*//"'), emit: versions_bedgraphtobigwig, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bedGraphToBigWig ${bedgraph} ${chrom_sizes} ${prefix}.bw
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bw
    """
}
