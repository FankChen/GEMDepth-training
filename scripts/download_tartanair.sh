#!/bin/bash
# Download TartanAir for GemDepth training using the OFFICIAL castacks/tartanair_tools
# downloader (the old azure-blob wget approach in download_tartanair.bsub is stale --
# TartanAir moved its hosting to AirLab Ceph RGW + HuggingFace).
#
# GemDepth's loader (dataset/dataset_mix.py) only needs, per scene/difficulty/trajectory:
#   image_left/*.png  depth_left/*.npy  pose_left.txt
# so by default we skip --seg and --flow (they are NOT used and are the bulk of the 3TB).
#
# Usage:
#   ./download_tartanair.sh [TARGET_DIR]
#   TARGET_DIR defaults to /mnt/data/datasets/tartanair
#
# Notes:
#   - Full rgb+depth (both difficulties, left cam only) is still large (~a few hundred GB).
#     Add --only-easy to the download_training.py call below if you want a smaller subset first.
#   - If the AirLab server is flaky, add --huggingface to use the HuggingFace mirror instead.

set -e

TARGET_DIR="${1:-/mnt/data/datasets/tartanair}"
TOOLS_DIR="$TARGET_DIR/tartanair_tools"

mkdir -p "$TARGET_DIR"

echo "[$(date)] Target dir: $TARGET_DIR"

pip install --quiet boto3 colorama

if [ ! -d "$TOOLS_DIR" ]; then
    git clone https://github.com/castacks/tartanair_tools "$TOOLS_DIR"
else
    echo "✓ tartanair_tools already cloned, pulling latest"
    git -C "$TOOLS_DIR" pull --ff-only || true
fi

cd "$TOOLS_DIR"

echo "[$(date)] Downloading TartanAir rgb+depth (left camera only) ..."
python download_training.py \
    --output-dir "$TARGET_DIR" \
    --rgb --depth --only-left --unzip
    # add --only-easy to shrink the download for a first smoke run
    # add --huggingface if the AirLab server (theairlab.org) is unreachable

echo "[$(date)] Done. Verify structure:"
echo "  ls $TARGET_DIR/<ENV_NAME>/Easy/P000/{image_left,depth_left,pose_left.txt}"
