process CREATE_FILTER_LIST {
    tag "$meta.id"

    input:
    tuple val(meta), val(common)

    output:
    tuple val(meta), path('files_to_copy.txt')

    script:
    def content = common.join('\n')

    """
    cat > files_to_copy.txt <<'EOF'
${content}
EOF
    """
}
