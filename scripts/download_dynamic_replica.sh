#!/bin/bash
# Download Dynamic Replica for GemDepth training data.
# NOTE: current dataset/dataset_mix.py has NO loader for Dynamic Replica yet --
# this only fetches the raw data; you still need to write a loader branch to use it.
#
# This dataset is license-gated: you MUST manually accept the license on the
# project website to get a `links.json` file. This step cannot be scripted
# (needs a browser + form submission):
#   1. Open https://dynamic-stereo.github.io/ in a browser
#   2. Go to the "Data" tab, accept the license agreement
#   3. Download the generated `links.json` file
#   4. Copy `links.json` to this script's directory (or pass its path as $2)
#
# Once you have links.json, this script clones facebookresearch/dynamic_stereo
# and runs the official download script.
#
# Usage:
#   ./download_dynamic_replica.sh [TARGET_DIR] [LINKS_JSON_PATH] [SPLITS...]
#   Default splits: valid test real   (train alone is ~1.8TB, opt in explicitly)
#
# Example (only valid+test+real, skip huge train split):
#   ./download_dynamic_replica.sh /mnt/data/datasets/dynamic_replica ./links.json valid test real
# Example (everything, including 1.8TB train split):
#   ./download_dynamic_replica.sh /mnt/data/datasets/dynamic_replica ./links.json train valid test real

set -e

TARGET_DIR="${1:-/mnt/data/datasets/dynamic_replica}"
LINKS_JSON="${2:-./links.json}"
shift 2 2>/dev/null || true
SPLITS=("$@")
if [ ${#SPLITS[@]} -eq 0 ]; then
    SPLITS=(valid test real)
fi

if [ ! -f "$LINKS_JSON" ]; then
    echo "ERROR: links.json not found at $LINKS_JSON" >&2
    echo "Get it manually (license acceptance required):" >&2
    echo "  1. https://dynamic-stereo.github.io/ -> Data tab -> accept license -> download links.json" >&2
    exit 1
fi

REPO_DIR="$TARGET_DIR/dynamic_stereo"
mkdir -p "$TARGET_DIR"

if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/facebookresearch/dynamic_stereo "$REPO_DIR"
fi

cp "$LINKS_JSON" "$REPO_DIR/links.json"
cd "$REPO_DIR"

echo "[$(date)] Downloading Dynamic Replica splits: ${SPLITS[*]}"
echo "Disk needed (unpacked): train=1.8T test=328G valid=106G real=152M"

python ./scripts/download_dynamic_replica.py \
    --link_list_file links.json \
    --download_folder "$TARGET_DIR/data" \
    --download_splits "${SPLITS[@]}"

echo "[$(date)] Done. Data under $TARGET_DIR/data"
