# nf-core/datasync: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - 2026-08-20

Initial release of nf-core/datasync, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- [[#79](https://github.com/nf-core/datasync/pull/79)] - Add exit status for `RCLONE` modules in multiqc report ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).
- [[#74](https://github.com/nf-core/datasync/pull/74)] - Implement warning and `--download` parameter when working with remote directories and SHA checksums ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila), [@apeltzer](https://github.com/apeltzer) and [@antoniasaracco](https://github.com/antoniasaracco)).
- [[#67](https://github.com/nf-core/datasync/pull/67)] - Copy only files which are successfully validated ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila) and [@antoniasaracco](https://github.com/antoniasaracco)).
- [[#57](https://github.com/nf-core/datasync/pull/57)] - Add nf-tests with edge cases([@atrigila](https://github.com/atrigila), review by [@delfiterradas](https://github.com/delfiterradas)).
- [[#55](https://github.com/nf-core/datasync/pull/55)] - Add subdirectories with sample id to results. Improvements to MultiQC report (width of columns, sections and sub-section headers)colors to multiqc results and display first errors in tables ([@atrigila](https://github.com/atrigila), review by [@delfiterradas](https://github.com/delfiterradas)).
- [[#54](https://github.com/nf-core/datasync/pull/54)] - Add colors to multiqc results and display first errors in tables ([@atrigila](https://github.com/atrigila), review by [@delfiterradas](https://github.com/delfiterradas)).
- [[#31](https://github.com/nf-core/datasync/pull/31)] - Compute checksum for each input file ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).
- [[#35](https://github.com/nf-core/datasync/pull/35)] - Compare generated checksum to given checksum in input and update test profiles ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).
- [[#46](https://github.com/nf-core/datasync/pull/46)] - Import Rclone module from nf-core([@antoniasaracco](https://github.com/antoniasaracco), review by [@delfiterradas](https://github.com/delfiterradas)).
- [[#41](https://github.com/nf-core/datasync/pull/41)] - Generate MultiQC Report with comparechecksum tables and input samplesheet ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).
- [[#49](https://github.com/nf-core/datasync/pull/49)] - Install `RCLONE_CHECK` and `RCLONE_CHECKSUM` modules from nf-core ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila) and [@antoniasaracco](https://github.com/antoniasaracco)).
- [[#59](https://github.com/nf-core/datasync/pull/59)] - Create pipeline documentation ([@antoniasaracco](https://github.com/antoniasaracco), review by [@atrigila](https://github.com/atrigila) and [@delfiterradas](https://github.com/delfiterradas)).

### `Fixed`

- [[#84](https://github.com/nf-core/datasync/pull/84)] - Update `RCLONE_` modules, enhance source and destination path handling, add local `create_filter_list` module and other small fixes ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).
- [[#83](https://github.com/nf-core/datasync/pull/83)] - Add apptainer version to avoid error in CI test ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila)).
- [[#78](https://github.com/nf-core/datasync/pull/78)] - Fixed linting issues reported by nf-core and Nextflow, and updated `rclone` modules and nf-tests to sort generated report files for deterministic snapshots ([@atrigila](https://github.com/atrigila), review by [@delfiterradas](https://github.com/delfiterradas) and [@antoniasaracco](https://github.com/antoniasaracco)).
- [[#76](https://github.com/nf-core/datasync/pull/76)] - Remove `--one-way` from rclone/checksum confi ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila) and [@antoniasaracco](https://github.com/antoniasaracco)).
- [[#73](https://github.com/nf-core/datasync/pull/73)] - Create tmp `files_to_copy.tx` avoiding error with write permissions in work directory ([@delfiterradas](https://github.com/delfiterradas), review by [@atrigila](https://github.com/atrigila) and [@antoniasaracco](https://github.com/antoniasaracco)).

### `Dependencies`

### `Deprecated`
