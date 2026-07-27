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

## 1. VKITTI2 —— ✅已有，不用下了

**2026-07-27 查证**：Bosch 这边 `/home/izi2sgh/MYDATA/vkitti/` 已经是完整的 VKITTI2 数据，
不用再跑 `download_vkitti2.py`。确认内容：
- 5 个 scene 全（Scene01/02/06/18/20）× 10 种 variation 全
  （15/30-deg-left/right、clone、fog、morning、overcast、rain、sunset）
- 每个 variation 下 `Camera_0` + `Camera_1` 都有，`extrinsic.txt`/`info.txt` 齐全
- 抽查 Scene01/sunset/Camera_0：447 帧 rgb 与 depth 一一对应
- 总大小 30G（Scene01=2.5G/Scene02=1.7G/Scene06=1.9G/Scene18=3.6G/Scene20=5.4G）

如果阿里云那边要用，直接把这份 30G 从 Bosch 传过去即可（不用再走官方下载）；
`scripts/download_vkitti2.py` 脚本留着备用（比如以后要多拉 segmentation/flow 才用）。

官方页面（备查）：https://europe.naverlabs.com/research/computer-vision/proxy-virtual-worlds-vkitti-2/

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

## 建议的优先级（2026-07-27 更新：VKITTI2 已有，不用再下）

1. **TartanAir** 先下 —— 唯一一个"代码已支持但还没数据"的，直接影响能不能训练。
   Bosch 之前试过下载，全部 `Proxy tunneling failed`（代理墙挡死），只能走阿里云。
2. 其余 5 个（VKITTI1.3.1 / MVS-Synth / PointOdyssey / Dynamic Replica / IRS）
   按你实际要不要扩 loader 再决定顺序；MVS-Synth/PointOdyssey 相对好搞定，
   Dynamic Replica/IRS 卡在人工步骤，优先级可以放最后。
3. ~~VKITTI2~~ 跳过，Bosch 本地已有完整 30G（见第 1 节），要用直接传数据，不用重下。

## 一条命令下完剩下要下的（TartanAir + 其余 5 个，跳过 VKITTI2）

```bash
# 1) TartanAir（最优先）
./scripts/download_tartanair.sh /mnt/data/datasets/tartanair

# 2) VKITTI 1.3.1（旧格式，代码暂时用不到，按需下）
python3 scripts/download_vkitti.py --target-dir /mnt/data/datasets/vkitti_1.3.1

# 3) MVS-Synth
./scripts/download_mvssynth.sh /mnt/data/datasets/mvs_synth 720

# 4) PointOdyssey（Google Drive，可能要重跑几次续传）
./scripts/download_pointodyssey.sh /mnt/data/datasets/point_odyssey

# 5) Dynamic Replica —— 必须先手动去 https://dynamic-stereo.github.io/ 接受协议拿 links.json
./scripts/download_dynamic_replica.sh /mnt/data/datasets/dynamic_replica ./links.json valid test real

# 6) IRS（OneDrive，失败就浏览器手动下载再传服务器）
./scripts/download_irs.sh /mnt/data/datasets/irs
```
