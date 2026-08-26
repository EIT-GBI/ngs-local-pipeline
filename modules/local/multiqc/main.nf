process MULTIQC {
    label 'process_single'
    label 'multiqc'

    input:
    path multiqc_files, stageAs: "?/*"
    path multiqc_config, stageAs: "?/*"
    // Renames the report. Empty (the standalone default) leaves MultiQC's own
    // `multiqc_report.html`. A parent pipeline that includes this workflow more
    // than once must pass a distinct value per instance — two invocations
    // otherwise emit the same basename and collide when a downstream process
    // stages both. It is an input rather than `ext.prefix` because a config
    // selector for a process that only exists in one of the caller's modes warns
    // on every run of the other mode.
    val report_prefix

    output:
    path "*multiqc_report.html", emit: report
    path "*_data",               emit: data
    path "*_plots",              emit: plots, optional: true
    tuple val("${task.process}"), val('multiqc'), eval('multiqc --version | sed "s/.* //g"'), emit: versions_multiqc, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def config = multiqc_config ? "--config ${multiqc_config}" : ''
    def rename = report_prefix ? "--filename ${report_prefix}_multiqc_report.html" : ''
    """
    multiqc \\
        --force \\
        ${args} \\
        ${rename} \\
        ${config} \\
        .
    """

    stub:
    def report = report_prefix ? "${report_prefix}_multiqc_report.html" : 'multiqc_report.html'
    def data   = report - '.html'
    """
    touch ${report}
    mkdir -p ${data}_data
    echo "stub" > ${data}_data/multiqc.log
    """
}
