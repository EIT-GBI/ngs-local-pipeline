process ALIGNMENT_BWA {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)
    path(ref_genome)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.alignment.log"), emit: log
    tuple val("${task.process}"), val('bwa'), eval('bwa --version 2>&1 | sed -e "s/bwa //g"'), emit: versions_bwa, topic: versions
    tuple val("${task.process}"), val('samtools'), eval('samtools --version 2>&1 | sed -e "s/samtools //g"'), emit: versions_samtools, topic: versions


    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bwa mem -t $task.cpu \
    $ref_genome ${reads[0]} ${reads[1]} 2>>${prefix}.alignment.log \
  | samtools view -@ $task.cpu -bS - 2>>${prefix}.alignment.log \
  | samtools sort -@ $task.cpu \
       -o ${prefix}.sorted.bam - >>${prefix}.alignment.log 2>&1
    samtools index -@ $task.cpu ${prefix}.sorted.bam >>${prefix}.alignment.log 2>&1
    """
}