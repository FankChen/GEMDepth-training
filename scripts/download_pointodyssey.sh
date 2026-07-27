#!/bin/bash
# Download PointOdyssey (v1.2) for GemDepth training data.
# NOTE: current dataset/dataset_mix.py has NO loader for PointOdyssey yet -- this
# only fetches the raw data; you still need to write a loader branch to use it.
#
# Data is hosted as a Google Drive folder (no official CLI/API), so this uses
# `gdown` to mirror the folder. Google Drive folder downloads can hit per-file
# rate limits / quota errors on large folders -- rerun the same command to
# resume (gdown skips files that already exist), or fall back to downloading
# via a browser if it keeps failing.
#
# Official links (from https://github.com/y-zheng18/point_odyssey):
#   v1.2 (latest, 159 videos): https://drive.google.com/drive/u/1/folders/1W6wxsbKbTdtV8-2TwToqa_QgLqRY3ft0
#   v1.1: https://drive.google.com/drive/u/1/folders/1lMMHMXrTaFZEugD8ABScvrkmGGSqDe2f
#
# Usage:
#   ./download_pointodyssey.sh [TARGET_DIR]

set -e

TARGET_DIR="${1:-/mnt/data/datasets/point_odyssey}"
FOLDER_URL="https://drive.google.com/drive/u/1/folders/1W6wxsbKbTdtV8-2TwToqa_QgLqRY3ft0"

mkdir -p "$TARGET_DIR"

pip install --quiet -U gdown

echo "[$(date)] Downloading PointOdyssey v1.2 folder into $TARGET_DIR"
echo "If this fails with a Google Drive quota/permission error, retry later"
echo "(quota resets), or download manually from:"
echo "  $FOLDER_URL"

gdown --folder "$FOLDER_URL" -O "$TARGET_DIR" --continue

echo "[$(date)] Done. Check $TARGET_DIR for train/val/test video folders."
