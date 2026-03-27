process BWA_INDEX {
    tag "${ref_genome.baseName}"

    input:
    path ref_genome

    output:
    tuple path(ref_genome), path("bwa"), emit: index
    tuple val("${task.process}"), val('bwa'), eval('bwa 2>&1 | sed -n "s/^Version: //p"'), topic: versions, emit: versions_bwa

    script:
    def prefix = task.ext.prefix ?: "${ref_genome.baseName}"
    def args   = task.ext.args ?: ''
    """
    mkdir bwa
    bwa \\
        index \\
        $args \\
        -p bwa/${prefix} \\
        $ref_genome
    """

    stub:
    def prefix = task.ext.prefix ?: "${ref_genome.baseName}"
    """
    mkdir bwa
    touch bwa/${prefix}.amb
    touch bwa/${prefix}.ann
    touch bwa/${prefix}.bwt
    touch bwa/${prefix}.pac
    touch bwa/${prefix}.sa
    """
}