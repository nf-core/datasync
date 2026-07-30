/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MULTIQC                                  } from '../modules/nf-core/multiqc/main'
include { RCLONE_COPY                              } from '../modules/nf-core/rclone/copy/main'
include { RCLONE_CHECK                             } from '../modules/nf-core/rclone/check/main'
include { RCLONE_CHECKSUM                          } from '../modules/nf-core/rclone/checksum/main'
include { paramsSummaryMap                         } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                   } from '../subworkflows/local/utils_nfcore_datasync_pipeline'
include { parseRcloneCheck                         } from '../subworkflows/local/utils_nfcore_datasync_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DATASYNC {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir
    rclone_config

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()
    ch_rclone_config = rclone_config ? file(rclone_config, checkIfExists: true) : []

    ch_samplesheet = ch_samplesheet.multiMap {
        meta, input_path, output_path, md5, sha ->

            def source = file(input_path)

            def source_uri = source.toUriString()

            def rclone_destination = source.isFile()
                ? output_path.toString().replaceAll('/+$', '')
                : "${output_path.toString().replaceAll('/+$', '')}/${source.name}"

            def rclone_check = source.isFile()
                ? input_path.replaceFirst('/[^/]+$', '')
                : input_path.toString().replaceAll('/+$', '')

            rclone:   [ meta, source_uri, rclone_destination ]
            checksum: [ meta, md5, sha, rclone_check ]
    }

    // Group input md5sum/shasum with their respective generated checksum
    ch_checksum = ch_samplesheet.checksum
        .flatMap { meta, md5, sha, input ->
            def checksum_tuple = []
            if (md5) {
                checksum_tuple << tuple(meta + [check_format: "md5"], md5, 'MD5', input)
            }
            if (sha) {
                checksum_tuple << tuple(meta + [check_format: "sha"], sha, "SHA256", input)
            }

            return checksum_tuple
        }

    RCLONE_CHECKSUM(
        ch_checksum,
        ch_rclone_config
    )

    ch_multiqc_files = ch_multiqc_files.mix(RCLONE_CHECKSUM.out.combined
        .flatMap { meta, check_file ->
            parseRcloneCheck(meta, check_file)
        }
        .collectFile(
            seed: "Row\tStatus\tFile\tSample\tPriority\n",
            sort: false
        ) { meta, checksum ->
            return [ "${meta.id}_${meta.check_format}_rclone_checksum_mqc.tsv", checksum ]
        }
    )

    //
    // MODULE: Rclone data copying
    //
    if(params.copy_matching_only) {
        // Compute expected group size per meta.id from the input
        ch_with_size = ch_checksum
            .map { meta, checksum, hash, source -> [ meta.subMap(meta.keySet() - 'check_format'), 1 ] }
            .groupTuple()
            .map { meta, ones -> tuple(meta, ones.size()) }

        files_to_copy = RCLONE_CHECKSUM.out.match.map {
                meta, match -> [ meta.subMap(meta.keySet() - 'check_format'), match ]
            }
            .combine(ch_with_size, by: 0)
            .map { meta, match, size -> tuple(groupKey(meta, size), match) }
            .groupTuple()
            .map{ meta, files ->
                def common = files
                    .collect { it.readLines() }
                    .inject { a, b -> a.intersect(b) }

                def copy_files = file("${workDir}/${meta.id}_files_to_copy.txt")
                copy_files.text = common.join('\n') + '\n'

                tuple(meta, copy_files)
            }

        ch_rclone_copy = ch_samplesheet.rclone
            .join(files_to_copy)
    } else {
        ch_rclone_copy = ch_samplesheet.rclone.map { meta, source, destination -> [ meta, source, destination, [] ] }
    }

    RCLONE_COPY(
        ch_rclone_copy,
        ch_rclone_config,
    )

    // Wait for file copy to finish before running RCLONE_CHECK
    ch_rclone_check = ch_samplesheet.rclone
        .join(RCLONE_COPY.out.log)
        .map { meta, input, output, log -> [ meta, input, output ] }

    //
    // File transfer validation
    //
    RCLONE_CHECK(
        ch_rclone_check,
        ch_rclone_config
    )

    ch_multiqc_files = ch_multiqc_files.mix(RCLONE_CHECK.out.combined
        .flatMap { meta, check_file ->
            parseRcloneCheck(meta, check_file)
        }
        .collectFile(
            seed: "Row\tStatus\tFile\tSample\tPriority\n",
            sort: false
        ) { meta, check ->
            return [ "${meta.id}_rclone_check_mqc.tsv", check ]
        }
    )

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'datasync_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(Channel.fromPath(params.input).collectFile(name: 'samplesheet.csv'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    ch_multiqc_files = ch_multiqc_files.mix(channel.value(file("${projectDir}/assets/multiqc_custom.css", checkIfExists: true)))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'datasync'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
