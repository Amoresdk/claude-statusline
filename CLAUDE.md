# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Claude Code Statusline 是一个为 Claude Code 添加实时费用统计状态栏的工具。支持 macOS/Linux 和 Windows 双平台。

## 常用命令

```bash
# macOS/Linux 安装
./install.sh

# Windows 安装 (PowerShell)
.\install.ps1

# macOS/Linux 卸载
./uninstall.sh

# Windows 卸载
.\uninstall.ps1

# 测试状态栏
echo '{}' | ~/.claude/statusline.sh      # macOS/Linux
echo '{}' | python ~/.claude/statusline.py  # Windows

# 重置统计
rm ~/.claude/usage_state.json
```

## 架构

```
scripts/
├── core/                    # 跨平台核心模块
│   ├── __init__.py
│   ├── file_lock.py        # 跨平台文件锁（fcntl/msvcrt）
│   └── paths.py            # 跨平台路径处理
├── calculate_today_stats.py # 费用计算引擎（使用 core 模块）
├── statusline.sh           # Bash 状态栏（macOS/Linux）
└── statusline.py           # Python 状态栏（Windows/跨平台）
```

**核心模块说明：**
- `core/file_lock.py`：Unix 使用 `fcntl.flock()`，Windows 使用 `msvcrt.locking()`
- `core/paths.py`：处理 Unix/Windows 路径差异，包括盘符处理

## 计费逻辑

```
quota = (input + cache_read × cache_ratio + cache_creation × cache_creation_ratio + output × completion_ratio) × model_ratio × group_ratio
cost = quota / quota_per_unit
```

模型费率通过前缀匹配从 `pricing_config.json` 获取。

## 安装后文件

| 平台 | 状态栏脚本 | 计费脚本 | 核心模块 |
|------|-----------|----------|----------|
| macOS/Linux | `~/.claude/statusline.sh` | `~/.claude/calculate_today_stats.py` | `~/.claude/core/` |
| Windows | `%USERPROFILE%\.claude\statusline.py` | 同上 | 同上 |

## 依赖

- **macOS/Linux**: Python 3.6+, jq, Bash
- **Windows**: Python 3.6+, PowerShell 5.1+
