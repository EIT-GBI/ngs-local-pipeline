include { FASTQC as FASTQC_RAW } from './modules/local/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/local/fastqc'
include { FASTP } from './modules/local/fastp'
include { ALIGNMENT_BWA } from './modules/local/alignment_bwa'
include { FLAGSTAT } from './modules/local/flagstat'
include { VARIANT_CALLING_FILTERING } from './modules/local/variant_calling_filtering'
include { BCF2VCF } from './modules/local/bcf2vcf'
include { BCF2CSV } from './modules/local/bcf2csv'
include { BCF_CONSENSUS } from './modules/local/bcf_consensus'
include { BWA_INDEX } from './modules/local/bwa_index'
include { FAIDX_INDEX } from './modules/local/faidx_index'
include { SAMTOOLS_STATS } from './modules/local/samtools_stats'
include { SAMTOOLS_COVERAGE } from './modules/local/samtools_coverage'
include { BCFTOOLS_STATS } from './modules/local/bcftools_stats'
include { MULTIQC } from './modules/local/multiqc'
include { PARSE_ALIGNMENT_LOG } from './modules/local/parse_alignment_log'
include { COLLECT_VERSIONS } from './modules/local/collect_versions'

workflow {
    main:
    // Reading samplesheet
    ch_samples = channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
        def id = row.sample_id
        def ref_genome = row.ref_genome

        def r1 = files("${params.reads_dir}/${id}*_R1*.fastq.gz", checkIfExists: true)
        def r2 = files("${params.reads_dir}/${id}*_R2*.fastq.gz", checkIfExists: true)
        def ref = file("${params.ref_dir}/${ref_genome}", checkIfExists: true)

        if( r1.size() != 1 || r2.size() != 1 ) {
            throw new IllegalArgumentException("Expected exactly one R1 and one R2 FASTQ for sample `${id}` but found ${r1.size()} R1 and ${r2.size()} R2 files")
        }

        def meta = [
            id         : id,
            sample_id  : id,
            ref_genome : ref_genome
        ]

        tuple(meta, [r1.first(), r2.first()], ref)
    }

    // Separating reads from reference files
    ch_reads = ch_samples.map { meta, reads, _ref ->
        tuple(meta, reads)
    }

    ch_refs = ch_samples.map { meta, _reads, ref ->
        tuple(meta, ref)
    }

    // Making a channel with unique reference files (in case several samples have the same ref)
    refs_unique_ch = ch_refs
        .map { _meta, ref -> ref }
        .unique()

    // BWA index
    BWA_INDEX(refs_unique_ch)
    ch_bwa_index = BWA_INDEX.out.index
        .map { ref, bwa_index -> tuple(ref.getFileName().toString(), ref, bwa_index) }

    // FAIDX index
    FAIDX_INDEX(refs_unique_ch)
    ch_faidx_ref = FAIDX_INDEX.out.index
        .map { ref, fai -> tuple(ref.getFileName().toString(), ref, fai) }

    // FASTQC - Raw
    FASTQC_RAW(ch_reads)

    // Trimming - Fastp
    FASTP(ch_reads)

    // FASTQC - Trimmed
    FASTQC_TRIMMED(FASTP.out.reads)

    // Alignment BWA - with filtering, sorting and indexing
    ch_alignment = FASTP.out.reads
        .map { meta, reads -> tuple(meta.ref_genome, meta, reads) }
        .combine(ch_bwa_index, by: 0)

    ALIGNMENT_BWA(
        ch_alignment.map { _ref_name, meta, reads, _ref, _bwa_index -> tuple(meta, reads) },
        ch_alignment.map { _ref_name, _meta, _reads, ref, bwa_index -> tuple(ref, bwa_index) }
    )

    // Stats with Flagstat
    FLAGSTAT(ALIGNMENT_BWA.out.bam_bai)

    // Samtools stats and coverage
    SAMTOOLS_STATS(ALIGNMENT_BWA.out.bam_bai)
    SAMTOOLS_COVERAGE(ALIGNMENT_BWA.out.bam_bai)

    // Variant calling
    ch_variant_calling = ALIGNMENT_BWA.out.bam_bai
        .map { meta, bam, bai -> tuple(meta.ref_genome, meta, bam, bai) }
        .combine(ch_faidx_ref, by: 0)

    VARIANT_CALLING_FILTERING(
        ch_variant_calling.map { _ref_name, meta, bam, bai, _ref, _fai -> tuple(meta, bam, bai) },
        ch_variant_calling.map { _ref_name, _meta, _bam, _bai, ref, fai -> tuple(ref, fai) },
        params.min_qmap,
        params.min_depth,
        params.min_qual
    )

    // IGV-friendly VCF.gz (+tabix)
    BCF2VCF(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Legacy-friendly CSV
    BCF2CSV(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Variant stats
    BCFTOOLS_STATS(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Consensus FASTA
    ch_consensus = VARIANT_CALLING_FILTERING.out.bcf_out
        .map { meta, bcf, bcf_index -> tuple(meta.ref_genome, meta, bcf, bcf_index) }
        .combine(ch_faidx_ref, by: 0)

    BCF_CONSENSUS(
        ch_consensus.map { _ref_name, meta, bcf, bcf_index, _ref, _fai -> tuple(meta, bcf, bcf_index) },
        ch_consensus.map { _ref_name, _meta, _bcf, _bcf_index, ref, fai -> tuple(ref, fai) }
    )

    // MultiQC
    ch_multiqc_config = file("${projectDir}/assets/multiqc_config.yaml")

    PARSE_ALIGNMENT_LOG(ALIGNMENT_BWA.out.log)

    ch_multiqc_files = channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.collect             { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.collect         { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect                  { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FLAGSTAT.out[0].collect                 { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(SAMTOOLS_STATS.out.stats.collect       { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(SAMTOOLS_COVERAGE.out.coverage.collect { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(BCFTOOLS_STATS.out.stats.collect       { _meta, files -> files }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(PARSE_ALIGNMENT_LOG.out.mqc.collect()               .ifEmpty([]))

    // Collect software versions from all upstream processes (not MULTIQC, to avoid deadlock)
    // Map each tuple to "tool\tversion" string to prevent .collect() from flattening tuples
    ch_versions = FASTQC_RAW.out.versions_fastqc.first()
        .mix(FASTP.out.versions_fastp.first())
        .mix(ALIGNMENT_BWA.out.versions_bwa.first())
        .mix(ALIGNMENT_BWA.out.versions_samtools.first())
        .mix(FLAGSTAT.out.versions_samtools.first())
        .mix(VARIANT_CALLING_FILTERING.out.versions_bcftools.first())
        .mix(BCF2VCF.out.versions_tabix.first())
        .map { _process_name, tool, version -> "${tool}\t${version}" }
        .collect()
    COLLECT_VERSIONS(ch_versions)
    ch_multiqc_files = ch_multiqc_files.mix(COLLECT_VERSIONS.out.mqc)

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config
    )

    publish:
    ch_fastqc_raw       = FASTQC_RAW.out.html.mix(FASTQC_RAW.out.zip)
    ch_fastqc_trimmed   = FASTQC_TRIMMED.out.html.mix(FASTQC_TRIMMED.out.zip)
    ch_fastp_qc         = FASTP.out.json.mix(FASTP.out.html).mix(FASTP.out.log)
    ch_bam              = ALIGNMENT_BWA.out.bam_bai
    ch_alignment_log    = ALIGNMENT_BWA.out.log
    ch_flagstat         = FLAGSTAT.out[0]
    ch_bcf              = VARIANT_CALLING_FILTERING.out.bcf_out
    ch_bcf_log          = VARIANT_CALLING_FILTERING.out.bcf_log
    ch_vcf              = BCF2VCF.out.vcf
    ch_csv              = BCF2CSV.out.csv
    ch_samtools_stats    = SAMTOOLS_STATS.out.stats
    ch_samtools_coverage = SAMTOOLS_COVERAGE.out.coverage
    ch_bcftools_stats    = BCFTOOLS_STATS.out.stats
    ch_consensus         = BCF_CONSENSUS.out.consensus
    ch_multiqc_report    = MULTIQC.out.report
    ch_multiqc_data     = MULTIQC.out.data

}

output {
    ch_fastqc_raw {
        path 'qc/fastqc/raw/'
    }
    ch_fastqc_trimmed {
        path 'qc/fastqc/trimmed/'
    }
    ch_fastp_qc {
        path 'qc/fastp/'
    }
    ch_bam {
        path 'alignment/'
    }
    ch_alignment_log {
        path 'logs/alignment/'
    }
    ch_flagstat {
        path 'qc/flagstat/'
    }
    ch_bcf {
        path 'variants/bcf/'
    }
    ch_bcf_log {
        path 'logs/variant_calling/'
    }
    ch_vcf {
        path 'variants/vcf/'
    }
    ch_csv {
        path 'variants/csv/'
    }
    ch_samtools_stats {
        path 'qc/samtools_stats/'
    }
    ch_samtools_coverage {
        path 'qc/samtools_coverage/'
    }
    ch_bcftools_stats {
        path 'qc/bcftools_stats/'
    }
    ch_consensus {
        path 'consensus/'
    }
    ch_multiqc_report {
        path 'qc/multiqc/'
    }
    ch_multiqc_data {
        path 'qc/multiqc/'
    }
}