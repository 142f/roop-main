#!/usr/bin/env python3
"""
roop CPU Headless 服务器环境一键检查脚本

用途:
    验证服务器 CPU headless 环境是否完整满足 roop 推理的基础条件

使用:
    python scripts/check_roop_server_cpu.py

预期输出:
    - 所有依赖包版本
    - CPUExecutionProvider 可用
    - ffmpeg / ffprobe 路径
    - 必需模型文件存在
    - 通过/失败状态

依赖条件:
    - Python 3.10+
    - ffmpeg / ffprobe (系统安装)
    - models/inswapper_128.onnx
    - models/buffalo_l/
"""

import os
import shutil
import sys
from pathlib import Path

# 检查 Python 版本
if sys.version_info < (3, 10):
    print(f"错误: 需要 Python 3.10+，当前版本 {sys.version_info.major}.{sys.version_info.minor}")
    sys.exit(1)

def check_import(name: str) -> None:
    """检查模块是否可导入"""
    try:
        __import__(name)
        return True
    except ImportError as e:
        raise ImportError(f"无法导入 {name}: {e}")


def main() -> None:
    print("=" * 60)
    print("roop CPU Headless 服务器环境检查")
    print("=" * 60)
    print()

    # 1. Python 信息
    print("【1】Python 环境")
    print(f"  版本: {sys.version}")
    print(f"  路径: {sys.executable}")
    print()

    # 2. 检查依赖包
    print("【2】Python 依赖包")
    try:
        import numpy
        import cv2
        import onnx
        import onnxruntime as ort
        import tensorflow as tf
        import google.protobuf
        import insightface
        import psutil
        import PIL
        import tqdm

        versions = {
            "numpy": numpy.__version__,
            "cv2": cv2.__version__,
            "onnx": onnx.__version__,
            "onnxruntime": ort.__version__,
            "tensorflow": tf.__version__,
            "protobuf": google.protobuf.__version__,
            "insightface": insightface.__version__,
            "psutil": psutil.__version__,
            "Pillow": PIL.__version__,
            "tqdm": tqdm.__version__,
        }

        for name, version in versions.items():
            status = "✓" if version else "✗"
            print(f"  {status} {name:20} {version}")

    except ImportError as e:
        print(f"  ✗ 依赖包导入失败: {e}")
        sys.exit(1)

    print()

    # 3. 检查 ONNX Runtime Provider
    print("【3】ONNX Runtime 执行提供者")
    try:
        providers = ort.get_available_providers()
        print(f"  可用提供者: {providers}")

        if "CPUExecutionProvider" not in providers:
            print("  ✗ 错误: CPUExecutionProvider 不可用")
            sys.exit(1)
        else:
            print(f"  ✓ CPUExecutionProvider 可用")

    except Exception as e:
        print(f"  ✗ 检查失败: {e}")
        sys.exit(1)

    print()

    # 4. 检查 ffmpeg / ffprobe
    print("【4】FFmpeg 工具链")
    ffmpeg_bin = os.environ.get("ROOP_FFMPEG_BIN") or shutil.which("ffmpeg")
    ffprobe_bin = os.environ.get("ROOP_FFPROBE_BIN") or shutil.which("ffprobe")

    if not ffmpeg_bin:
        print("  ✗ ffmpeg 未找到")
        print("    解决方案:")
        print("      1. 安装系统 ffmpeg: sudo apt-get install -y ffmpeg")
        print("      2. 或设置环境变量: export ROOP_FFMPEG_BIN=/path/to/ffmpeg")
        sys.exit(1)
    else:
        print(f"  ✓ ffmpeg: {ffmpeg_bin}")

    if not ffprobe_bin:
        print("  ✗ ffprobe 未找到")
        print("    解决方案:")
        print("      1. 安装系统 ffmpeg: sudo apt-get install -y ffmpeg")
        print("      2. 或设置环境变量: export ROOP_FFPROBE_BIN=/path/to/ffprobe")
        sys.exit(1)
    else:
        print(f"  ✓ ffprobe: {ffprobe_bin}")

    print()

    # 5. 检查模型资源
    print("【5】必需模型资源")
    required_files = [
        "models/inswapper_128.onnx",
        "models/buffalo_l",
        "models/buffalo_l/det_10g.onnx",
        "models/buffalo_l/w600k_r50.onnx",
        "models/buffalo_l/1k3d68.onnx",
        "models/buffalo_l/2d106det.onnx",
        "models/buffalo_l/genderage.onnx",
    ]

    all_exist = True
    for file_path in required_files:
        path = Path(file_path)
        if path.exists():
            if path.is_file():
                size = f"({path.stat().st_size / (1024*1024):.2f} MB)"
            else:
                size = "(目录)"
            print(f"  ✓ {file_path:40} {size}")
        else:
            print(f"  ✗ {file_path:40} 缺失")
            all_exist = False

    if not all_exist:
        print("\n  错误: 模型资源不完整")
        print("  解决方案: 上传完整的 models/ 目录到服务器")
        sys.exit(1)

    print()

    # 6. 检查配置环境变量
    print("【6】roop 配置环境变量")
    allow_download = os.environ.get("ROOP_ALLOW_DOWNLOAD", "默认(0)")
    print(f"  ROOP_ALLOW_DOWNLOAD: {allow_download}")
    print(f"  ROOP_FFMPEG_BIN: {os.environ.get('ROOP_FFMPEG_BIN', '未设置(自动查询)')}")
    print(f"  ROOP_FFPROBE_BIN: {os.environ.get('ROOP_FFPROBE_BIN', '未设置(自动查询)')}")

    print()

    # 7. 最终结论
    print("=" * 60)
    print("✓ roop CPU headless 服务器基础环境检查通过")
    print("=" * 60)
    print()
    print("下一步:")
    print("  1. 执行离线推理测试: bash scripts/run_cpu_offline_test.sh")
    print("  2. 查看完整部署说明: cat DEPLOYMENT.md")
    print()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        print(f"\n✗ 检查失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
