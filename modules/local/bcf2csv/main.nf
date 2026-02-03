process BCF2CSV {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bcf), path(bcf_index)

    output:
    tuple val(meta), path("*.calls.csv"), emit: csv
    tuple val("${task.process}"), val('bcftools'), eval('bcftools --version 2>&1 | sed -e "s/bcftools //g"'), emit: versions_bcftools, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bcftools query \
    -f '%CHROM,%POS,%REF,%ALT,%DP,[%AD],%QUAL,%FILTER\n' \
    ${bcf} > ${prefix}.calls.csv
    sed -i.bak '1i\
    CHROM,POS,REF,ALT,DP,AD(ref,alt),QUAL,FILTER
    ' ${prefix}.calls.csv
    """

}