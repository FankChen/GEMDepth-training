#!/bin/bash
# Download IRS (Indoor Robotics Stereo) for GemDepth training data.
# NOTE: current dataset/dataset_mix.py has NO loader for IRS yet -- this only
# fetches the raw data; you still need to write a loader branch to use it.
#
# Data is only hosted on OneDrive (no official script/API):
#   https://1drv.ms/f/s!AmN7U9URpGVGem0coY8PJMHYg0g?e=nvH5oB
#
# This script tries the `onedrivedownloader` pip package, which can pull public
# OneDrive share links non-interactively. If it fails (OneDrive share links
# are sometimes flaky for headless downloads), fall back to opening the link
# in a browser on a machine with a display, download the zip(s) manually, and
# scp them to the Aliyun server into TARGET_DIR.
#
# Usage:
#   ./download_irs.sh [TARGET_DIR]

set -e

TARGET_DIR="${1:-/mnt/data/datasets/irs}"
SHARE_URL="https://1drv.ms/f/s!AmN7U9URpGVGem0coY8PJMHYg0g?e=nvH5oB"

mkdir -p "$TARGET_DIR"

pip install --quiet -U onedrivedownloader

echo "[$(date)] Attempting automatic OneDrive folder download into $TARGET_DIR"
python3 - "$SHARE_URL" "$TARGET_DIR" <<'PYEOF'
import sys
from onedrivedownloader import download

url, target_dir = sys.argv[1], sys.argv[2]
download(url, filename=target_dir, unzip=True)
PYEOF

echo "[$(date)] If the above failed, download manually from:"
echo "  $SHARE_URL"
echo "then scp the extracted Home/Office/Restaurant/Store folders to $TARGET_DIR"
echo "Expected final structure: $TARGET_DIR/{Home,Office,Restaurant,Store}"
