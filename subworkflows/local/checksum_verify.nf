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

def splitChecksumFile(f, batchsize) {
    lines = []
    f.eachLine { line, index ->
        def parts = line.split(/\s+/)
        lines.add([parts[0], parts[1], String.format('%06d', (index % batchsize) + 1)])
    }
    return lines.collate(batchsize)
}

def makeRenameScript(batch) {
    script = []
    script.add("#!/bin/bash -euo pipefail")
    script.add("mkdir -p work")
    batch.each { checksum, filename, index ->
        script.add("mkdir -p work/\$(dirname '${filename}') && mv files/${index} 'work/${filename}'")
    }
    return script.join("\n")
}

workflow CHECKSUM_VERIFY {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    // ch_samplesheet.view()
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_batches = ch_samplesheet.map{ meta, path, checksum_file ->
        splitChecksumFile(checksum_file, params.chunksize).withIndex().collect {
            chunk, index -> [meta, chunk]
        }
    }.flatMap { meta, chunk -> tuple(meta, chunk)}
    // ch_batches.view()
    ch_scripts = ch_batches.map{ meta, chunk -> [meta, makeRenameScript(chunk)] }
    // ch_scripts.view()
    ch_files = ch_batches.join(ch_samplesheet).map{ meta, chunk, path, checksum_file ->
        [meta, chunk.collect{ checksum, filename, idx -> file("${path}/${filename}")}]
    }
    ch_files.view()
    // ch_files = ch_batches.map{
    //     meta, path, chunk -> chunk.each{
    //         checksum, filename, numeric_id ->
    //             files = []
    //             files.add(file("${path}/${filename}", checkIfExists:true))
    //     }
    // }
    // ch_files.view()
    // SHA256SUM_CHECK([[:], ["foo/test.txt", "foo/bar.txt"], [file("foo/test.txt"), file("foo/bar.txt")], []])

    emit:
    versions      = ch_versions                 // channel: [ path(versions.yml) ]
    multiqc_files = ch_multiqc_files

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
