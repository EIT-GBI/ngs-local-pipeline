process FASTP {
    tag "${meta.id}"
    label 'process_medium'

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
    -in1 ${reads[0]} \\
    -in2 ${reads[1]} \\
    -o ${out_fq1} \\
    -O ${out_fq2} \\
    -h ${prefix}.fastp.html \\
    -j ${prefix}.fastp.json \\
    $args \\
    2> >(tee ${prefix}.fastp.log >&2)
    """
}