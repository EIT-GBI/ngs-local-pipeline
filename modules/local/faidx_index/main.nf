process FAIDX_INDEX {
    tag "${ref_genome.baseName}"
    label 'samtools'

    input:
    path ref_genome

    output:
    tuple path(ref_genome), path("${ref_genome}.fai"), emit: index
    tuple val("${task.process}"), val('samtools'), eval('samtools 2>&1 | sed -n "s/^Version: //p"'), topic: versions, emit: versions_samtools

    script:
    """
    samtools faidx $ref_genome
    """
}
