#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Code Statusline Windows 卸载脚本
.DESCRIPTION
    卸载 Claude Code 费用统计状态栏
#>

$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Claude Code Statusline 卸载程序 (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "确定要卸载 Claude Code Statusline 吗？(y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "已取消卸载" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "正在卸载..." -ForegroundColor Yellow

# 删除脚本文件
$FilesToDelete = @(
    "statusline.py",
    "calculate_today_stats.py",
    "usage_state.json"
)

foreach ($file in $FilesToDelete) {
    $filePath = Join-Path $ClaudeDir $file
    if (Test-Path $filePath) {
        Remove-Item $filePath -Force
        Write-Host "√ 已删除 $file" -ForegroundColor Green
    }
}

# 删除 core 目录
$CoreDir = Join-Path $ClaudeDir "core"
if (Test-Path $CoreDir) {
    Remove-Item $CoreDir -Recurse -Force
    Write-Host "√ 已删除 core 目录" -ForegroundColor Green
}

Write-Host ""
Write-Host "以下文件需要手动处理：" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. 计费配置文件（如需保留可跳过）："
Write-Host "   del `"$ClaudeDir\pricing_config.json`""
Write-Host ""
Write-Host "2. 从 settings.json 中移除 statusLine 配置："
Write-Host "   notepad `"$ClaudeDir\settings.json`""
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  卸载完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
