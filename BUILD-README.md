# Fritzing 构建与发布指南

## 项目结构

```
xpni-fritzing-app/
├── libs/                    # 编译依赖库
│   ├── boost_1_85_0/
│   ├── Clipper1/
│   ├── libgit2-1.7.1/
│   ├── ngspice-42/         # 完整的电路仿真库
│   ├── quazip-1.4/
│   ├── quazip-6.5.3-1.4/
│   └── svgpp-1.3.1/
├── fritzing-parts/          # 零件数据库
├── release64/               # 编译生成的应用程序
├── run-fritzing.sh          # macOS/Linux 启动脚本
├── run-fritzing.bat         # Windows 启动脚本
└── build-release.sh         # 跨平台发布构建脚本
```

## 一键启动

### macOS / Linux

```bash
./run-fritzing.sh
```

### Windows

双击运行：
```
run-fritzing.bat
```

或者在命令提示符中：
```cmd
run-fritzing.bat
```

## 构建发布包

### 交互式构建

```bash
./build-release.sh
```

然后选择要构建的平台：
- 1) macOS
- 2) Linux
- 3) Windows (创建构建脚本)
- 4) 全部平台

### 命令行直接构建

```bash
# macOS
./build-release.sh 1

# Linux
./build-release.sh 2

# Windows (仅创建构建脚本)
./build-release.sh 3

# 全部平台
./build-release.sh 4
```

## 各平台详细说明

### macOS

#### 要求
- macOS 10.14 或更高版本
- Xcode Command Line Tools
- Qt 6.5.3 (已安装在 ~/local/Qt6/)

#### 构建输出
- `dist/Fritzing-1.0.0-macOS.dmg` - DMG 安装包
- `dist/Fritzing-1.0.0-macOS.zip` - ZIP 压缩包

#### 手动构建
```bash
# 设置 Qt 路径
export PATH="$HOME/local/Qt6/6.5.3/macos/bin:$PATH"

# 编译
qmake phoenix.pro
make -j$(sysctl -n hw.ncpu)

# 运行
./release64/Fritzing.app/Contents/MacOS/Fritzing -f ./fritzing-parts
```

### Linux

#### 要求
- Ubuntu 20.04 / Debian 11 / Fedora 35 或更高版本
- Qt 6.5+ 开发包
- 构建工具链

#### 安装依赖
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    qt6-base-dev \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    libqt6svg6-dev \
    libgit2-dev \
    libquazip1-qt6-dev \
    libngspice0-dev \
    cmake

# Fedora
sudo dnf install -y \
    gcc-c++ \
    qt6-qtbase-devel \
    qt6-qtsvg-devel \
    libgit2-devel \
    quazip-qt6-devel \
    ngspice-devel \
    cmake
```

#### 构建输出
- `dist/Fritzing-1.0.0-linux.tar.gz` - tar.gz 压缩包
- `dist/Fritzing-1.0.0-Linux.AppImage` - AppImage (如果安装了 linuxdeployqt)

#### 手动构建
```bash
# 编译
qmake phoenix.pro
make -j$(nproc)

# 运行
./release64/Fritzing -f ./fritzing-parts
```

### Windows

#### 要求
- Windows 10/11
- Qt 6.5.3 for Windows (MinGW 或 MSVC)
- MinGW-w64 或 Visual Studio 2019/2022
- Git for Windows

#### 安装步骤

1. **安装 Qt**
   - 下载 Qt Online Installer
   - 安装 Qt 6.5.3 + MinGW 或 MSVC
   - 添加 Qt 的 bin 目录到 PATH

2. **安装编译器**
   - MinGW: 包含在 Qt 安装中
   - MSVC: 安装 Visual Studio Community

3. **克隆仓库**
   ```cmd
   git clone https://github.com/fritzing/fritzing-app.git
   cd fritzing-app
   ```

4. **编译**
   ```cmd
   qmake phoenix.pro
   mingw32-make -j4
   ```

5. **创建发布包**
   ```cmd
   build-release.bat
   ```

#### 构建输出
- `dist/Fritzing-1.0.0-Windows.zip` - ZIP 压缩包

## 发布包内容

每个平台的发布包都包含：
- Fritzing 可执行文件
- fritzing-parts 零件数据库
- 所有必要的依赖库
- 启动脚本

## 故障排除

### macOS

**问题**: "无法打开，因为无法验证开发者"
**解决**: 
```bash
xattr -cr ./release64/Fritzing.app
```

**问题**: 找不到 Qt
**解决**: 
```bash
export PATH="$HOME/local/Qt6/6.5.3/macos/bin:$PATH"
```

### Linux

**问题**: 缺少共享库
**解决**:
```bash
# 查看缺少的库
ldd ./release64/Fritzing

# 安装缺少的依赖
sudo apt-get install <missing-library>
```

### Windows

**问题**: 找不到 qmake
**解决**: 将 Qt 的 bin 目录添加到 PATH 环境变量

**问题**: 编译错误
**解决**: 确保使用与 Qt 安装匹配的编译器 (MinGW/MSVC)

## 版本信息

- Fritzing 版本: 1.0.0
- Qt 版本: 6.5.3
- ngspice 版本: 42

## 许可证

Fritzing 使用 GPL v3 许可证。

## 更多信息

- 官方网站: https://fritzing.org
- 文档: https://fritzing.org/learning
- GitHub: https://github.com/fritzing/fritzing-app
