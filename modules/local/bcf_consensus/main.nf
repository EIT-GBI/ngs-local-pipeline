process BCF_CONSENSUS {
    tag "${meta.id}"
    label 'bcftools'

    input:
    tuple val(meta), path(bcf), path(bcf_index)
    tuple path(ref_genome), path("${ref_genome}.fai")

    output:
    tuple val(meta), path("*fna"), emit: consensus
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version | head -1 | sed "s/bcftools //"'), emit: versions_bcftools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools consensus -f ${ref_genome} ${bcf} > ${prefix}.consensus.fna
    """
}
