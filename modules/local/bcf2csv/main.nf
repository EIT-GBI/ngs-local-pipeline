process BCF2CSV {
    tag "${meta.id}"
    label 'bcftools'

    input:
    tuple val(meta), path(bcf), path(bcf_index)

    output:
    tuple val(meta), path("*.calls.csv"), emit: csv
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version | head -1 | sed "s/bcftools //"'), emit: versions_bcftools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools query \
    -f '%CHROM,%POS,%REF,%ALT,%DP,[%AD],%QUAL,%FILTER\n' \
    ${bcf} > ${prefix}.calls.csv
    {
        printf 'CHROM,POS,REF,ALT,DP,AD(ref,alt),QUAL,FILTER\n'
        cat ${prefix}.calls.csv
    } > ${prefix}.calls.csv.tmp
    mv ${prefix}.calls.csv.tmp ${prefix}.calls.csv
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    printf 'CHROM,POS,REF,ALT,DP,AD(ref,alt),QUAL,FILTER\n' > ${prefix}.calls.csv
    """
}
