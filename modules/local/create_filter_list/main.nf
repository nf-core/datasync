process CREATE_FILTER_LIST {
    tag "$meta.id"

    input:
    tuple val(meta), val(common)

    output:
    tuple val(meta), path('files_to_copy.txt')

    exec:
    def outFile = task.workDir.resolve('files_to_copy.txt')
    outFile.text = common.join('\n') + '\n'
}
