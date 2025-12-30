#!/usr/bin/env python3
"""
Claude Code 状态栏计费统计脚本（增量更新版）

特点：
1. 增量读取：只处理新增数据，不重复计算
2. 状态持久化：记录文件位置和累计值
3. 高性能：避免全量扫描，实时性更好

配置文件：~/.claude/pricing_config.json
状态文件：~/.claude/usage_state.json
"""
import json
import os
import fcntl
from datetime import datetime, timezone, timedelta
from pathlib import Path


def load_pricing_config():
    """加载模型费率配置"""
    config_path = Path.home() / '.claude' / 'pricing_config.json'
    if config_path.exists():
        with open(config_path, 'r') as f:
            return json.load(f)
    return {
        "quota_per_unit": 500000,
        "group_ratio": 1.0,
        "models": {},
        "default": {
            "model_ratio": 7.5,
            "completion_ratio": 5,
            "cache_ratio": 0.1,
            "cache_creation_ratio": 1.25
        }
    }


def get_model_pricing(model_id, pricing_config):
    """根据模型 ID 获取费率配置（前缀匹配）"""
    if not model_id:
        return pricing_config.get('default', {})

    model_lower = model_id.lower()
    models = pricing_config.get('models', {})

    for model_key in models:
        if model_lower.startswith(model_key.lower()):
            return models[model_key]

    for model_key in models:
        key_parts = model_key.lower().replace('-', '').replace('_', '')
        model_parts = model_lower.replace('-', '').replace('_', '')
        if key_parts in model_parts or model_parts.startswith(key_parts):
            return models[model_key]

    return pricing_config.get('default', {})


def calculate_cost(usage, model_id, pricing_config):
    """计算单条记录的费用"""
    pricing = get_model_pricing(model_id, pricing_config)

    input_tokens = usage.get('input_tokens', 0)
    output_tokens = usage.get('output_tokens', 0)
    cache_read_tokens = usage.get('cache_read_input_tokens', 0)
    cache_creation_tokens = usage.get('cache_creation_input_tokens', 0)

    model_ratio = pricing.get('model_ratio', 7.5)
    completion_ratio = pricing.get('completion_ratio', 5)
    cache_ratio = pricing.get('cache_ratio', 0.1)
    cache_creation_ratio = pricing.get('cache_creation_ratio', 1.25)
    group_ratio = pricing_config.get('group_ratio', 1.0)
    quota_per_unit = pricing_config.get('quota_per_unit', 500000)

    calculate_quota = float(input_tokens)
    calculate_quota += float(cache_read_tokens) * cache_ratio
    calculate_quota += float(cache_creation_tokens) * cache_creation_ratio
    calculate_quota += float(output_tokens) * completion_ratio
    calculate_quota = calculate_quota * group_ratio * model_ratio

    cost = calculate_quota / quota_per_unit
    return cost


def load_state():
    """加载状态文件"""
    state_path = Path.home() / '.claude' / 'usage_state.json'
    if state_path.exists():
        try:
            with open(state_path, 'r') as f:
                return json.load(f)
        except:
            pass
    return {
        "today": {
            "date": "",
            "cost": 0.0,
            "file_positions": {},
            "processed_ids": []
        },
        "sessions": {}
    }


def save_state(state):
    """保存状态文件（带文件锁）"""
    state_path = Path.home() / '.claude' / 'usage_state.json'
    with open(state_path, 'w') as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        json.dump(state, f, indent=2)
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)


def get_today_string():
    """获取北京时间的今天日期字符串"""
    beijing_tz = timezone(timedelta(hours=8))
    return datetime.now(beijing_tz).date().isoformat()


def get_today_start_timestamp():
    """获取今天开始的时间戳"""
    beijing_tz = timezone(timedelta(hours=8))
    beijing_today = datetime.now(beijing_tz).date()

    # 检查手动重置时间戳
    reset_file = Path.home() / '.claude' / 'reset_timestamp.txt'
    if reset_file.exists():
        try:
            with open(reset_file, 'r') as f:
                reset_time_str = f.read().strip()
                reset_time = datetime.fromisoformat(reset_time_str)
                return reset_time.timestamp()
        except:
            pass

    today_start = datetime.combine(beijing_today, datetime.min.time()).replace(tzinfo=beijing_tz)
    return today_start.timestamp()


def find_current_session():
    """查找当前工作目录对应的会话文件"""
    cwd = os.getcwd()

    # 构建项目目录路径
    project_dir_name = cwd.replace('/', '-').replace(':', '')
    if project_dir_name.startswith('-'):
        project_dir_name = project_dir_name[1:]

    claude_project_dir = Path.home() / '.claude' / 'projects' / f"-{project_dir_name}"

    # 模糊匹配
    if not claude_project_dir.exists():
        projects_dir = Path.home() / '.claude' / 'projects'
        if projects_dir.exists():
            for d in projects_dir.iterdir():
                if d.is_dir() and cwd.split('/')[-1] in d.name:
                    claude_project_dir = d
                    break

    if not claude_project_dir.exists():
        return None, None

    # 找到最新的会话文件（排除 agent 开头的）
    jsonl_files = [f for f in claude_project_dir.glob('*.jsonl') if not f.name.startswith('agent')]
    if not jsonl_files:
        return None, None

    latest_file = max(jsonl_files, key=lambda f: f.stat().st_mtime)
    return latest_file.stem, str(latest_file)


