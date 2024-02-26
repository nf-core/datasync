#!/bin/bash
# This script expects a single folder $1 with several subfolders that then need to be synchronized and checksummed to another location $2
mkdir -p $1
mkdir -p $2
touch $1/DemuxDone #Note this needs to be configured as a pattern to look for in the pipeline configuration, otherwise this trigger won't work.
touch $1/fake_file.fastq.gz
touch $1/fake_file2.fastq.gz
echo "Sync me to another place" > $1/SampleSheet.csv
