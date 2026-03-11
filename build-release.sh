#!/bin/bash
# Fritzing 跨平台发布构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="Fritzing"
VERSION="1.0.0"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Fritzing 跨平台发布构建脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检测操作系统
OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "${YELLOW}检测到的系统: $OS $ARCH${NC}"
echo ""

# 清理旧的构建
cleanup() {
    echo -e "${YELLOW}清理旧的构建文件...${NC}"
    rm -rf "$SCRIPT_DIR/release64"
    rm -rf "$SCRIPT_DIR/dist"
}

# 构建函数
build_macos() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  构建 macOS 版本${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 检查 Qt
    if [ ! -d "$HOME/local/Qt6/6.5.3/macos" ]; then
        echo -e "${RED}错误: 找不到 Qt 6.5.3${NC}"
        echo "请确保 Qt 安装在 $HOME/local/Qt6/6.5.3/macos"
        exit 1
    fi
    
    export PATH="$HOME/local/Qt6/6.5.3/macos/bin:$PATH"
    
    # 清理
    cleanup
    
    # 编译
    echo -e "${YELLOW}正在编译...${NC}"
    cd "$SCRIPT_DIR"
    qmake phoenix.pro
    make -j$(sysctl -n hw.ncpu)
    
    # 创建发布包
    echo -e "${YELLOW}创建发布包...${NC}"
    mkdir -p "$SCRIPT_DIR/dist"
    
    # 复制依赖库到 app bundle
    local APP_BUNDLE="$SCRIPT_DIR/release64/Fritzing.app"
    local FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
    
    mkdir -p "$FRAMEWORKS_DIR"
    
    # 复制 ngspice 库
    if [ -f "$SCRIPT_DIR/libs/ngspice-42/lib/libngspice.0.dylib" ]; then
        cp "$SCRIPT_DIR/libs/ngspice-42/lib/libngspice.0.dylib" "$FRAMEWORKS_DIR/"
        install_name_tool -change libngspice.0.dylib "@executable_path/../Frameworks/libngspice.0.dylib" "$APP_BUNDLE/Contents/MacOS/Fritzing"
    fi
    
    # 使用 macdeployqt 部署 Qt 依赖
    if command -v macdeployqt &> /dev/null; then
        macdeployqt "$APP_BUNDLE" -dmg
        mv "$SCRIPT_DIR/release64/Fritzing.dmg" "$SCRIPT_DIR/dist/Fritzing-$VERSION-macOS.dmg"
        echo -e "${GREEN}macOS DMG 包已创建: dist/Fritzing-$VERSION-macOS.dmg${NC}"
    fi
    
    # 创建 zip 包
    cd "$SCRIPT_DIR/release64"
    zip -r "$SCRIPT_DIR/dist/Fritzing-$VERSION-macOS.zip" "Fritzing.app"
    echo -e "${GREEN}macOS ZIP 包已创建: dist/Fritzing-$VERSION-macOS.zip${NC}"
    
    echo -e "${GREEN}macOS 构建完成!${NC}"
}

build_linux() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  构建 Linux 版本${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 检查依赖
    if ! command -v qmake &> /dev/null; then
        echo -e "${RED}错误: 找不到 qmake${NC}"
        echo "请安装 Qt 开发包: sudo apt-get install qt6-base-dev qt6-tools-dev"
        exit 1
    fi
    
    # 清理
    cleanup
    
    # 编译
    echo -e "${YELLOW}正在编译...${NC}"
    cd "$SCRIPT_DIR"
    qmake phoenix.pro
    make -j$(nproc)
    
    # 创建发布包
    echo -e "${YELLOW}创建发布包...${NC}"
    mkdir -p "$SCRIPT_DIR/dist"
    mkdir -p "$SCRIPT_DIR/dist/linux/Fritzing-$VERSION"
    
    # 复制文件
    cp -r "$SCRIPT_DIR/release64/Fritzing" "$SCRIPT_DIR/dist/linux/Fritzing-$VERSION/"
    cp -r "$SCRIPT_DIR/fritzing-parts" "$SCRIPT_DIR/dist/linux/Fritzing-$VERSION/"
    cp "$SCRIPT_DIR/run-fritzing.sh" "$SCRIPT_DIR/dist/linux/Fritzing-$VERSION/"
    
    # 复制依赖库
    if [ -f "$SCRIPT_DIR/libs/ngspice-42/lib/libngspice.so.0" ]; then
        cp "$SCRIPT_DIR/libs/ngspice-42/lib/libngspice.so.0" "$SCRIPT_DIR/dist/linux/Fritzing-$VERSION/"
    fi
    
    # 创建 AppImage (如果安装了 linuxdeployqt)
    if command -v linuxdeployqt &> /dev/null; then
        echo -e "${YELLOW}创建 AppImage...${NC}"
        # 创建 AppDir 结构
        mkdir -p "$SCRIPT_DIR/dist/AppDir/usr/bin"
        mkdir -p "$SCRIPT_DIR/dist/AppDir/usr/lib"
        mkdir -p "$SCRIPT_DIR/dist/AppDir/usr/share/applications"
        mkdir -p "$SCRIPT_DIR/dist/AppDir/usr/share/icons/hicolor/256x256/apps"
        
        cp "$SCRIPT_DIR/release64/Fritzing" "$SCRIPT_DIR/dist/AppDir/usr/bin/"
        cp -r "$SCRIPT_DIR/fritzing-parts" "$SCRIPT_DIR/dist/AppDir/usr/share/fritzing/"
        
        # 创建 desktop 文件
        cat > "$SCRIPT_DIR/dist/AppDir/usr/share/applications/fritzing.desktop" << EOF
[Desktop Entry]
Name=Fritzing
Exec=Fritzing
Icon=fritzing
Type=Application
Categories=Development;Electronics;
EOF
        
        linuxdeployqt "$SCRIPT_DIR/dist/AppDir/usr/share/applications/fritzing.desktop" -appimage
        mv Fritzing*.AppImage "$SCRIPT_DIR/dist/Fritzing-$VERSION-Linux.AppImage"
        echo -e "${GREEN}Linux AppImage 已创建: dist/Fritzing-$VERSION-Linux.AppImage${NC}"
    fi
    
    # 创建 tar.gz 包
    cd "$SCRIPT_DIR/dist/linux"
    tar -czf "$SCRIPT_DIR/dist/Fritzing-$VERSION-linux.tar.gz" "Fritzing-$VERSION"
    echo -e "${GREEN}Linux tar.gz 包已创建: dist/Fritzing-$VERSION-linux.tar.gz${NC}"
    
    echo -e "${GREEN}Linux 构建完成!${NC}"
}

