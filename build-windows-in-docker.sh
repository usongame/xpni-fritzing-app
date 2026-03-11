#!/bin/bash
# 使用 Docker 在 macOS 上构建 Windows 版本的 Fritzing

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="Fritzing"
VERSION="1.0.0"

echo "========================================"
echo "  使用 Docker 构建 Windows 版本"
echo "========================================"
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 未安装 Docker"
    echo "请先安装 Docker Desktop for Mac:"
    echo "https://www.docker.com/products/docker-desktop"
    exit 1
fi

# 创建 Dockerfile
cat > "$SCRIPT_DIR/Dockerfile.windows-build" << 'EOF'
FROM ubuntu:22.04

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    git \
    cmake \
    build-essential \
    mingw-w64 \
    mingw-w64-tools \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 安装 MXE (M cross environment) 用于交叉编译
RUN cd /opt && \
    git clone https://github.com/mxe/mxe.git && \
    cd mxe && \
    make MXE_TARGETS='x86_64-w64-mingw32.static' \
        qt6-qtbase \
        qt6-qtsvg \
        qt6-qttools \
        qt6-qt5compat \
        libgit2 \
        quazip \
        -j4

# 设置环境变量
ENV PATH="/opt/mxe/usr/bin:$PATH"
ENV MXE_DIR="/opt/mxe"

WORKDIR /build

# 构建脚本
COPY build-windows-docker.sh /build/
RUN chmod +x /build/build-windows-docker.sh

CMD ["/build/build-windows-docker.sh"]
EOF

# 创建 Docker 构建脚本
cat > "$SCRIPT_DIR/build-windows-docker.sh" << 'EOF'
#!/bin/bash
set -e

echo "在 Docker 中构建 Windows 版本..."

# 设置交叉编译环境
export TARGET=x86_64-w64-mingw32.static
export PATH="/opt/mxe/usr/bin:$PATH"

# 设置 Qt 工具
export QT_DIR="/opt/mxe/usr/x86_64-w64-mingw32.static/qt6"
export PATH="$QT_DIR/bin:$PATH"

# 进入项目目录
cd /build/fritzing

# 清理旧的构建
rm -rf release64
rm -rf dist

echo "配置项目..."
# 使用 MXE 的 qmake
/opt/mxe/usr/bin/x86_64-w64-mingw32.static-qmake-qt6 phoenix.pro

echo "编译..."
make -j$(nproc)

echo "创建发布包..."
mkdir -p dist/Fritzing-${VERSION}-Windows

# 复制可执行文件
cp release64/Fritzing.exe dist/Fritzing-${VERSION}-Windows/

# 复制资源文件
cp -r fritzing-parts dist/Fritzing-${VERSION}-Windows/

# 复制启动脚本
cp run-fritzing.bat dist/Fritzing-${VERSION}-Windows/

echo "Windows 构建完成!"
EOF

# 创建构建脚本
cat > "$SCRIPT_DIR/build-windows-via-docker.sh" << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  使用 Docker 构建 Windows 版本"
echo "========================================"
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker 未运行"
    echo "请启动 Docker Desktop"
    exit 1
fi

echo "构建 Docker 镜像..."
docker build -f "$SCRIPT_DIR/Dockerfile.windows-build" -t fritzing-windows-builder "$SCRIPT_DIR"

echo "运行构建容器..."
docker run --rm \
    -v "$SCRIPT_DIR:/build/fritzing" \
    -e VERSION="1.0.0" \
    fritzing-windows-builder

echo ""
echo "========================================"
echo "  Windows 构建完成!"
echo "========================================"
echo ""
echo "输出文件: $SCRIPT_DIR/dist/Fritzing-1.0.0-Windows/"
EOF

chmod +x "$SCRIPT_DIR/build-windows-via-docker.sh"
chmod +x "$SCRIPT_DIR/build-windows-docker.sh"

echo "Docker 构建脚本已创建!"
echo ""
echo "使用方法:"
echo "  ./build-windows-via-docker.sh"
echo ""
echo "注意: 首次运行需要下载和构建大量依赖，可能需要 1-2 小时"
