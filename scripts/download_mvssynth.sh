#!/bin/bash
# Download MVS-Synth for GemDepth training data (7th listed dataset).
# NOTE: current dataset/dataset_mix.py has NO loader for MVS-Synth yet -- this
# only fetches the raw data; you still need to write a loader branch to use it.
#
# Official source: https://phuang17.github.io/DeepMVS/mvs-synth.html
# Hosted on HuggingFace: https://huggingface.co/datasets/phuang17/MVS-Synth
#
# Usage:
#   ./download_mvssynth.sh [TARGET_DIR] [RESOLUTION]
#   RESOLUTION one of: 720 (default, 16GB) | 1080 (34GB) | 540 (9GB)

set -e

TARGET_DIR="${1:-/mnt/data/datasets/mvs_synth}"
RES="${2:-720}"
ARCHIVE="GTAV_${RES}.tar.gz"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "[$(date)] Fetching $ARCHIVE into $TARGET_DIR"

pip install --quiet -U huggingface_hub

# Official/robust path: huggingface_hub resolves the CDN url itself.
python3 - "$ARCHIVE" "$TARGET_DIR" <<'PYEOF'
import sys
from huggingface_hub import hf_hub_download

archive, target_dir = sys.argv[1], sys.argv[2]
path = hf_hub_download(
    repo_id="phuang17/MVS-Synth",
    repo_type="dataset",
    filename=archive,
    local_dir=target_dir,
)
print("Downloaded:", path)
PYEOF

echo "[$(date)] Extracting $ARCHIVE ..."
tar -xzf "$ARCHIVE" -C "$TARGET_DIR"

echo "[$(date)] Done. Structure per sequence: 0000/{depths/*.exr, images/*.png, poses/*.json}"
