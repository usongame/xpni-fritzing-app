#!/bin/bash
# Fritzing macOS 本地打包脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Fritzing"
VERSION="1.0.0"

# 注意：编译输出在 xpni/release64/，而不是 xpni/xpni-fritzing-app/release64/
RELEASE_DIR="$(dirname "$SCRIPT_DIR")/release64"

echo "========================================"
echo "  Fritzing macOS 打包脚本"
echo "========================================"
echo ""
echo "项目目录: $SCRIPT_DIR"
echo "编译输出: $RELEASE_DIR"
echo ""

# 检查 Qt 环境
if ! command -v qmake &> /dev/null; then
    echo "设置 Qt 环境..."
    export PATH="$HOME/local/Qt6/6.5.3/macos/bin:$PATH"
fi

# 检查是否已编译
if [ ! -f "$RELEASE_DIR/Fritzing.app/Contents/MacOS/Fritzing" ]; then
    echo "错误: 找不到 Fritzing 可执行文件"
    echo "路径: $RELEASE_DIR/Fritzing.app/Contents/MacOS/Fritzing"
    echo ""
    echo "请先编译项目:"
    echo "  cd $SCRIPT_DIR"
    echo "  export PATH=\"\$HOME/local/Qt6/6.5.3/macos/bin:\$PATH\""
    echo "  qmake phoenix.pro"
    echo "  make -j\$(sysctl -n hw.ncpu)"
    exit 1
fi

echo "✓ 找到 Fritzing 可执行文件"
echo ""

# 创建 dist 目录
mkdir -p "$SCRIPT_DIR/dist"

echo "1. 复制依赖库到 app bundle..."
APP_BUNDLE="$RELEASE_DIR/Fritzing.app"
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"

# 复制 ngspice 库
if [ -f "$SCRIPT_DIR/libs/ngspice-42/lib/libngspice.0.dylib" ]; then
    echo "  - 复制 ngspice 库..."
    cp "$SCRIPT_DIR/libs/ngspice-42/lib/libngspice.0.dylib" "$FRAMEWORKS_DIR/"
    # 修改库路径
    install_name_tool -change libngspice.0.dylib "@executable_path/../Frameworks/libngspice.0.dylib" "$APP_BUNDLE/Contents/MacOS/Fritzing" 2>/dev/null || echo "    警告: 无法修改库路径"
fi

# 复制 quazip 库
if [ -f "$SCRIPT_DIR/libs/quazip-6.5.3-1.4/lib/libquazip1-qt6.1.dylib" ]; then
    echo "  - 复制 quazip 库..."
    cp "$SCRIPT_DIR/libs/quazip-6.5.3-1.4/lib/libquazip1-qt6"*.dylib "$FRAMEWORKS_DIR/"
fi

# 复制 libgit2 库 (如果是动态链接)
if [ -f "$SCRIPT_DIR/libs/libgit2-1.7.1/lib/libgit2.dylib" ]; then
    echo "  - 复制 libgit2 库..."
    cp "$SCRIPT_DIR/libs/libgit2-1.7.1/lib/libgit2"*.dylib "$FRAMEWORKS_DIR/"
fi

echo ""
echo "2. 使用 macdeployqt 部署 Qt 依赖..."
if command -v macdeployqt &> /dev/null; then
    macdeployqt "$APP_BUNDLE" -verbose=2
else
    echo "警告: 找不到 macdeployqt，跳过 Qt 依赖部署"
    echo "请确保 Qt 的 bin 目录在 PATH 中"
fi

echo ""
echo "3. 复制资源文件..."
# 复制 fritzing-parts 到 app bundle 根目录（Fritzing 从 MacOS 向上两级查找）
if [ -d "$SCRIPT_DIR/fritzing-parts" ]; then
    echo "  - 复制 fritzing-parts..."
    # 先删除已存在的 fritzing-parts 目录
    rm -rf "$APP_BUNDLE/fritzing-parts"
    mkdir -p "$APP_BUNDLE/fritzing-parts"
    # 使用 tar 复制，排除 .git 目录
    tar -C "$SCRIPT_DIR/fritzing-parts" -cf - --exclude='.git' . | tar -C "$APP_BUNDLE/fritzing-parts" -xf - 2>/dev/null || \
    echo "    警告: 复制 fritzing-parts 时出现权限问题，继续..."
fi

echo ""
echo "4. 签名应用 (可选)..."
if command -v codesign &> /dev/null; then
    echo "  正在签名应用..."
    codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "  签名失败，继续..."
fi

echo ""
echo "5. 创建 DMG 安装包..."
DMG_NAME="Fritzing-${VERSION}-macOS.dmg"

# 创建临时目录
TMP_DIR=$(mktemp -d)
cp -r "$APP_BUNDLE" "$TMP_DIR/"

# 创建符号链接到 Applications
ln -s /Applications "$TMP_DIR/Applications"

# 创建 DMG
hdiutil create -volname "Fritzing ${VERSION}" \
    -srcfolder "$TMP_DIR" \
    -ov -format UDZO \
    "$SCRIPT_DIR/dist/${DMG_NAME}" 2>/dev/null || {
    echo "警告: DMG 创建失败，尝试创建 ZIP..."
}

# 清理临时目录
rm -rf "$TMP_DIR"

echo ""
echo "6. 创建 ZIP 压缩包..."
ZIP_NAME="Fritzing-${VERSION}-macOS.zip"
cd "$RELEASE_DIR"
zip -r "$SCRIPT_DIR/dist/${ZIP_NAME}" "Fritzing.app" -x "*.DS_Store"

echo ""
echo "========================================"
echo "  打包完成!"
echo "========================================"
echo ""
echo "输出文件:"
if [ -f "$SCRIPT_DIR/dist/${DMG_NAME}" ]; then
    echo "  - DMG: $SCRIPT_DIR/dist/${DMG_NAME}"
fi
echo "  - ZIP: $SCRIPT_DIR/dist/${ZIP_NAME}"
echo ""
echo "安装方法:"
echo "  1. 双击 DMG 文件"
echo "  2. 将 Fritzing 拖到 Applications 文件夹"
echo ""
