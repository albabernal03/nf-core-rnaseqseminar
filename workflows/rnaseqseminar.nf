/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { TRIMGALORE             } from '../modules/nf-core/trimgalore/main'
include { STAR_ALIGN             } from '../modules/nf-core/star/align/main'
include { SALMON_QUANT           } from '../modules/nf-core/salmon/quant/main'
include { DUPRADAR               } from '../modules/nf-core/dupradar/main'
include { QUALIMAP_RNASEQ        } from '../modules/nf-core/qualimap/rnaseq/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_rnaseqseminar_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow RNASEQSEMINAR {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:
    ch_versions      = Channel.empty()
    ch_multiqc_files = Channel.empty()

    // Reference file channels
    ch_star_index    = Channel.value(file(params.star_index))
    ch_salmon_index  = Channel.value(file(params.salmon_index))
    ch_gtf           = Channel.value(file(params.gtf))
    ch_transcriptome = Channel.value(file(params.transcriptome))

    //
    // MODULE: FASTQC
    //
    FASTQC(ch_samplesheet)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions      = ch_versions.mix(FASTQC.out.versions.first())

    //
    // MODULE: TRIMGALORE
    //
    TRIMGALORE(ch_samplesheet)
    ch_multiqc_files = ch_multiqc_files.mix(TRIMGALORE.out.zip.collect{it[1]})
    ch_versions      = ch_versions.mix(TRIMGALORE.out.versions.first())

    //
    // MODULE: STAR_ALIGN
    //
    STAR_ALIGN(
        TRIMGALORE.out.reads,
        ch_star_index,
        ch_gtf,
        false,
        '',
        ''
    )
    ch_multiqc_files = ch_multiqc_files.mix(STAR_ALIGN.out.log_final.collect{it[1]})
    ch_versions      = ch_versions.mix(STAR_ALIGN.out.versions.first())

    //
    // MODULE: SALMON_QUANT
    //
    SALMON_QUANT(
        TRIMGALORE.out.reads,
        ch_salmon_index,
        ch_gtf,
        ch_transcriptome,
        false,
        'A'
    )
    ch_versions = ch_versions.mix(SALMON_QUANT.out.versions.first())

    //
    // MODULE: DUPRADAR
    //
    DUPRADAR(
        STAR_ALIGN.out.bam,
        ch_gtf
    )
    ch_multiqc_files = ch_multiqc_files.mix(DUPRADAR.out.multiqc.collect{it[1]})

    //
    // MODULE: QUALIMAP_RNASEQ
    //
    QUALIMAP_RNASEQ(
        STAR_ALIGN.out.bam,
        ch_gtf
    )

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'rnaseqseminar_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MULTIQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList()
    versions       = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/