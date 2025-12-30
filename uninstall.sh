#!/bin/bash
#
# Claude Code Statusline 卸载脚本
#

set -e

CLAUDE_DIR="$HOME/.claude"

echo "=========================================="
echo "  Claude Code Statusline 卸载程序"
echo "=========================================="
echo ""

read -p "确定要卸载 Claude Code Statusline 吗？(y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "已取消卸载"
    exit 0
fi

echo ""
echo "正在卸载..."

# 删除脚本文件
if [ -f "$CLAUDE_DIR/statusline.sh" ]; then
    rm "$CLAUDE_DIR/statusline.sh"
    echo "✅ 已删除 statusline.sh"
fi

if [ -f "$CLAUDE_DIR/calculate_today_stats.py" ]; then
    rm "$CLAUDE_DIR/calculate_today_stats.py"
    echo "✅ 已删除 calculate_today_stats.py"
fi

# 删除状态文件
if [ -f "$CLAUDE_DIR/usage_state.json" ]; then
    rm "$CLAUDE_DIR/usage_state.json"
    echo "✅ 已删除 usage_state.json"
fi

# 提示用户处理配置
echo ""
echo "⚠️  以下文件需要手动处理："
echo ""
echo "1. 计费配置文件（如需保留可跳过）："
echo "   rm ~/.claude/pricing_config.json"
echo ""
echo "2. 从 settings.json 中移除 statusLine 配置："
echo "   vim ~/.claude/settings.json"
echo "   删除 \"statusLine\": { ... } 部分"
echo ""
echo "3. 重启 Claude Code 使更改生效"
echo ""
echo "=========================================="
echo "  卸载完成！"
echo "=========================================="
