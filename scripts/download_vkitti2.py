#!/usr/bin/env python3
"""Download and extract VKITTI 2.0.3 from the official Naver Labs URLs.

GemDepth's current loader (dataset/dataset_mix.py) actually expects **VKITTI 2**
layout (not 1.3.1!):

    <target-dir>/<Scene>/<variation>/frames/rgb/Camera_0/rgb_%05d.jpg
    <target-dir>/<Scene>/<variation>/frames/depth/Camera_0/depth_%05d.png
    <target-dir>/<Scene>/<variation>/extrinsic.txt

By default we only fetch the 3 components the loader needs: rgb, depth, textgt
(the small archive that contains extrinsic.txt/intrinsic.txt/etc). Segmentation
and optical/scene flow archives are optional extras (~90GB more) and skipped
unless requested.

Official dataset page:
https://europe.naverlabs.com/research/computer-vision/proxy-virtual-worlds-vkitti-2/
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


DEFAULT_TARGET_DIR = "/mnt/data/datasets/vkitti_2.0.3"

BASE_URL = "https://download.europe.naverlabs.com/virtual_kitti_2.0.3"

# name -> (url filename, is_gzipped)
COMPONENTS = {
    "rgb": ("vkitti_2.0.3_rgb.tar", False, "7.0GB - RGB frames (required)"),
    "depth": ("vkitti_2.0.3_depth.tar", False, "7.6GB - depth ground truth (required)"),
    "textgt": ("vkitti_2.0.3_textgt.tar.gz", True, "23MB - extrinsic/intrinsic/colors txt (required)"),
    "classSegmentation": ("vkitti_2.0.3_classSegmentation.tar", False, "1.0GB - optional, not used by GemDepth loader"),
    "instanceSegmentation": ("vkitti_2.0.3_instanceSegmentation.tar", False, "166MB - optional"),
    "forwardFlow": ("vkitti_2.0.3_forwardFlow.tar", False, "29.6GB - optional"),
    "backwardFlow": ("vkitti_2.0.3_backwardFlow.tar", False, "27.1GB - optional"),
    "forwardSceneFlow": ("vkitti_2.0.3_forwardSceneFlow.tar", False, "14.8GB - optional"),
    "backwardSceneFlow": ("vkitti_2.0.3_backwardSceneFlow.tar", False, "14.8GB - optional"),
}

REQUIRED_COMPONENTS = ["rgb", "depth", "textgt"]


def run(cmd: list[str]) -> None:
    print("+ " + " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True)


def download(url: str, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if shutil.which("wget"):
        run(["wget", "-c", "--tries=10", "--timeout=60", "--progress=dot:giga", "-O", str(output_path), url])
        return
    if shutil.which("curl"):
        run(["curl", "-L", "--retry", "10", "--retry-delay", "10", "-C", "-", "-o", str(output_path), url])
        return
    raise RuntimeError("Neither wget nor curl is available on this node.")


def extract(archive_path: Path, target_dir: Path, gzipped: bool) -> None:
    if gzipped:
        run(["tar", "-xzf", str(archive_path), "-C", str(target_dir)])
    else:
        run(["tar", "-xf", str(archive_path), "-C", str(target_dir)])


def verify(target_dir: Path) -> bool:
    print("\n" + "=" * 80)
    print(f"Verifying VKITTI 2.0.3 structure under: {target_dir}")
    print("=" * 80)
    scene_dirs = sorted(p for p in target_dir.glob("Scene*") if p.is_dir())
    if not scene_dirs:
        print(f"✗ no Scene* directories found directly under {target_dir}")
        print("  (tar files extract flat: rgb/depth/textgt all merge into Scene01..Scene20 folders)")
        return False
    ok = True
    for scene in scene_dirs:
        for variation_dir in sorted(p for p in scene.iterdir() if p.is_dir()):
            rgb_dir = variation_dir / "frames" / "rgb" / "Camera_0"
            depth_dir = variation_dir / "frames" / "depth" / "Camera_0"
            extr_file = variation_dir / "extrinsic.txt"
            missing = [p for p in (rgb_dir, depth_dir, extr_file) if not p.exists()]
            if missing:
                ok = False
                print(f"✗ {variation_dir}: missing {[str(m) for m in missing]}")
    if ok:
        print(f"✓ found {len(scene_dirs)} scenes with rgb/depth/extrinsic.txt present.")
        print("✓ VKITTI 2.0.3 is ready for GemDepth training "
              "(pass this directory, or any parent containing it, as data_dirs).")
    else:
        print("\n✗ VKITTI 2.0.3 is incomplete.")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description="Download VKITTI 2.0.3 from official Naver Labs URLs")
    parser.add_argument("--target-dir", default=DEFAULT_TARGET_DIR)
    parser.add_argument("--components", nargs="+", default=REQUIRED_COMPONENTS, choices=list(COMPONENTS.keys()))
    parser.add_argument("--keep-archives", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()

    target = Path(args.target_dir).expanduser().resolve()
    archive_dir = target / "archives"
    target.mkdir(parents=True, exist_ok=True)

    print(f"Target directory: {target}")
    print("Official VKITTI 2.0.3 source:")
    print("  https://europe.naverlabs.com/research/computer-vision/proxy-virtual-worlds-vkitti-2/")

    if args.verify_only:
        return 0 if verify(target) else 1

    archive_dir.mkdir(parents=True, exist_ok=True)
    try:
        for name in args.components:
            filename, gzipped, note = COMPONENTS[name]
            url = f"{BASE_URL}/{filename}"
            archive_path = archive_dir / filename
            print("\n" + "=" * 80)
            print(f"Component: {name} ({note})")
            print(f"URL: {url}")
            print("=" * 80)

            if not archive_path.exists():
                download(url, archive_path)
            else:
                print(f"✓ archive already exists, reusing: {archive_path}")

            print(f"Extracting {archive_path.name} ...")
            extract(archive_path, target, gzipped)

            if not args.keep_archives:
                archive_path.unlink(missing_ok=True)
                print(f"✓ removed archive to save space: {archive_path}")
    except Exception as exc:
        print(f"\nERROR: {exc}", file=sys.stderr)
        return 1

    return 0 if verify(target) else 1


if __name__ == "__main__":
    sys.exit(main())
