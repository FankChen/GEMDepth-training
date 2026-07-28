#!/bin/bash
# Download PointOdyssey (v1.2) for GemDepth training data.
# NOTE: current dataset/dataset_mix.py has NO loader for PointOdyssey yet -- this
# only fetches the raw data; you still need to write a loader branch to use it.
#
# Two sources are available:
#  1. Google Drive folder (default) via `gdown` -- can hit per-file rate limits /
#     quota errors ("too many users have viewed/downloaded this file recently",
#     which per Google's own message can take up to 24h to reset).
#  2. HuggingFace mirror (aharley/pointodyssey, 185GB total) via `--huggingface` --
#     no quota issues, preferred on networks where huggingface.co is whitelisted
#     but Google Drive is flaky/blocked.
#
# Official links (from https://github.com/y-zheng18/point_odyssey):
#   v1.2 (latest, 159 videos) Google Drive: https://drive.google.com/drive/u/1/folders/1W6wxsbKbTdtV8-2TwToqa_QgLqRY3ft0
#   v1.2 HuggingFace mirror: https://huggingface.co/datasets/aharley/pointodyssey
#
# Usage:
#   ./download_pointodyssey.sh [TARGET_DIR] [--huggingface]

set -e

TARGET_DIR="${1:-/mnt/data/datasets/point_odyssey}"
USE_HF=0
for arg in "$@"; do
    if [ "$arg" = "--huggingface" ]; then
        USE_HF=1
    fi
done

mkdir -p "$TARGET_DIR"

if [ "$USE_HF" = "1" ]; then
    echo "[$(date)] Downloading PointOdyssey v1.2 from HuggingFace mirror into $TARGET_DIR"
    pip install --quiet -U huggingface_hub
    python3 - "$TARGET_DIR" <<'PYEOF'
import sys
from huggingface_hub import list_repo_files, hf_hub_download

target_dir = sys.argv[1]
files = list_repo_files(repo_id="aharley/pointodyssey", repo_type="dataset")
for f in files:
    if f in (".gitattributes", "README.md"):
        continue
    print("Downloading:", f)
    hf_hub_download(
        repo_id="aharley/pointodyssey",
        repo_type="dataset",
        filename=f,
        local_dir=target_dir,
    )
PYEOF
    echo "[$(date)] Done fetching archives. Extracting..."
    cd "$TARGET_DIR"
    # train.tar.gz is split into 4 parts -- reassemble before extracting.
    if ls train.tar.gz.parta* >/dev/null 2>&1; then
        cat train.tar.gz.parta* > train.tar.gz
    fi
    for f in sample.tar.gz test.tar.gz val.tar.gz train.tar.gz; do
        [ -f "$f" ] && echo "Extracting $f ..." && tar -xzf "$f" -C "$TARGET_DIR"
    done
    echo "[$(date)] Done. Check $TARGET_DIR for train/val/test/sample video folders."
else
    FOLDER_URL="https://drive.google.com/drive/u/1/folders/1W6wxsbKbTdtV8-2TwToqa_QgLqRY3ft0"
    pip install --quiet -U gdown

    echo "[$(date)] Downloading PointOdyssey v1.2 folder into $TARGET_DIR"
    echo "If this fails with a Google Drive quota/permission error, retry later"
    echo "(quota resets), or download manually from:"
    echo "  $FOLDER_URL"

    gdown --folder "$FOLDER_URL" -O "$TARGET_DIR" --continue

    echo "[$(date)] Done. Check $TARGET_DIR for train/val/test video folders."
fi
