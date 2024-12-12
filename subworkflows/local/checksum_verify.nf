/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SHA256SUM_CHECK } from "../../modules/local/sha256sum/main"
include { MULTIQC                } from '../../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../local/utils_nfcore_datasync_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow CHECKSUM_VERIFY {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    // ch_samplesheet.view()
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_chunks = ch_samplesheet.flatMap { meta, path, checksum_file ->
        checksum_file.splitText( by: params.chunksize, file: true).collect{ it -> [meta, path, it]}
    }
    SHA256SUM_CHECK(ch_chunks)

    // collate reports from chunks
    SHA256SUM_CHECK.out.report.collectFile(storeDir: "${params.outdir}/reports"){ meta, report -> ["${meta.id}.report.txt", report]}

    // check if verification was sucessful (= all processes exited with code 0)
    exit_codes = SHA256SUM_CHECK.out.exit_code.groupTuple().map{ meta, exit_codes -> [meta, exit_codes.every{ it == "0" }] }.map{
        meta, status -> if(!status) {
            log.warn("Checksum verifycation failed for ${meta.id}!")
        }
    }


    emit:
    versions      = ch_versions                 // channel: [ path(versions.yml) ]
    multiqc_files = ch_multiqc_files

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
