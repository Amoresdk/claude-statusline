#!/usr/bin/env python3
"""
跨平台状态栏脚本
支持 Windows/macOS/Linux
"""
import sys
import json
import subprocess
from pathlib import Path

# 添加 core 模块路径
script_dir = Path(__file__).parent
if (script_dir / 'core').exists():
    sys.path.insert(0, str(script_dir))

from core.paths import get_claude_dir


def get_git_branch(cwd: str) -> str:
    """获取 Git 分支名"""
    try:
        result = subprocess.run(
            ['git', '-C', cwd, 'branch', '--show-current'],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass
    return ""


def get_cost_color(cost: float, yellow_threshold: float, red_threshold: float) -> str:
    """根据费用返回 ANSI 颜色码"""
    RED = '\033[0;31m'
    YELLOW = '\033[0;33m'
    GREEN = '\033[0;32m'

    if cost > red_threshold:
        return RED
    elif cost > yellow_threshold:
        return YELLOW
    return GREEN


def main():
    # 读取 JSON 输入
    try:
        json_input = sys.stdin.read()
        data = json.loads(json_input) if json_input.strip() else {}
    except Exception:
        data = {}

    # 解析字段（兼容 camelCase 和 snake_case）
    model = (data.get('model', {}).get('display_name') or
             data.get('model', {}).get('displayName') or
             data.get('model', {}).get('id') or 'unknown')
    cwd = (data.get('workspace', {}).get('current_dir') or
           data.get('workspace', {}).get('currentDir') or
           data.get('cwd') or str(Path.home()))
    output_style = data.get('output_style', {}).get('name', 'default')

    # 调用 Python 计费脚本
    try:
        claude_dir = get_claude_dir()
        result = subprocess.run(
            [sys.executable, str(claude_dir / 'calculate_today_stats.py')],
            capture_output=True, text=True, timeout=5,
            cwd=cwd
        )
        stats = json.loads(result.stdout) if result.stdout else {}
        today_cost = stats.get('today_cost', 0)
        session_cost = stats.get('session_cost', 0)
    except Exception:
        today_cost = session_cost = 0

    # Git 分支
    git_branch = get_git_branch(cwd)
    git_display = f" \033[0;33m⎇ {git_branch}\033[0m" if git_branch else ""

    # 路径简化
    short_cwd = Path(cwd).name

    # 颜色定义
    CYAN = '\033[0;36m'
    BLUE = '\033[0;34m'
    MAGENTA = '\033[0;35m'
    RESET = '\033[0m'

    today_color = get_cost_color(today_cost, 0.5, 1.0)
    session_color = get_cost_color(session_cost, 0.2, 0.5)

    # 输出状态栏
    print(f"{CYAN}{short_cwd}{RESET}{git_display} "
          f"{BLUE}[{model}]{RESET} {MAGENTA}{output_style}{RESET} "
          f"{today_color}今日${today_cost:.2f}{RESET} "
          f"{session_color}当前${session_cost:.2f}{RESET}", end='')


if __name__ == "__main__":
    main()
