process SHA256SUM_CHECK {
    container "biocontainers/fastp:0.23.4--h5f740d0_0" //Using the same as the nf-core shasum module
    //Rocky doesnt contain ps - which is required for nextflow https://nextflow.io/docs/latest/container.html

    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(checksum_file)

    output:
    tuple val(meta), path(report)

    script:
    """
    sha256sum -c ${checksum_file} > ${meta.id}.report.txt
    """
}
