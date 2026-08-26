// Entry point for a standalone run of the NGS pipeline.
//
// This file is deliberately thin: it is the ONLY place that reads `params.*`,
// and it hands every setting to the named `NGS` workflow as an argument. That
// split is what lets another pipeline include `NGS` — twice, even, with
// different inputs — without params collisions. See workflows/ngs/main.nf.
//
// Publishing stays here, in the entry workflow: `publish:` and the `output {}`
// block below are only honoured for the entry point, so a parent pipeline that
// includes `NGS` must declare its own targets from `NGS.out.*`.

include { NGS } from './workflows/ngs'

workflow {
    main:
    NGS(
        params.samplesheet,
        params.reads_dir,
        params.ref_dir,
        params.min_qmap,
        params.min_depth,
        params.min_qual
    )

    publish:
    ch_fastqc_raw           = NGS.out.fastqc_raw
    ch_fastqc_trimmed       = NGS.out.fastqc_trimmed
    ch_fastp_qc             = NGS.out.fastp_qc
    ch_bam                  = NGS.out.bam
    ch_alignment_log        = NGS.out.alignment_log
    ch_flagstat             = NGS.out.flagstat
    ch_bcf                  = NGS.out.bcf
    ch_bcf_log              = NGS.out.bcf_log
    ch_vcf                  = NGS.out.vcf
    ch_csv                  = NGS.out.csv
    ch_samtools_stats       = NGS.out.samtools_stats
    ch_samtools_coverage    = NGS.out.samtools_coverage
    ch_bcftools_stats       = NGS.out.bcftools_stats
    ch_bigwig               = NGS.out.bigwig
    ch_consensus            = NGS.out.consensus
    ch_multiqc_report       = NGS.out.multiqc_report
    ch_multiqc_data         = NGS.out.multiqc_data
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
    ch_bigwig {
        path 'bigwig/'
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
