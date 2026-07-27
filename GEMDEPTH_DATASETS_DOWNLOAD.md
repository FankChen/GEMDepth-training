# GemDepth 7 个训练数据集 —— 阿里云下载指南

README 里列的训练数据（论文原始 7 个）：TartanAir / VKITTI(1) / VKITTI2 / PointOdyssey /
MVS-Synth / Dynamic Replica / IRS。

## ⚠️ 先看这个：当前代码只吃 2 个数据集

`dataset/dataset_mix.py`（`DepthVideoDataset`）目前**只实现了两个 loader 分支**：
`'vkitti'`（按路径含 `vkitti` 触发，但读的其实是 **VKITTI2** 目录结构：
`<Scene>/<variation>/frames/{rgb,depth}/Camera_0/...` + `extrinsic.txt`，**不是** 1.3.1！）
和 `'tartanair'`。

`VKITTI_SETUP.md` / `GEMDepth_REPRO.md` 里写的 VKITTI **1.3.1** 三件套（`vkitti_1.3.1_rgb/
depthgt/extrinsicsgt`）已经和当前代码对不上了——代码已经改成认 VKITTI2 格式，那两份文档是旧的。

其余 5 个（PointOdyssey / MVS-Synth / Dynamic Replica / IRS / 以及 VKITTI1.3.1 本身）
**没有 loader 分支**，下载下来目前训练用不上，需要自己在 `dataset_mix.py` 里加对应分支才能接入。

下面 7 个下载脚本我都准备好了，能自动化的都自动化了；3 个数据集因为版权/托管方式（License 表单、
Google Drive 配额、OneDrive）没法完全脚本化，脚本里写清楚了要你手动做哪一步。

脚本都在：`/home/izi2sgh/MYDATA/quanjie/liren/depth_baselines/GemDepth/scripts/`
（阿里云上对应路径按你自己的 checkout 位置替换，目标目录默认统一放 `/mnt/data/datasets/<name>`）

---

## 1. VKITTI2（★训练必需，代码已支持）

```bash
python3 scripts/download_vkitti2.py --target-dir /mnt/data/datasets/vkitti_2.0.3
```

默认只下载 loader 需要的 3 个包：`rgb`(7GB) + `depth`(7.6GB) + `textgt`(23MB，含 extrinsic.txt)。
分割/光流是可选项，默认不下（`--components classSegmentation instanceSegmentation forwardFlow ...` 手动加）。

官方页面：https://europe.naverlabs.com/research/computer-vision/proxy-virtual-worlds-vkitti-2/

## 2. TartanAir（★训练必需，代码已支持）

旧的 `scripts/download_tartanair.bsub` 用的 azure blob 直链已经过期（TartanAir 官方已换成
AirLab Ceph RGW / HuggingFace）。新脚本走官方 `tartanair_tools` 下载器：

```bash
./scripts/download_tartanair.sh /mnt/data/datasets/tartanair
```

默认只拉 `--rgb --depth --only-left`（loader 只用 image_left/depth_left/pose_left.txt），
省掉 seg/flow（体积大头）。想先跑小样本可以在脚本里加 `--only-easy`。
如果 AirLab 服务器不通，加 `--huggingface` 走 HF 镜像。

官方仓库：https://github.com/castacks/tartanair_tools

## 3. VKITTI 1.3.1（旧格式，代码目前用不到，仅按你的要求保留下载）

沿用之前写好的脚本，换目标目录即可：

```bash
python3 scripts/download_vkitti.py --target-dir /mnt/data/datasets/vkitti_1.3.1
```

## 4. MVS-Synth（无 loader，先下数据）

托管在 HuggingFace，走官方 huggingface_hub 下载（比直接猜 CDN 直链稳）：

```bash
./scripts/download_mvssynth.sh /mnt/data/datasets/mvs_synth 720   # 720p ~16GB
# 分辨率可选 540(9GB) / 720(16GB) / 1080(34GB)
```

官方页面：https://phuang17.github.io/DeepMVS/mvs-synth.html

## 5. PointOdyssey（无 loader，Google Drive 文件夹，半自动）

```bash
./scripts/download_pointodyssey.sh /mnt/data/datasets/point_odyssey
```

用 `gdown --folder` 镜像官方 v1.2 Google Drive 文件夹。大文件夹可能撞 Google 配额报错，
重跑同一条命令即可续传；如果一直失败就只能挑浏览器手动下载再传上去。

官方仓库：https://github.com/y-zheng18/point_odyssey

## 6. Dynamic Replica（无 loader，License 表单，必须手动一步）

**不能全自动**：需要你先在浏览器打开 https://dynamic-stereo.github.io/ → Data 标签页 →
接受协议 → 下载生成的 `links.json`。拿到 `links.json` 后：

```bash
./scripts/download_dynamic_replica.sh /mnt/data/datasets/dynamic_replica ./links.json valid test real
# train 分片解压后 1.8TB，默认不下；要下就把 train 也加进参数列表
```

官方仓库：https://github.com/facebookresearch/dynamic_stereo

## 7. IRS（无 loader，OneDrive，尽量自动）

```bash
./scripts/download_irs.sh /mnt/data/datasets/irs
```

用 `onedrivedownloader` 尝试无交互下载官方 OneDrive 分享链接；OneDrive 分享链接对无头下载
不太友好，失败的话只能浏览器手动下载 zip 再 scp 到服务器。

官方仓库：https://github.com/HKBU-HPML/IRS
（下载链接：https://1drv.ms/f/s!AmN7U9URpGVGem0coY8PJMHYg0g?e=nvH5oB）

---

## 建议的优先级

1. **VKITTI2 + TartanAir** 先下 —— 代码现在就能直接拿来训练。
2. 其余 5 个按你实际要不要扩 loader 再决定顺序；MVS-Synth/PointOdyssey 相对好搞定，
   Dynamic Replica/IRS 卡在人工步骤，优先级可以放最后。
