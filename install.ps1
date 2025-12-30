#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Code Statusline Windows 安装脚本
.DESCRIPTION
    为 Claude Code 安装费用统计状态栏
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Statusline 安装程序 (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查依赖
Write-Host "[1/5] 检查依赖..." -ForegroundColor Yellow

try {
    $pythonVersion = python --version 2>&1
    Write-Host "  √ Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "× 错误: 需要安装 Python 3" -ForegroundColor Red
    Write-Host "  请从 https://www.python.org/downloads/ 下载安装" -ForegroundColor Yellow
    exit 1
}

Write-Host "√ 依赖检查通过" -ForegroundColor Green
Write-Host ""

# 创建目录
Write-Host "[2/5] 创建目录..." -ForegroundColor Yellow
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
}
Write-Host "√ 目录已就绪: $ClaudeDir" -ForegroundColor Green
Write-Host ""

# 复制脚本
Write-Host "[3/5] 复制脚本..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\scripts\statusline.py" "$ClaudeDir\" -Force
Copy-Item "$ScriptDir\scripts\calculate_today_stats.py" "$ClaudeDir\" -Force

# 复制 core 模块
$CoreDir = Join-Path $ClaudeDir "core"
if (-not (Test-Path $CoreDir)) {
    New-Item -ItemType Directory -Path $CoreDir | Out-Null
}
Copy-Item "$ScriptDir\scripts\core\*" "$CoreDir\" -Force
Write-Host "√ 脚本已复制" -ForegroundColor Green
Write-Host ""

# 复制配置
Write-Host "[4/5] 配置计费规则..." -ForegroundColor Yellow
$PricingConfig = Join-Path $ClaudeDir "pricing_config.json"
if (Test-Path $PricingConfig) {
    Copy-Item $PricingConfig "$PricingConfig.bak" -Force
    Write-Host "! 发现已有计费配置，已备份为 pricing_config.json.bak" -ForegroundColor Yellow
}
Copy-Item "$ScriptDir\config\pricing_config.json" "$ClaudeDir\" -Force
Write-Host "√ 计费配置已复制" -ForegroundColor Green
Write-Host ""

# 更新 settings.json
Write-Host "[5/5] 更新 Claude Code 设置..." -ForegroundColor Yellow
$SettingsFile = Join-Path $ClaudeDir "settings.json"

# 构建 statusline.py 的完整路径
$StatuslinePath = Join-Path $ClaudeDir "statusline.py"
$StatuslineCommand = "python `"$StatuslinePath`""

if (Test-Path $SettingsFile) {
    Copy-Item $SettingsFile "$SettingsFile.bak" -Force
    Write-Host "! 已备份现有设置为 settings.json.bak" -ForegroundColor Yellow

    $Settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json

    # 检查是否已有 statusLine 配置
    if ($Settings.PSObject.Properties.Name -contains "statusLine") {
        Write-Host "! 检测到已有 statusLine 配置，将更新" -ForegroundColor Yellow
    }

    # 添加或更新 statusLine 配置
    $StatusLineConfig = @{
        type = "command"
        command = $StatuslineCommand
        padding = 0
    }

    if ($Settings.PSObject.Properties.Name -contains "statusLine") {
        $Settings.statusLine = $StatusLineConfig
    } else {
        $Settings | Add-Member -NotePropertyName "statusLine" -NotePropertyValue $StatusLineConfig
    }

    $Settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
} else {
    # 创建新的 settings.json
    @{
        statusLine = @{
            type = "command"
            command = $StatuslineCommand
            padding = 0
        }
    } | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
}
Write-Host "√ 已更新 settings.json" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 编辑计费规则（根据你的 API 服务商调整）："
Write-Host "   notepad $ClaudeDir\pricing_config.json"
Write-Host ""
Write-Host "2. 重启 Claude Code 使配置生效"
Write-Host ""
Write-Host "3. 如需卸载，运行："
Write-Host "   .\uninstall.ps1"
Write-Host ""
