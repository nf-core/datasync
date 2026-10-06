# nf-core/datasync: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.2 - 2026-10-06

### `Fixed`

- [[#99](https://github.com/nf-core/datasync/pull/99)] - Bump pipeline's version ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).

## v1.0.1 - 2026-10-02

### `Fixed`

- [[#97](https://github.com/nf-core/datasync/pull/97)] - Pin nf-schema for AWS full test ([@delfiterradas](https://github.com/delfiterradas), review by [@mashehu](https://github.com/mashehu)).

## v1.0.0 - 2026-09-28

Initial release of nf-core/datasync, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Samplesheet-driven copying of files and directories between local paths and rclone-supported object storage locations.
- Validation of source data against supplied MD5 and SHA-256 checksum manifests before transfer.
- The ability to copy only files that pass checksum validation, and to download remote files when SHA-256 verification is required.
- Post-transfer comparison of copied data against the source, with detailed rclone status files for each sample.
- A MultiQC report covering the input samplesheet, validation summary, checksum validation, and post-transfer checks.
- A local test profile to explore the pipeline and its outputs.
