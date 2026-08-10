#!/usr/bin/env python3
"""現在の既定出力デバイスが「ミュート/音量」制御に対応しているかをCoreAudioに聞く（読み取り専用）"""
import ctypes, struct
from datetime import datetime

ca = ctypes.CDLL("/System/Library/Frameworks/CoreAudio.framework/CoreAudio")

def fourcc(s): return struct.unpack(">I", s.encode())[0]
def unfourcc(v): return struct.pack(">I", v).decode("ascii", "replace")

SYSTEM            = 1
P_DEFAULT_OUTPUT  = fourcc("dOut")
P_NAME            = fourcc("name")
P_TRANSPORT       = fourcc("tran")
P_MUTE            = fourcc("mute")
P_VOLUME          = fourcc("volm")
SCOPE_GLOBAL      = fourcc("glob")
SCOPE_OUTPUT      = fourcc("outp")

TRANSPORTS = {
    "bltn": "内蔵", "usb ": "USB", "airp": "AirPlay", "virt": "仮想デバイス",
    "hdmi": "HDMI", "dprt": "DisplayPort", "blue": "Bluetooth", "agg ": "集約デバイス",
}

class Addr(ctypes.Structure):
    _fields_ = [("mSelector", ctypes.c_uint32), ("mScope", ctypes.c_uint32), ("mElement", ctypes.c_uint32)]

def has(obj, sel, scope, elem=0):
    a = Addr(sel, scope, elem)
    return bool(ca.AudioObjectHasProperty(obj, ctypes.byref(a)))

def settable(obj, sel, scope, elem=0):
    a = Addr(sel, scope, elem)
    b = ctypes.c_ubyte(0)
    if ca.AudioObjectIsPropertySettable(obj, ctypes.byref(a), ctypes.byref(b)) != 0:
        return False
    return bool(b.value)

def get(obj, sel, scope, elem=0, size=None):
    a = Addr(sel, scope, elem)
    if size is None:
        n = ctypes.c_uint32(0)
        if ca.AudioObjectGetPropertyDataSize(obj, ctypes.byref(a), 0, None, ctypes.byref(n)) != 0:
            return None
        size = n.value
    n = ctypes.c_uint32(size)
    buf = ctypes.create_string_buffer(size)
    if ca.AudioObjectGetPropertyData(obj, ctypes.byref(a), 0, None, ctypes.byref(n), buf) != 0:
        return None
    return buf.raw[:n.value]

raw = get(SYSTEM, P_DEFAULT_OUTPUT, SCOPE_GLOBAL, size=4)
dev = struct.unpack("<I", raw)[0]

nm = get(dev, P_NAME, SCOPE_GLOBAL)
nm = nm.split(b"\x00")[0].decode("utf-8", "replace") if nm else "?"
tr = get(dev, P_TRANSPORT, SCOPE_GLOBAL, size=4)
tr = unfourcc(struct.unpack("<I", tr)[0]) if tr else "????"

print(f"=== 既定の出力デバイス [{datetime.now():%H:%M:%S}] ===")
print(f"  名前     : {nm}")
print(f"  接続方式 : {TRANSPORTS.get(tr, tr)}  ({tr!r})")
print()

def report(label, sel):
    rows = []
    for elem in (0, 1, 2):  # 0=マスター, 1/2=左右チャンネル
        if has(dev, sel, SCOPE_OUTPUT, elem):
            rows.append((elem, settable(dev, sel, SCOPE_OUTPUT, elem)))
    if not rows:
        print(f"  {label:<10}: ❌ プロパティ自体が存在しない → **制御不可**")
        return False
    ok = False
    for elem, st in rows:
        who = "マスター" if elem == 0 else f"ch{elem}"
        if st:
            ok = True
        print(f"  {label:<10}: {'✅ 書き込み可' if st else '⚠️ 読み取り専用'}  ({who})")
    return ok

print("--- Aqua Voice等が「音を止める」ために使う経路 ---")
m = report("ミュート", P_MUTE)
v = report("音量", P_VOLUME)
print()
if m or v:
    print("判定: このデバイスは macOS 側から制御 **できます**")
else:
    print("判定: 🚨 このデバイスは macOS 側から音量もミュートも制御 **できません**")
    print("      → アプリ内蔵のミュート機能は原理的に効きません")
