process BWA_INDEX {
    tag "${ref_genome.baseName}"
    label 'bwa'

    input:
    path ref_genome

    output:
    tuple path(ref_genome), path("bwa_index"), emit: index
    tuple val("${task.process}"), val('bwa'), eval('bwa 2>&1 | sed -n "s/^Version: //p"'), topic: versions, emit: versions_bwa

    script:
    def prefix = task.ext.prefix ?: "${ref_genome.baseName}"
    def args   = task.ext.args ?: ''
    """
    mkdir bwa_index
    bwa \\
        index \\
        $args \\
        -p bwa_index/${prefix} \\
        ${ref_genome}
    cp ${ref_genome} bwa_index/${ref_genome}
    """

    stub:
    def prefix = task.ext.prefix ?: "${ref_genome.baseName}"
    """
    mkdir bwa_index
    touch bwa_index/${prefix}.amb
    touch bwa_index/${prefix}.ann
    touch bwa_index/${prefix}.bwt
    touch bwa_index/${prefix}.pac
    touch bwa_index/${prefix}.sa
    cp  ${ref_genome} bwa_index/${ref_genome}
    """
}
