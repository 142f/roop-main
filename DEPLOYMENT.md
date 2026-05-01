# roop CPU Headless 服务器部署指南

**基于**: 2026-05-01 本地完整验收测试  
**环境**: Ubuntu 22.04+ / CentOS 8+ / 其他 Linux  
**目标**: CPU 纯推理服务（无 GPU，无 Web API）  

---

## 📋 快速清单

### 关键依赖
```
Python 3.10
ffmpeg + ffprobe
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
```

### 必需资源
```
models/inswapper_128.onnx        (~110 MB)
models/buffalo_l/                (~150 MB)
models/buffalo_l/*.onnx          (5个文件)
.opennsfw2/weights/...           (可选)
data/w700d1q75cms.jpg            (测试用)
data/0.mp4                       (测试用)
```

---

## 🚀 完整部署步骤

### 第1步：系统准备

```bash
# 更新包管理器
sudo apt-get update

# 安装系统依赖
sudo apt-get install -y \
    ffmpeg \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    build-essential \
    git

# 验证 ffmpeg
which ffmpeg
ffmpeg -version

which ffprobe
ffprobe -version
```

### 第2步：项目部署

```bash
# 创建目录
mkdir -p /home/lxj/lx
cd /home/lxj/lx

# 解包源代码（或 git clone）
tar -xzf roop-main.tar.gz
cd roop-main

# 目录结构检查
ls -la
# 应该包含: run.py, roop/, models/, scripts/, requirements-server-cpu.txt
```

### 第3步：虚拟环境

```bash
# 创建虚拟环境
python3.10 -m venv .venv_server

# 激活虚拟环境
source .venv_server/bin/activate

# 验证 Python
python --version
which python
```

### 第4步：依赖安装

```bash
# 升级 pip
python -m pip install --upgrade pip setuptools wheel

# 清理旧的 OpenCV 包（防止混装）
python -m pip uninstall -y \
    opencv-python \
    opencv-python-headless \
    opencv-contrib-python \
    opencv-contrib-python-headless \
    2>/dev/null || true

# 清理旧的 ONNX Runtime 包
python -m pip uninstall -y \
    onnxruntime \
    onnxruntime-gpu \
    2>/dev/null || true

# 安装 CPU headless 依赖
python -m pip install --no-cache-dir -r requirements-server-cpu.txt

# 验证安装
python -m pip check || echo "注意：pip check 有警告但不一定致命"
```

### 第5步：环境验证

```bash
# 激活虚拟环境（如果尚未激活）
source .venv_server/bin/activate
cd /home/lxj/lx/roop-main

# 运行环境检查
python scripts/check_roop_server_cpu.py

# 预期输出：
#   ✓ numpy, cv2, onnx, onnxruntime, tensorflow 等版本
#   ✓ CPUExecutionProvider 可用
#   ✓ ffmpeg 和 ffprobe 路径
#   ✓ 所有必需模型文件存在
#   ✓ roop CPU headless 服务器基础环境检查通过
```

### 第6步：离线推理测试

```bash
# 激活虚拟环境
source .venv_server/bin/activate
cd /home/lxj/lx/roop-main

# 设置离线环境变量
export ROOP_ALLOW_DOWNLOAD=0
export ROOP_FFMPEG_BIN=/usr/bin/ffmpeg
export ROOP_FFPROBE_BIN=/usr/bin/ffprobe

# 运行离线测试
bash scripts/run_cpu_offline_test.sh

# 预期输出：
#   ✓ 环境检查通过
#   ✓ 无网络访问
#   ✓ 成功生成输出 mp4
#   ✓ ffprobe 验证通过
#   ✓ 离线推理测试通过
```

### 第7步：真实推理验证

```bash
# 激活虚拟环境
source .venv_server/bin/activate
cd /home/lxj/lx/roop-main

# 设置环境变量
export ROOP_ALLOW_DOWNLOAD=0
export ROOP_FFMPEG_BIN=/usr/bin/ffmpeg
export ROOP_FFPROBE_BIN=/usr/bin/ffprobe

# 清理输出目录
rm -rf /home/lxj/lx/roop-main/data/output_final
mkdir -p /home/lxj/lx/roop-main/data/output_final

# 执行推理
python run.py \
    -s /home/lxj/lx/roop-main/data/w700d1q75cms.jpg \
    -t /home/lxj/lx/roop-main/data/0.mp4 \
    -o /home/lxj/lx/roop-main/data/output_final \
    --execution-provider cpu \
    --keep-fps

# 验证输出
ls -lh /home/lxj/lx/roop-main/data/output_final/
ffprobe -hide_banner /home/lxj/lx/roop-main/data/output_final/*.mp4
```

---

## 🔍 常见问题排查

### Q1: ImportError: No module named 'cv2'

