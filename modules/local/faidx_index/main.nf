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

    stub:
    """
    # A real .fai: CHROM_SIZES has no stub (it is a plain `cut`) and consumes
    # this for real, so the seqid must come from the actual reference.
    seqid=\$(grep '^>' ${ref_genome} | head -1 | sed 's/^>//; s/[[:space:]].*//')
    printf '%s\t1000\t%s\t60\t61\n' "\${seqid:-stub_chr}" "\$(( \${#seqid} + 2 ))" > ${ref_genome}.fai
    """
}
