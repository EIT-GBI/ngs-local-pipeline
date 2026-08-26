process PARSE_ALIGNMENT_LOG {
    tag "${meta.id}"

    input:
    tuple val(meta), path(alignment_log)

    output:
    path "*_bwa_mqc.tsv", emit: mqc

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Sum all reads processed across batches
    total_reads=\$(awk '/mem_process_seqs.*Processed/ {sum += \$3} END {print sum+0}' "${alignment_log}")

    # Real and CPU time from the [main] summary line
    real_time=\$(grep '\\[main\\] Real time' "${alignment_log}" | sed 's/.*Real time: //; s/ sec.*//')
    cpu_time=\$(grep '\\[main\\] Real time' "${alignment_log}" | sed 's/.*CPU: //; s/ sec.*//')

    # FR insert size stats: extract block between "orientation FR" and the next "orientation XX"
    fr_block=\$(awk '/orientation FR/{fr=1; next} /orientation [A-Z][A-Z]/{fr=0} fr' "${alignment_log}")

    insert_median=\$(echo "\${fr_block}" | awk '/percentile:/{gsub(/.*\\(/, ""); split(\$0, a, ","); gsub(/ /, "", a[2]); print a[2]+0; exit}')
    insert_mean=\$(echo "\${fr_block}"   | awk '/mean and std/{gsub(/.*\\(/, ""); sub(/,.*/, ""); print \$0+0; exit}')
    insert_std=\$(echo "\${fr_block}"    | awk '/mean and std/{gsub(/.*,[ ]*/, ""); sub(/\\).*/, ""); print \$0+0; exit}')

    # Fall back to NA if any value is empty (e.g. failed run)
    total_reads=\${total_reads:-NA}
    real_time=\${real_time:-NA}
    cpu_time=\${cpu_time:-NA}
    insert_mean=\${insert_mean:-NA}
    insert_std=\${insert_std:-NA}
    insert_median=\${insert_median:-NA}

    printf '# id: '"'"'bwa_alignment_stats'"'"'\\n'                                                    >  "${prefix}_bwa_mqc.tsv"
    printf '# section_name: '"'"'BWA Alignment Statistics'"'"'\\n'                                    >> "${prefix}_bwa_mqc.tsv"
    printf '# description: '"'"'Key metrics from BWA mem logs. Insert size statistics are for FR (forward-reverse) pairs.'"'"'\\n' >> "${prefix}_bwa_mqc.tsv"
    printf '# plot_type: '"'"'table'"'"'\\n'                                                          >> "${prefix}_bwa_mqc.tsv"
    printf '# pconfig:\\n'                                                                             >> "${prefix}_bwa_mqc.tsv"
    printf '#     id: '"'"'bwa_alignment_table'"'"'\\n'                                               >> "${prefix}_bwa_mqc.tsv"
    printf '#     title: '"'"'BWA Alignment Stats'"'"'\\n'                                            >> "${prefix}_bwa_mqc.tsv"
    printf '# headers:\\n'                                                                             >> "${prefix}_bwa_mqc.tsv"
    printf '#     reads_processed:\\n'                                                                 >> "${prefix}_bwa_mqc.tsv"
    printf '#         title: '"'"'Reads Processed'"'"'\\n'                                            >> "${prefix}_bwa_mqc.tsv"
    printf '#         format: '"'"'{:,.0f}'"'"'\\n'                                                   >> "${prefix}_bwa_mqc.tsv"
    printf '#         scale: '"'"'Blues'"'"'\\n'                                                      >> "${prefix}_bwa_mqc.tsv"
    printf '#     real_time_s:\\n'                                                                     >> "${prefix}_bwa_mqc.tsv"
    printf '#         title: '"'"'Real Time (s)'"'"'\\n'                                              >> "${prefix}_bwa_mqc.tsv"
    printf '#         suffix: '"'"' s'"'"'\\n'                                                        >> "${prefix}_bwa_mqc.tsv"
    printf '#     cpu_time_s:\\n'                                                                      >> "${prefix}_bwa_mqc.tsv"
    printf '#         title: '"'"'CPU Time (s)'"'"'\\n'                                               >> "${prefix}_bwa_mqc.tsv"
    printf '#         suffix: '"'"' s'"'"'\\n'                                                        >> "${prefix}_bwa_mqc.tsv"
    printf '#     insert_mean:\\n'                                                                     >> "${prefix}_bwa_mqc.tsv"
    printf '#         title: '"'"'Insert Mean (bp)'"'"'\\n'                                           >> "${prefix}_bwa_mqc.tsv"
    printf '#         suffix: '"'"' bp'"'"'\\n'                                                       >> "${prefix}_bwa_mqc.tsv"
    printf '#         scale: '"'"'Greens'"'"'\\n'                                                     >> "${prefix}_bwa_mqc.tsv"
    printf '#     insert_std:\\n'                                                                      >> "${prefix}_bwa_mqc.tsv"
    printf '#         title: '"'"'Insert Std Dev (bp)'"'"'\\n'                                        >> "${prefix}_bwa_mqc.tsv"
    printf '#         suffix: '"'"' bp'"'"'\\n'                                                       >> "${prefix}_bwa_mqc.tsv"
    printf '#     insert_median:\\n'                                                                   >> "${prefix}_bwa_mqc.tsv"
    printf '#         title: '"'"'Insert Median (bp)'"'"'\\n'                                         >> "${prefix}_bwa_mqc.tsv"
    printf '#         suffix: '"'"' bp'"'"'\\n'                                                       >> "${prefix}_bwa_mqc.tsv"
    printf '#         scale: '"'"'Greens'"'"'\\n'                                                     >> "${prefix}_bwa_mqc.tsv"
    printf 'Sample\\treads_processed\\treal_time_s\\tcpu_time_s\\tinsert_mean\\tinsert_std\\tinsert_median\\n' >> "${prefix}_bwa_mqc.tsv"
    printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \\
        "${prefix}" \\
        "\${total_reads}" \\
        "\${real_time}" \\
        "\${cpu_time}" \\
        "\${insert_mean}" \\
        "\${insert_std}" \\
        "\${insert_median}" >> "${prefix}_bwa_mqc.tsv"
    """
}
