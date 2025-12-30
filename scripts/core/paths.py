"""跨平台路径处理"""
import sys
from pathlib import Path


def get_claude_dir() -> Path:
    """获取 Claude 配置目录"""
    return Path.home() / '.claude'


def normalize_project_path(cwd: str) -> str:
    """
    将工作目录路径转换为项目目录名称

    Unix:  /Users/name/project  ->  -Users-name-project
    Windows: C:\\Users\\name\\project  ->  -C-Users-name-project
    """
    path = Path(cwd)

    if sys.platform == 'win32':
        # Windows: 处理盘符，如 C: -> C
        parts = list(path.parts)
        if parts and parts[0].endswith(':'):
            parts[0] = parts[0].rstrip(':')
        project_dir_name = '-'.join(parts)
    else:
        # Unix: 移除开头的 /
        project_dir_name = str(path).replace('/', '-')
        if project_dir_name.startswith('-'):
            project_dir_name = project_dir_name[1:]

    return f"-{project_dir_name}"


def find_project_dir(cwd: str) -> Path:
    """查找项目目录（精确匹配 + 模糊匹配）"""
    projects_dir = get_claude_dir() / 'projects'

    if not projects_dir.exists():
        return None

    # 精确匹配
    exact_name = normalize_project_path(cwd)
    exact_path = projects_dir / exact_name
    if exact_path.exists():
        return exact_path

    # 模糊匹配：使用项目名称的最后一部分
    project_name = Path(cwd).name
    for d in projects_dir.iterdir():
        if d.is_dir() and project_name in d.name:
            return d

    return None
