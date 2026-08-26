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

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.sorted.bam ${prefix}.sorted.bam.bai
    # A realistic BWA mem log, not an empty file: PARSE_ALIGNMENT_LOG has no stub
    # of its own (it is pure awk/sed), so under `-stub-run` it parses this for
    # real — which is what keeps its regexes honest.
    cat > ${prefix}.alignment.log <<'LOG'
[M::mem_process_seqs] Processed 20000 reads in 1.234 CPU sec, 0.567 real sec
[M::mem_pestat] analyzing insert size distribution for orientation FR...
[M::mem_pestat] (25, 50, 75) percentile: (180, 250, 320)
[M::mem_pestat] mean and std.dev: (251.30, 45.20)
[M::mem_pestat] analyzing insert size distribution for orientation RF...
[main] Real time: 0.600 sec; CPU: 1.300 sec
LOG
    """
}
