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

workflow {
    // Reading samplesheet
    ch_samples = channel
    .fromPath(params.samplesheet)
    .splitCsv(header: true)
    .map { row ->
        def id = row.sample_id
        def ref_genome = row.ref_genome

        def r1 = file("${params.reads_dir}/${id}*_R1*.fastq.gz")
        def r2 = file("${params.reads_dir}/${id}*_R2*.fastq.gz")
        def ref = file("${params.ref_dir}/${ref_genome}")

        def meta = [
        id        : id,
        sample_id : id,
        ref_genome    : ref_genome
        ]

        tuple(meta, [r1, r2], ref)
    }

    // Separating reads from reference files for 
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
    // need to take care of index
    // BWA index
    BWA_INDEX(refs_unique_ch)

    // FAIDX index
    FAIDX_INDEX(refs_unique_ch)

    // FASTQC - Raw
    FASTQC_RAW(ch_reads)

    // Trimning - Fastp
    FASTP(ch_reads)

    // FASTQC - Trimmed
    FASTQC_TRIMMED(FASTP.out.reads)

    // Alignment BWA - with filtering, sorting and indexing
    ALIGNMENT_BWA(FASTP.out.reads)

    // Stats with Flagstat
    FLAGSTAT(ALIGNMENT_BWA.out.bam_bai)

    // Variant calling 
    VARIANT_CALLING_FILTERING(ALIGNMENT_BWA.out.bam_bai, ref_genome, params.min_qmap, params.min_depth, params.min_qual)

    // IGV-friendly VCF.gz (+tabix)
    BCF2VCF(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Legacy-friendly CSV
    BCF2CSV(VARIANT_CALLING_FILTERING.out.bcf_out)

    // Consensus FASTA
    BCF_CONSENSUS(VARIANT_CALLING_FILTERING.out.bcf_out)

    // MultiQC - probably need something specific for us

}

// Need index for bwa mem (bwt file). It is created using bwa index
// For bcftools consensus, we need the samtools faidx for indexing