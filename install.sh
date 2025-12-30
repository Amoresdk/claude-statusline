#!/bin/bash
#
# Claude Code Statusline 安装脚本
# 用于安装费用统计状态栏到 Claude Code
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=========================================="
echo "  Claude Code Statusline 安装程序"
echo "=========================================="
echo ""

# 检查依赖
echo "[1/5] 检查依赖..."

if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 需要安装 Python 3"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ 错误: 需要安装 jq"
    echo "   macOS: brew install jq"
    echo "   Ubuntu: sudo apt install jq"
    exit 1
fi

if ! command -v bc &> /dev/null; then
    echo "❌ 错误: 需要安装 bc"
    echo "   macOS: brew install bc"
    echo "   Ubuntu: sudo apt install bc"
    exit 1
fi

echo "✅ 依赖检查通过"
echo ""

# 创建目录
echo "[2/5] 创建目录..."
mkdir -p "$CLAUDE_DIR"
echo "✅ 目录已就绪: $CLAUDE_DIR"
echo ""

# 复制脚本
echo "[3/5] 复制脚本..."
cp "$SCRIPT_DIR/scripts/statusline.sh" "$CLAUDE_DIR/"
cp "$SCRIPT_DIR/scripts/calculate_today_stats.py" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/calculate_today_stats.py"
echo "✅ 脚本已复制"
echo ""

# 复制配置
echo "[4/5] 配置计费规则..."
if [ -f "$CLAUDE_DIR/pricing_config.json" ]; then
    echo "⚠️  发现已有计费配置，已备份为 pricing_config.json.bak"
    cp "$CLAUDE_DIR/pricing_config.json" "$CLAUDE_DIR/pricing_config.json.bak"
fi
cp "$SCRIPT_DIR/config/pricing_config.json" "$CLAUDE_DIR/"
echo "✅ 计费配置已复制"
echo ""

# 更新 settings.json
echo "[5/5] 更新 Claude Code 设置..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # 备份现有设置
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
    echo "⚠️  已备份现有设置为 settings.json.bak"

    # 检查是否已有 statusLine 配置
    if grep -q '"statusLine"' "$SETTINGS_FILE"; then
        echo "⚠️  检测到已有 statusLine 配置，请手动更新"
        echo "   将以下内容添加到 $SETTINGS_FILE:"
        echo ""
        echo '   "statusLine": {'
        echo '     "type": "command",'
        echo '     "command": "~/.claude/statusline.sh",'
        echo '     "padding": 0'
        echo '   }'
    else
        # 使用 jq 添加 statusLine 配置
        if command -v jq &> /dev/null; then
            jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            echo "✅ 已自动添加 statusLine 配置"
        else
            echo "⚠️  请手动添加 statusLine 配置到 settings.json"
        fi
    fi
else
    # 创建新的 settings.json
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
EOF
    echo "✅ 已创建 settings.json"
fi

echo ""
echo "=========================================="
echo "  安装完成！"
echo "=========================================="
echo ""
echo "📝 下一步操作："
echo ""
echo "1. 编辑计费规则（根据你的 API 服务商调整）："
echo "   vim ~/.claude/pricing_config.json"
echo ""
echo "2. 重启 Claude Code 使配置生效"
echo ""
echo "3. 如需卸载，运行："
echo "   ./uninstall.sh"
echo ""
