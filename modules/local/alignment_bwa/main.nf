process ALIGNMENT_BWA {
    tag "${meta.id}"
    label 'process_high'
    label 'bwa_samtools'

    input:
    tuple val(meta), path(reads)
    tuple path(ref_genome), path("bwa_index")

    output:
    tuple val(meta), path("*.bam"), path("*.bam.bai"), emit: bam_bai
    tuple val(meta), path("*.alignment.log"), emit: log
    tuple val("${task.process}"), val('bwa'), eval('bwa 2>&1 | sed -n "s/^Version: //p"'), emit: versions_bwa, topic: versions
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | sed "s/samtools //"'), emit: versions_samtools, topic: versions


    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bwa_index_prefix = ref_genome.baseName
    """
    bwa mem -t $task.cpus \
    bwa_index/${bwa_index_prefix} ${reads[0]} ${reads[1]} 2>>${prefix}.alignment.log \
  | samtools view -@ $task.cpus -bS - 2>>${prefix}.alignment.log \
  | samtools sort -@ $task.cpus \
       -o ${prefix}.sorted.bam - >>${prefix}.alignment.log 2>&1
    samtools index -@ $task.cpus ${prefix}.sorted.bam >>${prefix}.alignment.log 2>&1
    """
}
