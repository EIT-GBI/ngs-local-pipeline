process COLLECT_VERSIONS {

    input:
    val versions

    output:
    path "software_versions_mqc.yaml", emit: mqc

    exec:
    // versions is a list of "tool\tversion" strings
    def seen = [:]
    versions.each { entry ->
        def parts = entry.toString().split('\t')
        def tool = parts[0]
        // Take only the first line of the version string (some tools output multi-line info)
        def ver  = parts.size() > 1 ? parts[1]?.trim()?.readLines()?.first()?.trim() : null
        if (tool && ver && !seen.containsKey(tool)) {
            seen[tool] = ver
        }
    }

    // Add Nextflow version
    seen['Nextflow'] = nextflow.version

    // Build MultiQC custom content YAML as a table
    def yaml = []
    yaml << "id: 'software_versions'"
    yaml << "section_name: 'Software Versions'"
    yaml << "description: 'Software versions used in this pipeline run.'"
    yaml << "plot_type: 'table'"
    yaml << "pconfig:"
    yaml << "    id: 'software_versions_table'"
    yaml << "    namespace: 'Software Versions'"
    yaml << "data:"
    seen.sort().each { tool, ver ->
        yaml << "    ${tool}:"
        yaml << "        Version: '${ver}'"
    }

    task.workDir.resolve("software_versions_mqc.yaml").text = yaml.join("\n") + "\n"
}
