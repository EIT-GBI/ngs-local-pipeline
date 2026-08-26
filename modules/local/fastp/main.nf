process FASTP {
    tag "${meta.id}"
    label 'process_high'
    label 'process_medium'
    label 'fastp'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.trimmed.fastq.gz') , optional:true, emit: reads
    tuple val(meta), path('*.json')           , emit: json
    tuple val(meta), path('*.html')           , emit: html
    tuple val(meta), path('*.log')            , emit: log
    tuple val("${task.process}"), val('fastp'), eval('fastp --version 2>&1 | sed -e "s/fastp //g"'), emit: versions_fastp, topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def out_fq1 = "${prefix}_R1.trimmed.fastq.gz"
    def out_fq2 = "${prefix}_R2.trimmed.fastq.gz"
    """
    fastp \\
    -w $task.cpus \\
    -i ${reads[0]} \\
    -I ${reads[1]} \\
    -o ${out_fq1} \\
    -O ${out_fq2} \\
    -h ${prefix}.fastp.html \\
    -j ${prefix}.fastp.json \\
    $args \\
    2> >(tee ${prefix}.fastp.log >&2)
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo | gzip -c > ${prefix}_R1.trimmed.fastq.gz
    echo | gzip -c > ${prefix}_R2.trimmed.fastq.gz
    printf '{"summary":{"before_filtering":{"total_reads":20000},"after_filtering":{"total_reads":19500}}}\n' > ${prefix}.fastp.json
    touch ${prefix}.fastp.html
    echo "stub" > ${prefix}.fastp.log
    """
}
