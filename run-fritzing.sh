#!/bin/bash
# Fritzing 一键启动脚本 (macOS/Linux)

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 设置资源路径
FRITZING_PARTS="$SCRIPT_DIR/fritzing-parts"

# 检测操作系统
OS="$(uname -s)"

case "$OS" in
    Darwin*)
        # macOS
        FRITZING_APP="$SCRIPT_DIR/release64/Fritzing.app/Contents/MacOS/Fritzing"
        if [ ! -f "$FRITZING_APP" ]; then
            echo "错误: 找不到 Fritzing 可执行文件"
            echo "请确保已经编译 Fritzing"
            exit 1
        fi
        echo "正在启动 Fritzing (macOS)..."
        "$FRITZING_APP" -f "$FRITZING_PARTS" &
        ;;
    Linux*)
        # Linux
        FRITZING_BIN="$SCRIPT_DIR/release64/Fritzing"
        if [ ! -f "$FRITZING_BIN" ]; then
            echo "错误: 找不到 Fritzing 可执行文件"
            echo "请确保已经编译 Fritzing"
            exit 1
        fi
        echo "正在启动 Fritzing (Linux)..."
        "$FRITZING_BIN" -f "$FRITZING_PARTS" &
        ;;
    *)
        echo "不支持的操作系统: $OS"
        exit 1
        ;;
esac

echo "Fritzing 已启动!"
