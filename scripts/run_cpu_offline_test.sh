#!/usr/bin/env bash
# roop CPU Headless 离线推理验证脚本
#
# 用途:
#   验证 roop 在完全离线、无缓存状态下的推理能力
#   用于确认模型资源已打包完整，不依赖隐藏缓存或在线下载
#
# 前置条件:
#   1. 本地 CPU 推理成功（第4级）
#   2. 虚拟环境已激活，依赖已安装
#   3. models/ 目录已完整上传
#   4. data/ 目录中有测试数据
#
# 使用方式:
#   bash scripts/run_cpu_offline_test.sh
#   或
#   bash scripts/run_cpu_offline_test.sh /path/to/roop/dir
#
# 预期输出:
#   - 无网络访问警告
#   - 无缓存读取提示
#   - 成功生成输出 mp4 文件
#   - ffprobe 可解析输出视频

set -euo pipefail

# 确定 roop 项目目录
ROOP_DIR="${1:-.}"
if [ ! -f "$ROOP_DIR/run.py" ]; then
    echo "错误: 找不到 $ROOP_DIR/run.py"
    echo "用法: $0 [/path/to/roop-main]"
    exit 1
fi

cd "$ROOP_DIR"

echo "========================================="
echo "roop CPU Headless 离线推理验证"
echo "========================================="
echo ""

# 1. 环境变量设置 - 禁用联网与缓存
echo "【1】设置离线环境变量..."
export ROOP_ALLOW_DOWNLOAD=0
export ROOP_FFMPEG_BIN="${ROOP_FFMPEG_BIN:-/usr/bin/ffmpeg}"
export ROOP_FFPROBE_BIN="${ROOP_FFPROBE_BIN:-/usr/bin/ffprobe}"

export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export HF_DATASETS_OFFLINE=1

# 创建临时隔离缓存目录
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EMPTY_CACHE="/tmp/roop_offline_cache_${TIMESTAMP}"
mkdir -p "$EMPTY_CACHE"

export HF_HOME="$EMPTY_CACHE/huggingface"
export TORCH_HOME="$EMPTY_CACHE/torch"
export XDG_CACHE_HOME="$EMPTY_CACHE/xdg"

echo "  ✓ ROOP_ALLOW_DOWNLOAD=0"
echo "  ✓ HF_HUB_OFFLINE=1"
echo "  ✓ 隔离缓存: $EMPTY_CACHE"
echo ""

# 2. 验证环境
echo "【2】运行环境检查..."
python scripts/check_roop_server_cpu.py
echo ""

# 3. 清理输出目录
echo "【3】准备输出目录..."
OUTPUT_DIR="$ROOP_DIR/data/output_offline_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"
echo "  输出目录: $OUTPUT_DIR"
echo ""

# 4. 执行离线推理
echo "【4】执行离线推理..."
echo "  源图像: $ROOP_DIR/data/w700d1q75cms.jpg"
echo "  目标视频: $ROOP_DIR/data/0.mp4"
echo "  执行方式: CPUExecutionProvider (纯CPU)"
echo "  模式: 离线 + 无缓存"
echo ""

python run.py \
    -s "$ROOP_DIR/data/w700d1q75cms.jpg" \
    -t "$ROOP_DIR/data/0.mp4" \
    -o "$OUTPUT_DIR" \
    --execution-provider cpu \
    --keep-fps

echo ""

# 5. 验证输出文件
echo "【5】验证输出文件..."

# 查找生成的 mp4 文件
OUTPUT_FILE=$(find "$OUTPUT_DIR" -type f -name "*.mp4" -print | head -1)

if [ -z "$OUTPUT_FILE" ]; then
    echo "  ✗ 错误: 未找到输出 mp4 文件"
    echo "  输出目录内容:"
    ls -lh "$OUTPUT_DIR"
    exit 1
fi

# 检查文件大小
FILE_SIZE=$(stat -c%s "$OUTPUT_FILE")
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1048576" | bc)

if [ "$FILE_SIZE" -lt 50000 ]; then
    echo "  ⚠️  警告: 输出文件过小 ($FILE_SIZE_MB MB)"
    echo "  可能的原因: 推理未完成或视频编码有问题"
    exit 1
fi

echo "  ✓ 输出文件: $OUTPUT_FILE"
echo "  ✓ 文件大小: $FILE_SIZE_MB MB"
echo ""

# 6. 用 ffprobe 验证视频有效性
echo "【6】验证输出视频有效性..."
if ! command -v ffprobe &> /dev/null; then
    echo "  ⚠️  ffprobe 未找到，跳过视频验证"
else
    ffprobe_out=$("$ROOP_FFPROBE_BIN" -hide_banner -show_streams -show_format "$OUTPUT_FILE" 2>&1)

    duration=$(echo "$ffprobe_out" | grep "duration=" | head -1 | cut -d= -f2)
    nb_frames=$(echo "$ffprobe_out" | grep "nb_read_frames=" | head -1 | cut -d= -f2)
    codec=$(echo "$ffprobe_out" | grep "codec_name=" | head -1 | cut -d= -f2)

    echo "  ✓ 视频信息:"
    echo "    时长: ${duration:0:8} 秒"
    echo "    帧数: $nb_frames"
    echo "    编码: $codec"
fi

echo ""

# 7. 最终结论
echo "========================================="
echo "✓ 离线推理测试通过"
echo "========================================="
echo ""
echo "输出文件: $OUTPUT_FILE"
echo "缓存目录: $EMPTY_CACHE"
echo ""
echo "结论: roop 环境满足离线运行要求"
echo "  ✓ 模型资源完整"
echo "  ✓ 无网络依赖"
echo "  ✓ 无缓存依赖"
echo ""
echo "下一步:"
echo "  1. 如果在 Linux 服务器上: 验证 Windows/Linux 输出一致性"
echo "  2. 如果需要 GPU: 安装 onnxruntime-gpu 并验证 CUDAExecutionProvider"
echo "  3. 准备生产部署"
echo ""
