# Fritzing 本地运行与打包发布指南

## 项目简介

Fritzing 是一个开源的电路设计软件，支持原理图设计、PCB 布局和电路仿真。

## 目录结构

```
xpni-fritzing-app/
├── src/                    # 源代码
├── libs/                   # 依赖库
│   ├── boost_1_85_0/      # Boost 库
│   ├── libgit2-1.7.1/     # Git 库
│   ├── quazip-1.4/        # ZIP 压缩库
│   ├── ngspice-42/        # 电路仿真库
│   ├── Clipper1/          # 多边形裁剪库
│   └── svgpp-1.3.1/       # SVG 解析库
├── fritzing-parts/        # 零件数据库
├── release64/             # 编译输出目录
├── run-fritzing.sh        # 启动脚本
├── build-release.sh       # 构建脚本
├── package-macos.sh       # macOS 打包脚本
└── BUILD-README.md        # 详细构建文档
```

---

## 快速开始

### 1. 一键启动

#### macOS / Linux

```bash
./run-fritzing.sh
```

#### Windows

```cmd
run-fritzing.bat
```

---

## 本地构建

### 环境要求

- **Qt 6.5.3** (已安装在 `~/local/Qt6/`)
- **编译工具**:
  - macOS: Xcode Command Line Tools
  - Linux: GCC/G++
  - Windows: MinGW 或 MSVC

### 依赖库

所有依赖库已包含在 `libs/` 目录中：

| 库 | 版本 | 用途 |
|----|------|------|
| Boost | 1.85.0 | C++ 工具库 |
| libgit2 | 1.7.1 | Git 操作 |
| quazip | 1.4 | ZIP 压缩 |
| ngspice | 42 | 电路仿真 |
| Clipper1 | 6.4.2 | 多边形裁剪 |
| svgpp | 1.3.1 | SVG 解析 |

### 构建步骤

#### macOS

```bash
# 1. 设置 Qt 环境
export PATH="$HOME/local/Qt6/6.5.3/macos/bin:$PATH"

# 2. 编译
qmake phoenix.pro
make -j$(sysctl -n hw.ncpu)

# 3. 运行
./release64/Fritzing.app/Contents/MacOS/Fritzing -f ./fritzing-parts
```

#### Linux

```bash
# 1. 安装依赖
sudo apt-get install -y build-essential libgl1-mesa-dev

# 2. 编译
qmake phoenix.pro
make -j$(nproc)

# 3. 运行
./release64/Fritzing -f ./fritzing-parts
```

#### Windows

```cmd
# 1. 设置 Qt 环境
set PATH=C:\Qt\6.5.3\mingw_64\bin;%PATH%

# 2. 编译
qmake phoenix.pro
mingw32-make -j4

# 3. 运行
release64\Fritzing.exe -f fritzing-parts
```

---

## 打包发布

### 使用构建脚本

```bash
# 交互式构建
./build-release.sh

# 直接构建 macOS
./build-release.sh 1

# 直接构建 Linux
./build-release.sh 2

# 直接构建 Windows (创建脚本)
./build-release.sh 3

# 构建所有平台
./build-release.sh 4
```

### macOS 本地打包

```bash
# 1. 先编译项目
./build-release.sh 1

# 2. 打包应用
./package-macos.sh
```

输出文件：
- `dist/Fritzing-1.0.0-macOS.dmg` - DMG 安装包
- `dist/Fritzing-1.0.0-macOS.zip` - ZIP 压缩包

### 手动打包 macOS

```bash
# 1. 复制依赖库
cp libs/ngspice-42/lib/libngspice.0.dylib release64/Fritzing.app/Contents/Frameworks/

# 2. 使用 macdeployqt 部署 Qt
macdeployqt release64/Fritzing.app

# 3. 创建 DMG
hdiutil create -volname "Fritzing" -srcfolder release64/Fritzing.app -ov -format UDZO Fritzing.dmg
```

---

## GitHub Actions 自动构建

项目已配置 GitHub Actions，支持自动构建：

- **触发条件**: push 到 main/master 分支
- **构建平台**: macOS、Linux、Windows
- **输出产物**: DMG、ZIP、AppImage

### 查看构建状态

访问: https://github.com/usongame/xpni-fritzing-app/actions

### 下载构建产物

1. 打开 Actions 页面
2. 点击最新的 workflow run
3. 在 Artifacts 部分下载对应平台的构建包

---

## 常见问题

### Q: 找不到 Qt

**A**: 确保 Qt 已安装并添加到 PATH

```bash
# macOS
export PATH="$HOME/local/Qt6/6.5.3/macos/bin:$PATH"

# Linux
export PATH="/opt/Qt/6.5.3/gcc_64/bin:$PATH"
```

### Q: 找不到依赖库

**A**: 所有依赖库已包含在 `libs/` 目录中，无需额外安装

### Q: macOS 提示"无法验证开发者"

**A**: 使用以下命令移除隔离属性

```bash
xattr -cr release64/Fritzing.app
```

### Q: 电路仿真不工作

**A**: 确保 ngspice 库已正确链接

```bash
# 检查库路径
otool -L release64/Fritzing.app/Contents/MacOS/Fritzing | grep ngspice
```

### Q: 零件库加载失败

**A**: 使用 `-f` 参数指定零件库路径

```bash
./release64/Fritzing.app/Contents/MacOS/Fritzing -f ./fritzing-parts
```

---

## 发布流程

### 1. 版本号更新

编辑 `package-macos.sh` 中的 VERSION 变量：

```bash
VERSION="1.0.1"  # 更新版本号
```

### 2. 本地测试

```bash
# 编译并运行测试
./build-release.sh 1
./run-fritzing.sh
```

### 3. 打包发布

```bash
# 创建发布包
./package-macos.sh
```

### 4. 上传到 GitHub Releases

1. 打开 GitHub 仓库页面
2. 点击 Releases
3. 创建新 Release
4. 上传 DMG/ZIP 文件

---

## 技术支持

- **官方文档**: https://fritzing.org/learning
- **GitHub**: https://github.com/fritzing/fritzing-app
- **问题反馈**: 在 GitHub Issues 中提交

---

## 许可证

Fritzing 使用 GPL v3 许可证。
