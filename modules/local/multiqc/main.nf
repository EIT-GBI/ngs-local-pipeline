process MULTIQC {
    label 'process_single'
    label 'multiqc'

    input:
    path multiqc_files, stageAs: "?/*"
    path multiqc_config, stageAs: "?/*"

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
    """
    multiqc \\
        --force \\
        ${args} \\
        ${config} \\
        .
    """
}
