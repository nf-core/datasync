process SYNC {
    label 'process_single'

    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3'}"

    input:
    tuple val(run_id), path(origin), path(sync) // [run_id, rundir, origin]

    output: //We do not really have outputs, this happens in the directories already as they are just "mounted" and copied over from
    tuple val(run_id), path(${run_id}_sha256_checksums.txt) , emit: synced
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in pipelines/archivetmcp/bin/
    """
    //Run checksums first
    for file in $(find ${origin} -type f)
    do
        sha256sum ${file} >> ${run_id}_sha256_checksums.txt
        touch ${origin}/CHECKSUM_DONE ##Needs to be parameterized , currently always creates this
    done
    fi

    //Run actual sync step
    rsync -crptgo ${origin} ${sync}

    //Touch SYNC DONE
    touch ${origin}/SYNC_DONE

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
