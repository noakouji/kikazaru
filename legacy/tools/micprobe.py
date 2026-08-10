#!/usr/bin/env python3
"""マイクが「使用中」かをCoreAudioに直接聞いて監視するプローブ（読み取り専用）"""
import ctypes, ctypes.util, struct, sys, time
from datetime import datetime

ca = ctypes.CDLL("/System/Library/Frameworks/CoreAudio.framework/CoreAudio")

def fourcc(s):
    return struct.unpack(">I", s.encode())[0]

SYSTEM_OBJECT      = 1
P_DEVICES          = fourcc("dev#")
P_DEVICE_NAME      = fourcc("name")
P_STREAM_CONFIG    = fourcc("slay")
P_RUNNING_SOMEWHERE= fourcc("gone")
SCOPE_GLOBAL       = fourcc("glob")
SCOPE_INPUT        = fourcc("inpt")
ELEMENT_MAIN       = 0

class Addr(ctypes.Structure):
    _fields_ = [("mSelector", ctypes.c_uint32),
                ("mScope",    ctypes.c_uint32),
                ("mElement",  ctypes.c_uint32)]

def size_of(obj, sel, scope=SCOPE_GLOBAL):
    a = Addr(sel, scope, ELEMENT_MAIN)
    n = ctypes.c_uint32(0)
    if ca.AudioObjectGetPropertyDataSize(obj, ctypes.byref(a), 0, None, ctypes.byref(n)) != 0:
        return None
    return n.value

def get(obj, sel, scope=SCOPE_GLOBAL, size=None):
    if size is None:
        size = size_of(obj, sel, scope)
        if size is None:
            return None
    a = Addr(sel, scope, ELEMENT_MAIN)
    n = ctypes.c_uint32(size)
    buf = ctypes.create_string_buffer(size)
    if ca.AudioObjectGetPropertyData(obj, ctypes.byref(a), 0, None, ctypes.byref(n), buf) != 0:
        return None
    return buf.raw[:n.value]

def devices():
    raw = get(SYSTEM_OBJECT, P_DEVICES)
    return list(struct.unpack("<%dI" % (len(raw) // 4), raw)) if raw else []

def name(dev):
    raw = get(dev, P_DEVICE_NAME)
    return raw.split(b"\x00")[0].decode("utf-8", "replace") if raw else "?"

def has_input(dev):
    raw = get(dev, P_STREAM_CONFIG, SCOPE_INPUT)
    if not raw or len(raw) < 4:
        return False
    (nbuf,) = struct.unpack("<I", raw[:4])
    off = 8  # mNumberBuffers + padding (64bit alignment)
    for _ in range(nbuf):
        if off + 4 > len(raw):
            break
        (ch,) = struct.unpack("<I", raw[off:off + 4])
        if ch > 0:
            return True
        off += 16
    return False

def running(dev):
    raw = get(dev, P_RUNNING_SOMEWHERE, size=4)
    return bool(struct.unpack("<I", raw)[0]) if raw else False

def ts():
    return datetime.now().strftime("%H:%M:%S")

duration = float(sys.argv[1]) if len(sys.argv) > 1 else 0  # 0 = 無制限
inputs = [d for d in devices() if has_input(d)]

print("=== 入力デバイス監視 ===")
state = {}
for d in inputs:
    r = running(d)
    state[d] = r
    print(f"[{ts()}] 初期  {name(d):<28} {'🔴 使用中' if r else '⚪️ 停止'}")
print("--- 変化のみ出力 ---", flush=True)

start = time.time()
try:
    while duration == 0 or time.time() - start < duration:
        for d in inputs:
            r = running(d)
            if state[d] != r:
                print(f"[{ts()}] 変化  {name(d):<28} {'🔴 使用中' if r else '⚪️ 停止'}", flush=True)
                state[d] = r
        time.sleep(0.1)
except KeyboardInterrupt:
    pass
print("--- 監視終了 ---")
