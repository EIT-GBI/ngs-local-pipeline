process BIGWIG {
    tag "${meta.id}"
    label 'bigwig'

    input:
    tuple val(meta), path(bam), path(bai)
    path chrom_sizes

    output:
    tuple val(meta), path("*.bw"), emit: bigwig
    tuple val("${task.process}"), val('bedtools'), eval('bedtools --version | sed "s/bedtools v//"'), emit: versions_bedtools, topic: versions
    tuple val("${task.process}"), val('bedGraphToBigWig'), eval('bedGraphToBigWig 2>&1 | head -1 | sed "s/bedGraphToBigWig v //; s/ .*//"'), emit: versions_bedgraphtobigwig, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # BAM to bedgraph
    bedtools genomecov -ibam ${bam} -bg \\
        | sort -k1,1 -k2,2n > ${prefix}.bedgraph

    # Bedgraph to BigWig
    bedGraphToBigWig ${prefix}.bedgraph ${chrom_sizes} ${prefix}.bw

    # Clean up intermediate file
    rm -f ${prefix}.bedgraph
    """
}
