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
include { MULTIQC } from './modules/local/multiqc'
include { PARSE_ALIGNMENT_LOG } from './modules/local/parse_alignment_log'

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
    ch_reads = ch_samples.map { meta, reads, ref ->
        tuple(meta, reads)
    }

    ch_refs = ch_samples.map { meta, reads, ref ->
        tuple(meta, ref)
    }

    // Making a channel with unique reference files (in case several samples have the same ref)
    refs_unique_ch = ch_refs
    .map { meta, ref -> ref }
    .unique()

    ch_sample_reads_by_ref = ch_samples.map { meta, reads, ref ->
        tuple(meta.ref_genome, meta, reads)
    }

    // need to take care of index
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

    // Trimning - Fastp
    FASTP(ch_reads)

    // FASTQC - Trimmed
    FASTQC_TRIMMED(FASTP.out.reads)

    // Alignment BWA - with filtering, sorting and indexing
    ch_alignment = FASTP.out.reads
        .map { meta, reads -> tuple(meta.ref_genome, meta, reads) }
        .join(ch_bwa_index)

    ALIGNMENT_BWA(
        ch_alignment.map { ref_name, meta, reads, ref, bwa_index -> tuple(meta, reads) },
        ch_alignment.map { ref_name, meta, reads, ref, bwa_index -> tuple(ref, bwa_index) }
    )

    // Stats with Flagstat
    FLAGSTAT(ALIGNMENT_BWA.out.bam_bai)

    // Variant calling
    ch_variant_calling = ALIGNMENT_BWA.out.bam_bai
        .map { meta, bam, bai -> tuple(meta.ref_genome, meta, bam, bai) }
        .join(ch_faidx_ref)

    VARIANT_CALLING_FILTERING(
        ch_variant_calling.map { ref_name, meta, bam, bai, ref, fai -> tuple(meta, bam, bai) },
        ch_variant_calling.map { ref_name, meta, bam, bai, ref, fai -> tuple(ref, fai) },
        params.min_qmap,
        params.min_depth,
        params.min_qual
    )

    // IGV-friendly VCF.gz (+tabix)
    BCF2VCF(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Legacy-friendly CSV
    BCF2CSV(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Consensus FASTA
    ch_consensus = VARIANT_CALLING_FILTERING.out.bcf_out
        .map { meta, bcf, bcf_index -> tuple(meta.ref_genome, meta, bcf, bcf_index) }
        .join(ch_faidx_ref)

    BCF_CONSENSUS(
        ch_consensus.map { ref_name, meta, bcf, bcf_index, ref, fai -> tuple(meta, bcf, bcf_index) },
        ch_consensus.map { ref_name, meta, bcf, bcf_index, ref, fai -> tuple(ref, fai) }
    )

    // MultiQC
    ch_multiqc_config = file("${projectDir}/assets/multiqc_config.yaml")

    PARSE_ALIGNMENT_LOG(ALIGNMENT_BWA.out.log)

    ch_multiqc_files = channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_RAW.out.zip.collect             { it[1] }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.collect         { it[1] }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect                  { it[1] }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FLAGSTAT.out[0].collect                 { it[1] }.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(PARSE_ALIGNMENT_LOG.out.mqc.collect()               .ifEmpty([]))

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
    ch_consensus        = BCF_CONSENSUS.out.consensus
    ch_multiqc_report   = MULTIQC.out.report
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

// Need index for bwa mem (bwt file). It is created using bwa index
// For bcftools consensus, we need the samtools faidx for indexing
