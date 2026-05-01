# roop CPU Headless 快速参考卡

## 💻 系统要求

```
操作系统: Ubuntu 22.04+ / CentOS 8+ 
Python: 3.10+
内存: 2 GB+ (推荐 4 GB+)
CPU: 2核+ (推荐 4核+)
存储: 500 MB+ (不含模型)
模型存储: 260 MB+ (inswapper + buffalo_l)
```

## 📦 依赖包（完整版本）

```
numpy==1.24.4
opencv-python-headless==4.11.0.86
onnx==1.14.0
onnxruntime==1.15.0
insightface==0.7.3
tensorflow==2.13.0
protobuf==4.23.4
opennsfw2==0.10.2
psutil==5.9.5
tqdm==4.65.0
Pillow==12.1.1
scipy==1.11.4
```

## 🚀 5分钟快速部署

```bash
# 1. 系统依赖
sudo apt-get install -y ffmpeg python3.10 python3.10-venv

# 2. 项目部署
cd /home/lxj/lx
tar -xzf roop-main-cpu-server.tar.gz
cd roop-main

# 3. 虚拟环境
python3.10 -m venv .venv_server
source .venv_server/bin/activate

# 4. 安装依赖
python -m pip install --upgrade pip
python -m pip install -r requirements-server-cpu.txt

# 5. 验证环境
python scripts/check_roop_server_cpu.py

# 6. 测试推理
python run.py -s data/w700d1q75cms.jpg -t data/0.mp4 -o data/output \
    --execution-provider cpu --keep-fps
```

## 🔍 关键命令速查

| 任务 | 命令 |
|------|------|
| 检查环境 | `python scripts/check_roop_server_cpu.py` |
| 离线测试 | `bash scripts/run_cpu_offline_test.sh` |
| CPU 推理 | `python run.py -s img.jpg -t video.mp4 -o out --execution-provider cpu` |
| 查看版本 | `python -c "import onnxruntime as ort; print(ort.__version__)"` |
| 列出提供者 | `python -c "import onnxruntime as ort; print(ort.get_available_providers())"` |
| 检查依赖 | `python -m pip check` |
| 查看已装包 | `python -m pip freeze` |

## ⚙️ 环境变量配置

```bash
# 必需
export ROOP_ALLOW_DOWNLOAD=0          # 禁用联网下载
export ROOP_FFMPEG_BIN=/usr/bin/ffmpeg
export ROOP_FFPROBE_BIN=/usr/bin/ffprobe

# 可选（离线测试用）
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export HF_HOME=/tmp/hf_cache
export XDG_CACHE_HOME=/tmp/xdg_cache
```

## 🎯 性能指标

| 指标 | 本地测试值 | 服务器预期 |
|------|----------|----------|
| 推理速度 | 1.6 sec/frame | 1-3 sec/frame |
| 内存占用 | 1.58 GB | 1.5-2 GB |
| 输出大小 | 170 KB (107帧) | 按视频长度成比例 |
| CPU 占用 | ~80% | ~70-90% |
| 推理时间 | 2:50 (107帧) | 按视频长度成比例 |

## 🔴 常见错误与快速修复

| 错误 | 原因 | 修复 |
|-----|------|------|
| `No module named 'cv2'` | OpenCV 未装 | `pip install opencv-python-headless==4.11.0.86` |
| `CPUExecutionProvider 不可用` | ONNX Runtime 版本不对 | `pip install onnxruntime==1.15.0` |
| `找不到 ffmpeg` | 未安装或不在 PATH | `sudo apt-get install ffmpeg` |
| `缺少 inswapper_128.onnx` | 模型未上传 | 检查 `models/` 目录 |
| `输出文件 < 50KB` | 推理失败 | 检查日志，重试推理 |
| `TensorFlow ImportError` | 版本不兼容 | `pip install tensorflow==2.13.0` |

## 🧪 验证步骤

```bash
# 逐一确认这些命令都能成功执行

# 1. Python 环境
python --version                    # 应输出 3.10.x

# 2. 核心包
python -c "import numpy; print(numpy.__version__)"
python -c "import cv2; print(cv2.__version__)"
python -c "import onnx; print(onnx.__version__)"
python -c "import onnxruntime as ort; print(ort.__version__)"
python -c "import tensorflow as tf; print(tf.__version__)"

# 3. 执行提供者
python -c "import onnxruntime as ort; assert 'CPUExecutionProvider' in ort.get_available_providers()"

# 4. ffmpeg
which ffmpeg
which ffprobe

# 5. 模型文件
ls -lh models/inswapper_128.onnx
ls -lh models/buffalo_l/*.onnx

# 6. 完整验证
python scripts/check_roop_server_cpu.py
```

## 📊 测试结果汇总

| 级别 | 项目 | 结果 | 备注 |
|-----|------|------|------|
| 1 | 基础依赖 | ✅ PASS | Python 3.10 + 全部包 |
| 2 | ffmpeg 检查 | ✅ PASS | ffprobe 8.0.1 可用 |
| 3 | 模型资源 | ✅ PASS | inswapper + buffalo_l 完整 |
| 4 | CPU 推理 | ✅ PASS | 输出 170 KB mp4 |
| 5 | 离线模式 | 👁️ 待验证 | 服务器上需重复 |

## 📝 部署检查清单

- [ ] 系统包已安装 (ffmpeg, python3.10)
- [ ] 虚拟环境已创建
- [ ] 依赖已安装 (requirements-server-cpu.txt)
- [ ] check 脚本通过
- [ ] 模型文件完整
- [ ] 推理输出有效
- [ ] 离线测试通过
- [ ] ffmpeg 路径已配置

## 🔗 重要文件位置

```
脚本位置:
  检查脚本: roop-main/scripts/check_roop_server_cpu.py
  测试脚本: roop-main/scripts/run_cpu_offline_test.sh

配置文件:
  依赖清单: roop-main/requirements-server-cpu.txt
  部署说明: roop-main/DEPLOYMENT.md

模型位置:
  主模型: roop-main/models/inswapper_128.onnx (~110 MB)
  检测器: roop-main/models/buffalo_l/ (~150 MB)

测试数据:
  源图像: roop-main/data/w700d1q75cms.jpg
  目标视频: roop-main/data/0.mp4
```

## 💡 最佳实践

1. **隔离缓存**: 离线测试时使用空缓存目录
2. **验证输出**: 始终用 ffprobe 验证生成的视频
3. **记录日志**: 推理时保存输出日志便于排查
4. **版本锁定**: 不要随意升级包版本，用指定版本
5. **环境变量**: 在脚本中显式设置 ROOP_ALLOW_DOWNLOAD=0
6. **定期备份**: 模型资源很大，部署前备份
7. **权限管理**: 设置适当的文件和目录权限

## 🎓 学习资源

- roop 官方: https://github.com/s0md3v/roop
- ONNX Runtime: https://onnxruntime.ai/
- InsightFace: https://github.com/deepinsight/insightface
- TensorFlow: https://www.tensorflow.org/

---

**版本**: 1.0  
**日期**: 2026-05-01  
**作者**: roop CPU Headless 迁移项目
