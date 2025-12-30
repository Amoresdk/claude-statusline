#!/bin/bash

# 读取 JSON 输入
read json_input

# 调试：将 JSON 保存到文件（可选，用于调试）
# echo "$json_input" > ~/.claude/debug_statusline.json

# 使用 jq 解析 JSON 数据 - 注意字段名可能是 camelCase 或 snake_case
model=$(echo "$json_input" | jq -r '.model.display_name // .model.displayName // .model.id // "unknown"')
cwd=$(echo "$json_input" | jq -r '.workspace.current_dir // .workspace.currentDir // .cwd // "~"')
output_style=$(echo "$json_input" | jq -r '.output_style.name // "default"')

# 获取输出样式图标（已禁用）
# get_style_icon() {
#     case "$1" in
#         "default"|"Default")
#             echo "📝"
#             ;;
#         "explanatory"|"Explanatory")
#             echo "💡"
#             ;;
#         "learning"|"Learning")
#             echo "🎓"
#             ;;
#         *)
#             echo "⚙️"
#             ;;
#     esac
# }

# style_icon=$(get_style_icon "$output_style")

# 使用Python脚本从 New API 获取实际消费数据
today_stats=$(python3 ~/.claude/calculate_today_stats.py 2>/dev/null)
if [ -n "$today_stats" ]; then
    today_cost=$(echo "$today_stats" | jq -r '.today_cost // 0')
    session_cost=$(echo "$today_stats" | jq -r '.session_cost // 0')
else
    today_cost=0
    session_cost=0
fi

# 缓存相关（已不使用）
cache_read=0
cache_write=0

# 获取当前目录的简短路径
short_cwd=$(basename "$cwd")

# 获取 Git 分支（如果在 Git 仓库中）
git_branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ -n "$git_branch" ]; then
        git_branch=" \033[0;33m⎇ ${git_branch}\033[0m"
    fi
fi

# 格式化费用（保留2位小数）
formatted_today=$(printf "%.2f" "$today_cost")
formatted_session=$(printf "%.2f" "$session_cost")

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

# 根据今日费用设置颜色
if (( $(echo "$today_cost > 1" | bc -l) )); then
    today_color="$RED"
elif (( $(echo "$today_cost > 0.5" | bc -l) )); then
    today_color="$YELLOW"
else
    today_color="$GREEN"
fi

# 根据会话费用设置颜色
if (( $(echo "$session_cost > 0.5" | bc -l) )); then
    session_color="$RED"
elif (( $(echo "$session_cost > 0.2" | bc -l) )); then
    session_color="$YELLOW"
else
    session_color="$GREEN"
fi

# 构建状态栏
echo -ne "${CYAN}${short_cwd}${RESET}${git_branch} ${BLUE}[${model}]${RESET} ${MAGENTA}${output_style}${RESET} "

# 如果有缓存使用，显示缓存信息（已禁用）
# if [ "$cache_read" -gt 0 ] || [ "$cache_write" -gt 0 ]; then
#     echo -ne "💾 $(format_number "$cache_read")/$(format_number "$cache_write") "
# fi

# 显示费用：今日 $X.XX | 当前 $X.XX
echo -ne "${today_color}今日\$${formatted_today}${RESET} ${session_color}当前\$${formatted_session}${RESET}"