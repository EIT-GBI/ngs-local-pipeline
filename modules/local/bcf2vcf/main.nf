process BCF2VCF {
    tag "${meta.id}"
    label 'bcftools'

    input:
    tuple val(meta), path(bcf), path(bcf_index)

    output:
    tuple val(meta), path("*calls.vcf.gz"), path("*calls.vcf.gz.tbi"), emit: vcf
    tuple val(meta), path("*.vcf.log"), emit: cvf_log
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version | head -1 | sed "s/bcftools //"'), emit: versions_bcftools, topic: versions
    tuple val("${task.process}"), val('tabix'), eval('tabix --version 2>&1 | head -1 | sed "s/tabix //"'), emit: versions_tabix, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools view -Oz -o ${prefix}.calls.vcf.gz ${bcf} >>${prefix}.vcf.log 2>&1
    tabix -p vcf ${prefix}.calls.vcf.gz >>${prefix}.vcf.log 2>&1
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.calls.vcf.gz ${prefix}.calls.vcf.gz.tbi
    echo "stub" > ${prefix}.vcf.log
    """
}
