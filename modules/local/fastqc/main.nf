process FASTQC {
    tag "${meta.id}"
    label 'process_high'
    label 'process_medium'
    label 'fastqc'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta)             , path("*.html")                                                       , emit: html
    tuple val(meta)             , path("*.zip")                                                        , emit: zip
    tuple val("${task.process}"), val('fastqc'), eval('fastqc --version | sed "/FastQC v/!d; s/.*v//"'), emit: versions_fastqc, topic: versions

    script:
    def args          = task.ext.args ?: ''
    // The total amount of allocated RAM by FastQC is equal to the number of threads defined (--threads) time the amount of RAM defined (--memory)
    // https://github.com/s-andrews/FastQC/blob/1faeea0412093224d7f6a07f777fad60a5650795/fastqc#L211-L222
    // Dividing the task.memory by task.cpu allows to stick to requested amount of RAM in the label
    def memory_in_mb = task.memory ? task.memory.toUnit('MB') / task.cpus : null
    // FastQC memory value allowed range (100 - 10000)
    def fastqc_memory = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)

    """
    # Keep the JVM's temp/perfdata off the container's small /tmp (avoids SIGBUS
    # under Apptainer on HPC); use the task work dir, which has space.
    export TMPDIR="\$PWD/tmp"
    mkdir -p "\$TMPDIR"
    export _JAVA_OPTIONS="-Djava.io.tmpdir=\$TMPDIR -XX:-UsePerfData"

    fastqc \\
        ${args} \\
        --dir "\$TMPDIR" \\
        --threads ${task.cpus} \\
        --memory ${fastqc_memory} \\
        ${reads}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_R1_fastqc.html ${prefix}_R1_fastqc.zip
    touch ${prefix}_R2_fastqc.html ${prefix}_R2_fastqc.zip
    """
}
