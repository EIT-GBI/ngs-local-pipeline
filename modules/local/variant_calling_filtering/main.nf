process VARIANT_CALLING_FILTERING {
    tag "${meta.id}"
    label 'bcftools'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(ref_genome), path("${ref_genome}.fai")
    val min_qmap
    val min_depth
    val min_qual

    output:
    tuple val(meta), path("*.calls.bcf"), path("*.calls.bcf.csi"), emit: bcf_out
    tuple val(meta), path("*.variantcalling.log"), emit: bcf_log
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version 2>&1 | sed -e "s/bcftools //g"'), emit: versions_bcftools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools mpileup \
        -Ou \
        -f ${ref_genome} \
        -q "${min_qmap}" \
        -a AD,DP \
        ${bam} 2>>${prefix}.variantcalling.log \
    | bcftools call \
        --ploidy 1 \
        -mv \
        -Ou 2>>${prefix}.variantcalling.log \
    | bcftools filter \
        -e "FMT/DP<${min_depth} || QUAL<${min_qual}" \
        -Ob \
        -o ${prefix}.calls.bcf 2>>${prefix}.variantcalling.log

    bcftools index ${prefix}.calls.bcf >>${prefix}.variantcalling.log 2>&1
    """
}