def read_new_entries(file_path, last_position, today_start_ts, processed_ids, pricing_config):
    """增量读取文件中的新条目"""
    new_cost = 0.0
    new_ids = []
    new_position = last_position

    try:
        file_size = os.path.getsize(file_path)

        # 如果文件变小了（可能被截断），从头开始读
        if file_size < last_position:
            last_position = 0

        with open(file_path, 'r') as f:
            f.seek(last_position)

            while True:
                line = f.readline()
                if not line:
                    break

                new_position = f.tell()

                try:
                    data = json.loads(line.strip())

                    # 检查时间戳
                    timestamp = data.get('timestamp', '')
                    if timestamp:
                        try:
                            ts_str = timestamp.replace('Z', '+00:00')
                            record_time = datetime.fromisoformat(ts_str)
                            if record_time.timestamp() < today_start_ts:
                                continue
                        except:
                            pass

                    # 提取 usage 数据
                    if 'message' in data and isinstance(data['message'], dict):
                        msg = data['message']
                        usage = msg.get('usage')
                        msg_id = msg.get('id')
                        model = msg.get('model')

                        if usage and msg_id and msg_id not in processed_ids:
                            cost = calculate_cost(usage, model, pricing_config)
                            new_cost += cost
                            new_ids.append(msg_id)

                except json.JSONDecodeError:
                    continue

    except Exception:
        pass

    return new_cost, new_ids, new_position


def scan_today_files():
    """扫描今天修改过的所有会话文件"""
    beijing_tz = timezone(timedelta(hours=8))
    beijing_today = datetime.now(beijing_tz).date()

    projects_dir = Path.home() / '.claude' / 'projects'
    if not projects_dir.exists():
        return []

    today_files = []
    for project_dir in projects_dir.iterdir():
        if not project_dir.is_dir():
            continue

        for jsonl_file in project_dir.glob('*.jsonl'):
            # 排除 agent 文件
            if jsonl_file.name.startswith('agent'):
                continue

            # 检查修改时间
            try:
                file_mtime = datetime.fromtimestamp(jsonl_file.stat().st_mtime, tz=beijing_tz)
                if file_mtime.date() == beijing_today:
                    today_files.append(str(jsonl_file))
            except:
                continue

    return today_files


def calculate_stats():
    """计算今日总消耗和当前会话消耗（增量更新）"""
    pricing_config = load_pricing_config()
    state = load_state()
    today_str = get_today_string()
    today_start_ts = get_today_start_timestamp()

    # 日期变化，重置今日统计
    if state['today'].get('date') != today_str:
        state['today'] = {
            "date": today_str,
            "cost": 0.0,
            "file_positions": {},
            "processed_ids": []
        }
        state['sessions'] = {}

    # 获取当前会话信息
    current_session_id, current_session_file = find_current_session()

    # 扫描今天的所有文件
    today_files = scan_today_files()

    # 增量更新今日总消耗
    processed_ids = set(state['today'].get('processed_ids', []))
    file_positions = state['today'].get('file_positions', {})

    for file_path in today_files:
        last_pos = file_positions.get(file_path, 0)
        new_cost, new_ids, new_pos = read_new_entries(
            file_path, last_pos, today_start_ts, processed_ids, pricing_config
        )

        state['today']['cost'] += new_cost
        file_positions[file_path] = new_pos
        processed_ids.update(new_ids)

    state['today']['file_positions'] = file_positions
    # 只保留最近的 ID（避免无限增长）
    state['today']['processed_ids'] = list(processed_ids)[-10000:]

    # 计算当前会话消耗
    current_session_cost = 0.0
    if current_session_id and current_session_file:
        # 初始化会话状态
        if current_session_id not in state['sessions']:
            state['sessions'][current_session_id] = {
                "file_path": current_session_file,
                "file_position": 0,
                "cost": 0.0,
                "processed_ids": []
            }

        session_state = state['sessions'][current_session_id]
        session_processed_ids = set(session_state.get('processed_ids', []))

        # 增量读取当前会话
        new_cost, new_ids, new_pos = read_new_entries(
            current_session_file,
            session_state.get('file_position', 0),
            0,  # 会话不按日期过滤
            session_processed_ids,
            pricing_config
        )

        session_state['cost'] += new_cost
        session_state['file_position'] = new_pos
        session_state['processed_ids'] = list(session_processed_ids.union(new_ids))[-5000:]

        current_session_cost = session_state['cost']

    # 清理旧会话（保留最近 50 个）
    if len(state['sessions']) > 50:
        sessions_by_time = sorted(
            state['sessions'].items(),
            key=lambda x: x[1].get('file_position', 0),
            reverse=True
        )
        state['sessions'] = dict(sessions_by_time[:50])

    # 保存状态
    save_state(state)

    return {
        'today_cost': state['today']['cost'],
        'session_cost': current_session_cost
    }


if __name__ == "__main__":
    result = calculate_stats()
    print(json.dumps(result))
