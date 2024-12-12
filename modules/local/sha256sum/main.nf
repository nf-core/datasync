process SHA256SUM_CHECK {
    // container "biocontainers/fastp:0.23.4--h5f740d0_0" //Using the same as the nf-core shasum module
    // //Rocky doesnt contain ps - which is required for nextflow https://nextflow.io/docs/latest/container.html

    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(path_to_check), path(checksum_file)

    output:
    tuple val(meta), path("${meta.id}.report.txt"), emit: report
    tuple val(meta), env("EXIT_CODE"), emit: exit_code

    script:
    """
    # we don't want to fail, even when subprocess fails
    set +euo pipefail
    sha256sum --strict -c ${checksum_file} 2>&1 > ${meta.id}.report.txt
    EXIT_CODE=\$?
    echo
    """
}
