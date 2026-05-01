#!/usr/bin/env bash
# roop CPU Headless 自动化部署初始化脚本
#
# 用途:
#   在新的 Linux 服务器上自动完成部署前的所有准备步骤
#
# 使用:
#   bash scripts/init_server_env.sh
#   或
#   bash scripts/init_server_env.sh /home/lxj/lx/roop-main
#
# 前置条件:
#   - Ubuntu 22.04+ / CentOS 8+
#   - sudo 权限
#   - 网络连接（用于 apt/yum 包安装）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-.}"

# 配置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 检查是否为 root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "此脚本需要 sudo 权限"
        exit 1
    fi
}

# 检测系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    log_info "检测到系统: $OS $VER"
}

# 更新包管理器
update_package_manager() {
    log_info "更新包管理器..."
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update -qq
        log_success "apt 更新完成"
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum update -y -q
        log_success "yum 更新完成"
    else
        log_warn "不支持的包管理器: $OS"
    fi
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖..."
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get install -y -qq \
            ffmpeg \
            python3.10 \
            python3.10-venv \
            python3.10-dev \
            build-essential \
            git \
            wget \
            curl
        log_success "Ubuntu/Debian 依赖安装完成"
        
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum install -y -q \
            ffmpeg \
            python3.10 \
            python3.10-devel \
            gcc \
            gcc-c++ \
            make \
            git \
            wget \
            curl
        log_success "CentOS/RHEL 依赖安装完成"
    fi
}

# 验证系统工具
verify_tools() {
    log_info "验证系统工具..."
    
    local tools=("ffmpeg" "ffprobe" "python3.10" "git")
    local missing=0
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=$("$tool" --version 2>&1 | head -1)
            log_success "$tool: $version"
        else
            log_error "$tool 未找到"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_error "部分系统工具缺失"
        exit 1
    fi
}

# 创建虚拟环境
create_venv() {
    log_info "创建 Python 虚拟环境..."
    
    if [ -d "$PROJECT_DIR/.venv_server" ]; then
        log_warn "虚拟环境已存在，跳过创建"
    else
        python3.10 -m venv "$PROJECT_DIR/.venv_server"
        log_success "虚拟环境创建完成: $PROJECT_DIR/.venv_server"
    fi
}

# 安装 Python 依赖
install_python_deps() {
    log_info "安装 Python 依赖包..."
    
    # 激活虚拟环境
    source "$PROJECT_DIR/.venv_server/bin/activate"
    
    # 升级 pip
    python -m pip install --upgrade --quiet pip setuptools wheel
    log_success "pip 升级完成"
    
    # 清理旧包
    log_info "清理旧的 OpenCV/ONNX Runtime 包..."
    python -m pip uninstall -y \
        opencv-python \
        opencv-python-headless \
        opencv-contrib-python \
        opencv-contrib-python-headless \
        onnxruntime \
        onnxruntime-gpu \
        2>/dev/null || true
    
    # 安装 CPU headless 依赖
    log_info "安装 requirements-server-cpu.txt..."
    python -m pip install --no-cache-dir -q -r "$PROJECT_DIR/requirements-server-cpu.txt"
    log_success "依赖包安装完成"
    
    # 验证安装
    log_info "验证依赖安装..."
    python -m pip check || log_warn "pip check 有警告（非致命）"
}

# 验证环境
verify_environment() {
    log_info "验证部署环境..."
    
    source "$PROJECT_DIR/.venv_server/bin/activate"
    
    # 运行检查脚本
    if [ -f "$PROJECT_DIR/scripts/check_roop_server_cpu.py" ]; then
        python "$PROJECT_DIR/scripts/check_roop_server_cpu.py"
        log_success "环境验证通过"
    else
        log_warn "找不到检查脚本"
    fi
}