build_windows() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  Windows 构建说明${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Windows 构建需要在 Windows 系统上进行。"
    echo "请按照以下步骤操作:"
    echo ""
    echo "1. 安装 Qt 6.5.3 for Windows"
    echo "2. 安装 MinGW 或 MSVC 编译器"
    echo "3. 安装 Git for Windows"
    echo "4. 在命令提示符中运行:"
    echo ""
    echo "   cd xpni-fritzing-app"
    echo "   qmake phoenix.pro"
    echo "   mingw32-make -j4"
    echo ""
    echo "5. 运行 build-release.bat 创建发布包"
    echo ""
    
    # 创建 Windows 构建脚本
    cat > "$SCRIPT_DIR/build-release.bat" << 'EOF'
@echo off
chcp 65001 >nul
REM Fritzing Windows 发布构建脚本

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "VERSION=1.0.0"
set "PROJECT_NAME=Fritzing"

echo ========================================
echo   Fritzing Windows 发布构建脚本
echo ========================================
echo.

REM 检查 Qt
where qmake >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 找不到 qmake
    echo 请确保 Qt 已安装并添加到 PATH
    pause
    exit /b 1
)

echo 清理旧的构建文件...
if exist "%SCRIPT_DIR%release64" rmdir /s /q "%SCRIPT_DIR%release64"
if exist "%SCRIPT_DIR%dist" rmdir /s /q "%SCRIPT_DIR%dist"

echo 正在编译...
cd /d "%SCRIPT_DIR%"
qmake phoenix.pro
mingw32-make -j4

if %errorlevel% neq 0 (
    echo 编译失败!
    pause
    exit /b 1
)

echo 创建发布包...
mkdir "%SCRIPT_DIR%dist"
mkdir "%SCRIPT_DIR%dist\Fritzing-%VERSION%-Windows"

REM 复制可执行文件
xcopy /s /e /i "%SCRIPT_DIR%release64\*" "%SCRIPT_DIR%dist\Fritzing-%VERSION%-Windows\"

REM 复制资源文件
xcopy /s /e /i "%SCRIPT_DIR%fritzing-parts" "%SCRIPT_DIR%dist\Fritzing-%VERSION%-Windows\fritzing-parts\"

REM 复制启动脚本
copy "%SCRIPT_DIR%run-fritzing.bat" "%SCRIPT_DIR%dist\Fritzing-%VERSION%-Windows\"

REM 使用 windeployqt 部署 Qt 依赖
if exist "%QTDIR%\bin\windeployqt.exe" (
    "%QTDIR%\bin\windeployqt.exe" "%SCRIPT_DIR%dist\Fritzing-%VERSION%-Windows\Fritzing.exe"
)

REM 创建 ZIP 包
cd /d "%SCRIPT_DIR%dist"
powershell -Command "Compress-Archive -Path 'Fritzing-%VERSION%-Windows' -DestinationPath 'Fritzing-%VERSION%-Windows.zip'"

echo.
echo Windows ZIP 包已创建: dist\Fritzing-%VERSION%-Windows.zip
echo.
echo 构建完成!
pause
EOF
    
    echo -e "${GREEN}Windows 构建脚本已创建: build-release.bat${NC}"
}

# 主菜单
show_menu() {
    echo "请选择构建目标:"
    echo ""
    echo "1) macOS"
    echo "2) Linux"
    echo "3) Windows (创建构建脚本)"
    echo "4) 全部平台"
    echo "5) 退出"
    echo ""
}

# 根据参数或交互式选择构建目标
if [ $# -eq 0 ]; then
    show_menu
    read -p "请输入选项 (1-5): " choice
else
    choice=$1
fi

case "$choice" in
    1)
        if [[ "$OS" == "Darwin"* ]]; then
            build_macos
        else
            echo -e "${RED}错误: 当前不是 macOS 系统${NC}"
            exit 1
        fi
        ;;
    2)
        if [[ "$OS" == "Linux"* ]]; then
            build_linux
        else
            echo -e "${RED}错误: 当前不是 Linux 系统${NC}"
            exit 1
        fi
        ;;
    3)
        build_windows
        ;;
    4)
        if [[ "$OS" == "Darwin"* ]]; then
            build_macos
        elif [[ "$OS" == "Linux"* ]]; then
            build_linux
        fi
        build_windows
        ;;
    5)
        echo "退出"
        exit 0
        ;;
    *)
        echo -e "${RED}无效选项${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  构建完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "发布包位于: $SCRIPT_DIR/dist/"
echo ""
ls -lh "$SCRIPT_DIR/dist/"
