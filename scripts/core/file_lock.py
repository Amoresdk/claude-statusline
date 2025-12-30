"""跨平台文件锁实现"""
import sys

if sys.platform == 'win32':
    import msvcrt

    def lock_file(file_obj):
        """获取文件排他锁 (Windows)"""
        msvcrt.locking(file_obj.fileno(), msvcrt.LK_LOCK, 1)

    def unlock_file(file_obj):
        """释放文件锁 (Windows)"""
        file_obj.seek(0)
        msvcrt.locking(file_obj.fileno(), msvcrt.LK_UNLCK, 1)
else:
    import fcntl

    def lock_file(file_obj):
        """获取文件排他锁 (Unix)"""
        fcntl.flock(file_obj.fileno(), fcntl.LOCK_EX)

    def unlock_file(file_obj):
        """释放文件锁 (Unix)"""
        fcntl.flock(file_obj.fileno(), fcntl.LOCK_UN)
