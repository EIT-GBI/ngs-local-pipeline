process BCF2VCF {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bcf), path(bcf_index)

    output:
    tuple val(meta), path("*calls.vcf.gz"), emit: vcf
    tuple val(meta), path("*.vcf.log"), emit: cvf_log
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version 2>&1 | sed -e "s/bcftools //g"'), emit: versions_bcftools, topic: versions
    tuple val("${task.process}"), val('tabix'), eval('tabix --version 2>&1 | sed -e "s/tabix //g"'), emit: versions_tabix, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools view -Oz -o ${prefix}.calls.vcf.gz ${bcf} >>${prefix}.vcf.log 2>&1
    tabix -p vcf ${prefix}.calls.vcf.gz >>${prefix}.vcf.log 2>&1
    """
}