#!/bin/bash
# read annibale launchd-related docs (bounded output)
A=/root/ref2/hackios-redmi-k90-annibale
echo "############ 1. 2026-10-28-ios26-icon-model-and-launchd-cache.md ############"
head -60 "$A/docs/analysis/2026-10-28-ios26-icon-model-and-launchd-cache.md"
echo
echo "############ 2. 2026-10-31-launchd-jobs-and-boot-cpu.md ############"
head -50 "$A/docs/analysis/2026-10-31-launchd-jobs-and-boot-cpu.md"
echo
echo "############ 3. tracking doc: first 40 rows ############"
head -45 "$A/docs/plan/2026-10-23-tracking.md"
