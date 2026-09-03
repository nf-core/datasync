# nf-core/datasync: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/datasync/usage](https://nf-co.re/datasync/usage)

> Pipeline parameter documentation is generated automatically from [`nextflow_schema.json`](../nextflow_schema.json). This page explains how to prepare a transfer and operate the pipeline.

## Prerequisites

Install Nextflow 25.10.4 or later and use a supported software profile. Docker or Singularity/Apptainer is recommended for reproducibility. Ensure that the account running Nextflow can read each source and checksum manifest and can write to every destination.

For cloud or other authenticated rclone remotes, create an [rclone configuration](https://rclone.org/docs/) and pass it with `--rclone_config`. The configuration applies to remote **sources and destinations**. The pipeline has currently been tested for transfers between S3 buckets. Other rclone-supported layouts, such as Azure Blob Storage to S3 or transfers between S3-compatible providers, should be configured and validated against the upstream `rclone` documentation for each provider before use.

## Samplesheet input

Supply a comma-separated samplesheet with `--input`:

```bash
--input /path/to/samplesheet.csv
```

Each row describes an independent transfer. The header names are fixed; columns may be in any order.

| Column         | Required            | Description                                                                                                                                                                                                                |
| -------------- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`       | Yes                 | Unique identifier used in task labels and output report names. It must not contain whitespace. Use a unique value for each row to prevent published report files from colliding.                                           |
| `input`        | Yes                 | Source file or directory. Use a local path or object-storage URI such as `s3://bucket/prefix`. HTTP(S) URLs and rclone-specific `remote:path` syntax are not supported. Whitespace is not allowed.                         |
| `output_path`  | Yes                 | Destination directory. Use a local path such as `/archive/runs` or an object-storage URI such as `s3://bucket/prefix`. HTTP(S) URLs and rclone-specific `remote:path` syntax are not supported. Whitespace is not allowed. |
| `checksum_md5` | One checksum column | Path or URL to an MD5 checksum manifest used to validate `input` before copying. The manifest format is described below. Leave empty when using SHA-256 only.                                                              |
| `checksum_sha` | One checksum column | Path or URL to a SHA-256 checksum manifest used to validate `input` before copying. The manifest format is described below. Leave empty when using MD5 only.                                                               |

HTTP(S) URLs are not currently supported for `input` or `output_path`. The pipeline validates checksum manifests before copying and verifies the copied content afterwards; HTTP checksum behavior is not yet defined and tested for this workflow. Download HTTP-hosted data locally before including it in a samplesheet.

At least one checksum manifest is required on every row. If both are supplied, both validations run. Checksum files must use the format accepted by [`rclone checksum`](https://rclone.org/commands/rclone_checksum/): one checksum record per line with the hash value followed by two spaces and then the file path. Paths must be relative to the source root from the `input` column, not absolute paths.

For a directory input, the source root is the directory named in the samplesheet. For example, if the samplesheet `input` is `/data/run_001` and one file in that directory is `/data/run_001/reads/sample_R1.fastq.gz`, the checksum manifest path must be `reads/sample_R1.fastq.gz`. Do not write `/data/run_001/reads/sample_R1.fastq.gz` in the manifest. For a single-file input, use the input file name as the manifest path.

Checksum manifests may use a `.tsv`, `.txt`, `.md5` or `.sha256` filename extension, but their contents are not tab-separated or comma-separated tables and must not include a header. Each record is plain text with the hash and path separated by exactly **two spaces**. The required fields are:

| Field | Required | Description                                                                                     |
| ----- | -------- | ----------------------------------------------------------------------------------------------- |
| Hash  | Yes      | MD5 hash for `checksum_md5` files or SHA-256 hash for `checksum_sha` files.                     |
| Path  | Yes      | Relative path to the file being validated, resolved from the corresponding `input` source root. |

Example samplesheet:

```csv title="samplesheet.csv"
sample,input,output_path,checksum_md5,checksum_sha
run_001,/data/run_001,s3://archive/runs,/data/checksums/run_001_md5.tsv,
reference,/data/reference.fa,/data/references,,/data/checksums/reference_sha256.tsv
run_002,/data/run_002,s3://archive/runs,/data/checksums/run_002_md5.tsv,/data/checksums/run_002_sha256.tsv
```

For the `run_001` directory example, `/data/checksums/run_001_md5.tsv` could contain:

```text title="run_001_md5.tsv"
d41d8cd98f00b204e9800998ecf8427e  reads/sample_R1.fastq.gz
0cc175b9c0f1b6a831c399e269772661  reads/sample_R2.fastq.gz
900150983cd24fb0d6963f7d28e17f72  reports/qc_summary.txt
```

For a SHA-256 manifest, the same relative paths are used with SHA-256 hashes:

```text title="run_001_sha256.tsv"
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  reads/sample_R1.fastq.gz
ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb  reads/sample_R2.fastq.gz
ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  reports/qc_summary.txt
```

An [example samplesheet](../assets/samplesheet.csv) is included in the repository.

## Configuring `rclone` remotes

The file supplied with `--rclone_config` uses `rclone`'s INI-style format.

Each `[name]` section defines an rclone remote used internally by the pipeline. Samplesheet paths must use local paths or standard URIs such as `s3://bucket/path`; `name:path` values are not accepted. For an `s3://` URI, configure the matching `[s3]` remote in the rclone configuration.

> [!NOTE]
> The pipeline's documented and tested configuration pattern is S3-to-S3 transfer.

One file may contain several sections for different providers, but samplesheet URIs select the remote that has the matching scheme name. Provider-specific options should be taken from the relevant `rclone` documentation.

Create the file interactively where possible:

```bash
rclone config --config /secure/rclone.conf
rclone listremotes --config /secure/rclone.conf
```

Then provide that exact file to the pipeline:

```bash
nextflow run nf-core/datasync \
    -profile docker \
    --input samplesheet.csv \
    --outdir results \
    --rclone_config /secure/rclone.conf
```

### S3 and S3-compatible storage

The main use case tested for nf-core/datasync is transferring files between S3 buckets. An S3 remote specifies the provider, region, and credentials. For example:

```ini title="rclone.conf"
[s3]
type = s3
provider = AWS
access_key_id = YOUR_ACCESS_KEY_ID
secret_access_key = YOUR_SECRET_ACCESS_KEY
region = eu-central-1
```

Use `s3://bucket/path` for S3 sources and destinations in the samplesheet. The pipeline converts this to rclone's internal `s3:bucket/path` form, so ensure rclone has credentials and provider settings for the `[s3]` remote. Provider-specific settings vary: consult the [`rclone` S3 documentation](https://rclone.org/s3/) and your storage provider's endpoint, region, addressing-style, and credential documentation rather than copying example values unchanged.

Because samplesheet paths use URI schemes rather than rclone remote names, a single samplesheet cannot select multiple differently configured S3 remotes. Use one `[s3]` configuration for the run, or run separate transfers when providers require different rclone configurations.

## SHA256 checksum verification for remote inputs

When validating files stored on cloud storage providers (e.g. S3, azure, google cloud), only MD5 hashes are typically available through the storage provider (see [Overview of cloud storage systems](https://rclone.org/overview/)). SHA256 checksums are not exposed by the remote API, so they cannot be verified directly.

In order to validate SHA256 checksums for remote inputs, `rclone checksum` must download each file and compute its SHA256 checksum locally. If a `checksum_sha` file is provided for remote inputs, the `--download` parameter must be enabled. Otherwise, SHA checksum verification cannot be performed and the pipeline will terminate with an error.

> [!NOTE]
> Providing `--download` does not force all files to be downloaded in all modules. It is only used when verifying SHA256 checksum files for remote source directories in `RCLONE_CHECKSUM`.

> [!WARNING]
> Enabling `--download` may incur substantial cloud data transfer and egress costs, particularly when validating large datasets. Make sure this is the intended behaviour before running the pipeline.

## Copying only successfully validated files

By default, the pipeline will copy all files in the source directory, regardless of whether they were successfully validated against the provided checksum or not.

However, it is possible to restrict copying of files to only the ones that successfully pass checksum validation by enabling the `--copy_matching_only` parameter:

- If only an MD5 checksum file is provided, only files that successfully match their MD5 checksum will be copied.
- If only a SHA256 checksum file is provided, only files that successfully match their SHA256 checksum will be copied.
- If both MD5 and SHA256 checksum files are provided, the pipeline will copy only files that successfully pass **both** checksum validations.

Files that fail checksum validation, are missing, or cannot be verified are excluded from the copy operation when this parameter is enabled.

## Destination layout

The pipeline preserves the source basename:

- for a file source, `rclone` copies the file into `output_path`, and validation expects `output_path/<source filename>`;
- for a directory source, the pipeline appends the source directory name, so `/data/run_001` with `output_path=/archive/runs` is copied and checked at `/archive/runs/run_001`.

A trailing slash on `output_path` is removed before these paths are constructed. Ensure that a destination does not already contain unrelated files: post-copy validation uses `rclone check --one-way`, which checks that source content exists and matches at the destination while tolerating destination-only files. You can override this behavior by providing your own config file with external arguments for `rclone check`.

## Running the pipeline

A typical local-to-cloud run is:

```bash
nextflow run nf-core/datasync \
    -r <VERSION> \
    -profile docker \
    --input /data/samplesheet.csv \
    --outdir /data/datasync-results \
    --rclone_config /secure/rclone.conf
```

`--outdir` stores logs, integrity reports, MultiQC, and execution metadata. It does **not** override the transfer destinations in the samplesheet.

To inspect the proposed copy without writing destination data:

```bash
nextflow run nf-core/datasync \
    -r <VERSION> \
    -profile docker \
    --input /data/samplesheet.csv \
    --outdir /data/datasync-dry-run \
    --rclone_config /secure/rclone.conf \
    --rclone_dry_run
```

The checksum and post-copy check stages still run during a dry run. Consequently, post-copy results reflect whatever was already present at the destination rather than a simulated final state.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/running/run-pipelines#configuring-pipelines), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/datasync -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
genome: 'GRCh37'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Parameter files

Frequently reused settings can be stored in YAML or JSON and loaded with `-params-file`:

```yaml title="params.yaml"
input: /data/samplesheet.csv
outdir: /data/datasync-results
rclone_config: /secure/rclone.conf
multiqc_title: July archive transfer
```

```bash
nextflow run nf-core/datasync -r <VERSION> -profile docker -params-file params.yaml
```

Do not use `-c` for pipeline parameters. Use it only for Nextflow executor, resources, and other infrastructure configuration.

### Common integrity outcomes

The workflow is designed to collect `rclone` reports even when `rclone` detects differences. The table below summarises common edge cases and how to interpret them in the published reports and MultiQC.

| Situation                                                          | Where it is detected                                             | Report status                     | Pipeline behaviour and action                                                                                                                       |
| ------------------------------------------------------------------ | ---------------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| File exists and checksum/content matches                           | `rclone checksum` before copy and `rclone check` after copy      | `=` / `Match`                     | Expected result; no action needed.                                                                                                                  |
| File is listed in the checksum manifest but absent from the source | Pre-copy `rclone checksum`                                       | `-` / missing from checked source | The report is retained for review. Fix the manifest or restore the missing source file before relying on the transfer.                              |
| Source file exists but is absent from the checksum manifest        | Pre-copy `rclone checksum`                                       | `+` / missing from manifest       | Review whether the manifest is incomplete or whether the extra source file should be excluded from the transfer.                                    |
| Source file hash differs from the supplied manifest                | Pre-copy `rclone checksum`                                       | `*` / mismatch                    | Investigate source mutation, stale manifests, or incorrect checksum files before accepting the copy.                                                |
| Source file cannot be read or hashed                               | Pre-copy `rclone checksum`                                       | `!` / error                       | Inspect credentials, permissions, connectivity, and source path spelling.                                                                           |
| Destination is missing a copied file                               | Post-copy `rclone check`                                         | `-` / missing from destination    | Treat as an incomplete transfer unless the file was intentionally excluded; re-run or inspect the rclone copy log.                                  |
| Destination file exists but content differs from source            | Post-copy `rclone check`                                         | `*` / mismatch                    | Re-copy or investigate concurrent source/destination changes.                                                                                       |
| Destination contains files absent from the source                  | Post-copy `rclone check`                                         | `+` / missing from source         | The post-copy check uses `--one-way`, so destination-only files are tolerated, but should still be reviewed for unexpected stale or unrelated data. |
| Dry-run execution                                                  | Copy step uses `--dry-run`; checksum and check reports still run | Depends on existing destination   | No transfer data is written. Post-copy reports describe whatever was already present at the destination.                                            |

### Including or excluding files

Filter files by passing additional `rclone` filter flags to the relevant rclone module through a Nextflow configuration file. `rclone` supports flags such as `--include`, `--exclude`, `--filter`, `--files-from`, and related rule files; see the [`rclone` filtering documentation](https://rclone.org/filtering/) for rule syntax and ordering.

For example, to copy and check only FASTQ files while excluding temporary files, create a small infrastructure config:

```groovy title="rclone_filters.config"
process {
    withName: 'RCLONE_COPY' {
        ext.args = {
            [
                '--log-level INFO',
                '--stats 30s',
                '--stats-one-line',
                '--stats-log-level INFO',
                '--s3-chunk-size 64M',
                '--no-check-certificate',
                params.rclone_dry_run ? '--dry-run' : '',
                '--include "*.fastq.gz"',
                '--include "*.fq.gz"',
                '--exclude "*.tmp"',
                '--exclude "*"'
            ].findAll { it }.join(' ')
        }
    }

    withName: 'RCLONE_CHECK' {
        ext.args = {
            [
                '--no-check-certificate',
                '--one-way',
                '--include "*.fastq.gz"',
                '--include "*.fq.gz"',
                '--exclude "*.tmp"',
                '--exclude "*"'
            ].join(' ')
        }
    }
}
```

Run it with `-c rclone_filters.config` in addition to your normal profile and parameters. Because `ext.args` overrides module defaults, include the default `rclone` flags you still need when adding filters. Keep checksum manifests consistent with the same filtering rules: if a file is intentionally excluded from copy/check, remove it from the checksum manifest or generate a manifest for only the included files.

## Understanding completion and integrity

For each row, the pipeline first validates supplied checksum manifests, performs the copy, and then compares source and destination. `rclone` comparison commands write status reports even when differences are found, allowing all results to be collected in MultiQC. Therefore, a successful Nextflow run means the workflow completed; it does **not by itself** prove every object matched. Review `multiqc/multiqc_report.html` and the reports under `rclone/`, especially lines marked `-`, `+`, `*`, or `!` (see [output documentation](output.md)).

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/datasync releases page](https://github.com/nf-core/datasync/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

The `rclone` processes use the `process_low` label. Configure executors and override CPU, memory, or time in a Nextflow config, for example:

```groovy title="resources.config"
process {
    withLabel: process_low {
        cpus = 8
        memory = '16 GB'
        time = '12h'
    }
}
```

Run with `-c resources.config`. `rclone` derives its checker count from allocated CPUs, and the copy step uses roughly half that count (minimum one) for parallel transfers.
To change the resource requests, please see the [max resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#set-max-resources) and [customise process resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#customize-process-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#update-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).