# 生成激活脚本
create_activation_script() {
    log_info "生成激活脚本..."
    
    local activate_script="$PROJECT_DIR/activate.sh"
    
    cat > "$activate_script" << 'EOF'
#!/usr/bin/env bash
# roop CPU headless 快速激活脚本

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "激活 roop CPU headless 环境..."
echo "项目目录: $PROJECT_DIR"

source "$PROJECT_DIR/.venv_server/bin/activate"

export ROOP_ALLOW_DOWNLOAD=0
export ROOP_FFMPEG_BIN=${ROOP_FFMPEG_BIN:-/usr/bin/ffmpeg}
export ROOP_FFPROBE_BIN=${ROOP_FFPROBE_BIN:-/usr/bin/ffprobe}

echo "环境变量:"
echo "  ROOP_ALLOW_DOWNLOAD=$ROOP_ALLOW_DOWNLOAD"
echo "  ROOP_FFMPEG_BIN=$ROOP_FFMPEG_BIN"
echo "  ROOP_FFPROBE_BIN=$ROOP_FFPROBE_BIN"
echo ""
echo "已激活虚拟环境 (.venv_server)"
echo "使用示例:"
echo "  python run.py -s image.jpg -t video.mp4 -o output --execution-provider cpu"
echo "  bash scripts/run_cpu_offline_test.sh"
EOF
    
    chmod +x "$activate_script"
    log_success "激活脚本: $activate_script"
}

# 生成部署总结
generate_summary() {
    log_info "生成部署总结..."
    
    local summary_file="$PROJECT_DIR/DEPLOYMENT_SUMMARY.txt"
    
    cat > "$summary_file" << EOF
roop CPU Headless 部署完成总结
================================

部署时间: $(date)
操作系统: $OS $VER
项目目录: $PROJECT_DIR
虚拟环境: $PROJECT_DIR/.venv_server

已完成步骤:
  ✓ 系统依赖安装 (ffmpeg, python3.10, build tools)
  ✓ Python 虚拟环境创建
  ✓ Python 依赖包安装 (requirements-server-cpu.txt)
  ✓ 环境验证

后续步骤:
  1. 激活环境:
     source $PROJECT_DIR/activate.sh
     或
     source $PROJECT_DIR/.venv_server/bin/activate

  2. 验证环境:
     python scripts/check_roop_server_cpu.py

  3. 离线测试:
     bash scripts/run_cpu_offline_test.sh

  4. 实际推理:
     python run.py -s data/w700d1q75cms.jpg -t data/0.mp4 -o data/output \\
       --execution-provider cpu --keep-fps

关键文件:
  - 快速参考: $PROJECT_DIR/QUICKSTART.md
  - 完整文档: $PROJECT_DIR/DEPLOYMENT.md
  - 检查脚本: $PROJECT_DIR/scripts/check_roop_server_cpu.py
  - 测试脚本: $PROJECT_DIR/scripts/run_cpu_offline_test.sh

模型位置:
  - 主模型: $PROJECT_DIR/models/inswapper_128.onnx
  - 检测器: $PROJECT_DIR/models/buffalo_l/

环境变量配置:
  ROOP_ALLOW_DOWNLOAD=0 (禁用联网下载)
  ROOP_FFMPEG_BIN=/usr/bin/ffmpeg
  ROOP_FFPROBE_BIN=/usr/bin/ffprobe

故障排查:
  查看日志: tail -f $PROJECT_DIR/inference.log
  重新检查: python scripts/check_roop_server_cpu.py

联系支持:
  项目地址: https://github.com/142f/roop-main
  
完成日期: $(date)
EOF
    
    log_success "部署总结已保存: $summary_file"
    cat "$summary_file"
}

# 主函数
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  roop CPU Headless 自动化部署初始化脚本                ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # 执行部署步骤
    check_root
    detect_os
    update_package_manager
    install_system_deps
    verify_tools
    create_venv
    install_python_deps
    verify_environment
    create_activation_script
    generate_summary
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  ✓ 部署初始化完成！                                    ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "立即开始使用:"
    echo "  source $PROJECT_DIR/activate.sh"
    echo "  python scripts/check_roop_server_cpu.py"
    echo ""
}

# 运行主函数
main "$@"