**原因**: OpenCV 安装失败或路径问题

```bash
# 解决方案
source .venv_server/bin/activate
python -m pip uninstall -y opencv-python opencv-python-headless
python -m pip install --no-cache-dir opencv-python-headless==4.11.0.86
```

### Q2: RuntimeError: CPUExecutionProvider 不可用

**原因**: ONNX Runtime 安装不完整或版本不匹配

```bash
# 解决方案
source .venv_server/bin/activate
python -m pip uninstall -y onnxruntime
python -m pip install --no-cache-dir onnxruntime==1.15.0

# 验证
python -c "import onnxruntime as ort; print(ort.get_available_providers())"
```

### Q3: 找不到 ffmpeg / ffprobe

**原因**: 未安装或路径不在 PATH 中

```bash
# 解决方案 1: 安装系统 ffmpeg
sudo apt-get install -y ffmpeg

# 解决方案 2: 指定完整路径
export ROOP_FFMPEG_BIN=/usr/bin/ffmpeg
export ROOP_FFPROBE_BIN=/usr/bin/ffprobe

# 验证
which ffmpeg
$ROOP_FFMPEG_BIN -version
```

### Q4: 缺少模型文件

**原因**: models/ 目录未上传或不完整

```bash
# 解决方案
# 确保上传了以下文件：
ls -lh /home/lxj/lx/roop-main/models/
# 应该包含:
#   inswapper_128.onnx
#   buffalo_l/
#     ├── 1k3d68.onnx
#     ├── 2d106det.onnx
#     ├── det_10g.onnx
#     ├── genderage.onnx
#     └── w600k_r50.onnx
```

### Q5: 推理输出文件过小 (< 50KB)

**原因**: 推理失败或编码异常

```bash
# 检查日志输出
# 查看是否有错误提示

# 重新运行推理，仔细观察日志
python run.py -s ... -t ... -o ... --execution-provider cpu --keep-fps 2>&1 | tee inference.log

# 查看生成的文件
ls -lh data/output_final/
file data/output_final/*.mp4
```

### Q6: tensorflow 相关错误

**原因**: TensorFlow 版本不兼容或依赖缺失

```bash
# 解决方案
source .venv_server/bin/activate
python -m pip uninstall -y tensorflow
python -m pip install --no-cache-dir tensorflow==2.13.0

# 验证
python -c "import tensorflow as tf; print(tf.__version__)"
```

---

## 📦 打包与迁移清单

### 上传到服务器的内容

```text
roop-main/
├── run.py                           # 主入口
├── roop/                            # 源代码目录
│   ├── __init__.py
│   ├── capturer.py
│   ├── core.py
│   ├── face_analyser.py
│   ├── face_reference.py
│   ├── globals.py
│   ├── metadata.py
│   ├── predictor.py
│   ├── typing.py
│   ├── ui.json
│   ├── ui.py
│   ├── utilities.py
│   └── processors/
│       ├── __init__.py
│       └── frame/
│
├── models/                          # 必需：模型资源
│   ├── inswapper_128.onnx           (~110 MB)
│   └── buffalo_l/                   (~150 MB)
│       ├── 1k3d68.onnx
│       ├── 2d106det.onnx
│       ├── det_10g.onnx
│       ├── genderage.onnx
│       └── w600k_r50.onnx
│
├── .opennsfw2/                      # 可选：NSFW 权重
│   └── weights/
│       └── open_nsfw_weights.h5
│
├── scripts/                         # 新增：验证脚本
│   ├── check_roop_server_cpu.py
│   └── run_cpu_offline_test.sh
│
├── data/                            # 测试数据
│   ├── w700d1q75cms.jpg
│   └── 0.mp4
│
├── requirements-server-cpu.txt      # CPU headless 依赖
├── requirements-headless.txt        # 原始 headless 依赖 (保留)
├── requirements.txt                 # 原始完整依赖 (保留)
│
├── .gitignore                       # 已更新
├── README.md
├── LICENSE
└── DEPLOYMENT.md                    # 本文件
```

### 打包命令

```bash
# 在本地 Windows 创建压缩包
cd E:\Project
tar -czf roop-main-cpu-server.tar.gz \
    --exclude='.venv310' \
    --exclude='data/output*' \
    --exclude='.git' \
    --exclude='__pycache__' \
    roop-main/

# 上传到服务器
scp roop-main-cpu-server.tar.gz user@server:/home/lxj/lx/
```

---

## 🔧 性能优化建议

### 1. 多进程推理（可选）

当前 roop CLI 默认单进程。若要支持多视频批处理，建议：

```bash
# 并行处理多个视频
for video in *.mp4; do
    python run.py -s image.jpg -t "$video" -o "output_${video%.mp4}" \
        --execution-provider cpu &
done
wait
```

