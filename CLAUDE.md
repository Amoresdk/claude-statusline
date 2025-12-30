# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Claude Code Statusline 是一个为 Claude Code 添加实时费用统计状态栏的工具。它通过增量读取会话日志文件，计算今日总消耗和当前会话消耗，并在状态栏中显示。

## 常用命令

```bash
# 安装
./install.sh

# 卸载
./uninstall.sh

# 手动测试状态栏脚本
echo '{}' | ~/.claude/statusline.sh

# 重置统计
rm ~/.claude/usage_state.json
```

## 架构

项目由两个核心脚本组成：

1. **statusline.sh** - Bash 状态栏入口脚本
   - 从 stdin 接收 JSON 上下文（模型名、工作目录等）
   - 调用 Python 脚本获取费用数据
   - 渲染带颜色的状态栏输出

2. **calculate_today_stats.py** - Python 费用计算引擎
   - 增量读取 `~/.claude/projects/` 下的 JSONL 会话日志
   - 使用文件位置和已处理 ID 避免重复计算
   - 状态持久化到 `~/.claude/usage_state.json`

## 计费逻辑

费用公式：
```
quota = (input + cache_read × cache_ratio + cache_creation × cache_creation_ratio + output × completion_ratio) × model_ratio × group_ratio
cost = quota / quota_per_unit
```

模型费率通过前缀匹配从 `pricing_config.json` 获取，未匹配则使用 default 配置。

## 关键路径

安装后文件位于：
- `~/.claude/statusline.sh` - 主脚本
- `~/.claude/calculate_today_stats.py` - 计算脚本
- `~/.claude/pricing_config.json` - 计费规则
- `~/.claude/usage_state.json` - 统计状态（自动生成）
- `~/.claude/settings.json` - 需包含 statusLine 配置

## 依赖

- Python 3.6+
- jq（JSON 处理）
- bc（数学计算）
