@echo off
chcp 65001 >nul
REM Fritzing 一键启动脚本 (Windows)

REM 获取脚本所在目录
set "SCRIPT_DIR=%~dp0"

REM 设置资源路径
set "FRITZING_PARTS=%SCRIPT_DIR%fritzing-parts"

REM 设置可执行文件路径
set "FRITZING_EXE=%SCRIPT_DIR%release64\Fritzing.exe"

REM 检查可执行文件是否存在
if not exist "%FRITZING_EXE%" (
    echo 错误: 找不到 Fritzing 可执行文件
    echo 请确保已经编译 Fritzing
    pause
    exit /b 1
)

echo 正在启动 Fritzing (Windows)...
start "" "%FRITZING_EXE%" -f "%FRITZING_PARTS%"

echo Fritzing 已启动!
timeout /t 2 >nul