注意：多进程会增加内存占用，监控系统资源。

### 2. 帧处理优化

```bash
# 跳帧处理（加速，但可能影响质量）
python run.py -s image.jpg -t video.mp4 -o output \
    --execution-provider cpu \
    --frame-processors frame-skip  # 仅示例，实际功能需确认
```

### 3. 内存管理

当前测试显示单次推理占用约 1.58 GB 内存。若服务器内存有限：

```bash
# 监控内存使用
watch -n 1 'ps aux | grep python | grep run.py'

# 或使用系统工具
free -h
vmstat 1 5
```

---

## 🌐 GPU 扩展（可选，后期）

当前部署为 CPU headless。若后续需要 GPU 加速：

### 前置条件

```bash
# 检查服务器 GPU
nvidia-smi

# 确认 CUDA 和 cuDNN 版本
nvcc --version
ldconfig -p | grep -E "cudnn|cudart"
```

### GPU 安装步骤

```bash
# 1. 切换到 GPU 版本
source .venv_server/bin/activate
cd /home/lxj/lx/roop-main

python -m pip uninstall -y onnxruntime
python -m pip install --no-cache-dir onnxruntime-gpu==1.15.1

# 2. 验证 CUDAExecutionProvider
python -c "import onnxruntime as ort; print(ort.get_available_providers())"
# 应该看到: ['CUDAExecutionProvider', 'CPUExecutionProvider']

# 3. 用 GPU 推理
python run.py -s image.jpg -t video.mp4 -o output \
    --execution-provider cuda \
    --keep-fps
```

### GPU 常见问题

```text
1. CUDAExecutionProvider 不出现
   → 检查 CUDA/cuDNN 版本是否匹配 onnxruntime-gpu==1.15.1
   → ONNX Runtime 1.15 要求 CUDA 11.6+ / cuDNN 8.2+

2. GPU 内存溢出
   → 尝试设置 TensorFlow/ONNX 的显存使用限制
   → 或减小视频分辨率/帧率

3. 推理速度未提升
   → 检查是否真的用了 CUDAExecutionProvider（见上面的验证）
   → GPU 对短视频（< 100 帧）可能没有优势
```

---

## 🔐 生产部署注意事项

### 安全性

```bash
# 1. 限制文件权限
chmod 755 /home/lxj/lx/roop-main/run.py
chmod 755 /home/lxj/lx/roop-main/scripts/*.py
chmod 755 /home/lxj/lx/roop-main/scripts/*.sh

# 2. 隔离用户权限
useradd -m roop_user
chown -R roop_user:roop_user /home/lxj/lx/roop-main

# 3. 设置日志目录
mkdir -p /var/log/roop
chown roop_user:roop_user /var/log/roop
```

### 持久化运行

```bash
# 使用 systemd service（可选）
sudo tee /etc/systemd/system/roop-worker.service > /dev/null <<EOF
[Unit]
Description=roop CPU headless worker
After=network.target

[Service]
Type=simple
User=roop_user
WorkingDirectory=/home/lxj/lx/roop-main
Environment="ROOP_ALLOW_DOWNLOAD=0"
Environment="ROOP_FFMPEG_BIN=/usr/bin/ffmpeg"
ExecStart=/home/lxj/lx/roop-main/.venv_server/bin/python run.py ...
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable roop-worker
sudo systemctl start roop-worker
```

### 监控与日志

```bash
# 设置推理日志重定向
python run.py ... 2>&1 | tee /var/log/roop/inference-$(date +%Y%m%d_%H%M%S).log

# 定期检查日志
tail -f /var/log/roop/*.log
```

---

## ✅ 部署验收清单

部署完成后，逐一确认：

- [ ] Python 3.10 已安装
- [ ] ffmpeg / ffprobe 可用
- [ ] 虚拟环境已创建
- [ ] 所有依赖已安装（pip check 无关键错误）
- [ ] `python scripts/check_roop_server_cpu.py` 通过
- [ ] `bash scripts/run_cpu_offline_test.sh` 通过
- [ ] 推理输出文件有效（> 1 MB，ffprobe 可解析）
- [ ] 模型资源完整（所有 .onnx 文件存在）
- [ ] 无网络访问（离线测试成功）
- [ ] 推理速度符合预期（记录处理时间）

---

## 📞 故障排查联系

如遇到问题，请提供：

1. 完整的错误日志
2. `python scripts/check_roop_server_cpu.py` 的输出
3. `python --version` 和 `python -m pip freeze`
4. `uname -a` 和 `lsb_release -a`
5. GPU 信息（若使用）: `nvidia-smi`

---

**文档版本**: 1.0  
**最后更新**: 2026-05-01  
**适用范围**: roop CPU headless 迁移版，Python 3.10+，Linux/Ubuntu 系统
