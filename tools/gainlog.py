#!/usr/bin/env python3
"""入力音量を0.5秒間隔で監視し、変化した瞬間だけ記録する（読み取り専用）"""
import ctypes, struct, sys, time
from datetime import datetime

ca = ctypes.CDLL("/System/Library/Frameworks/CoreAudio.framework/CoreAudio")
def fc(s): return struct.unpack(">I", s.encode())[0]

class Addr(ctypes.Structure):
    _fields_ = [("s", ctypes.c_uint32), ("sc", ctypes.c_uint32), ("e", ctypes.c_uint32)]

def get(obj, sel, scope, elem=0, size=4):
    a = Addr(sel, scope, elem)
    n = ctypes.c_uint32(size)
    b = ctypes.create_string_buffer(size)
    if ca.AudioObjectGetPropertyData(obj, ctypes.byref(a), 0, None, ctypes.byref(n), b) != 0:
        return None
    return b.raw[:n.value]

dev = struct.unpack("<I", get(1, fc("dIn "), fc("glob")))[0]

def vol():
    for elem in (0, 1, 2):
        r = get(dev, fc("volm"), fc("inpt"), elem)
        if r:
            return struct.unpack("<f", r)[0]
    return None

dur = float(sys.argv[1]) if len(sys.argv) > 1 else 120
start, prev, t0 = time.time(), vol(), time.time()
print(f"[{datetime.now():%H:%M:%S}] 開始  入力音量 = {prev*100:.1f}%")
print("--- 変化した瞬間だけ記録 ---", flush=True)
moves = 0
while time.time() - start < dur:
    v = vol()
    if v is not None and prev is not None and abs(v - prev) > 0.002:
        d = v - prev
        moves += 1
        print(f"[{datetime.now():%H:%M:%S}] {prev*100:5.1f}% → {v*100:5.1f}%  "
              f"({'↑' if d>0 else '↓'}{abs(d)*100:.1f}pt, 前回から{time.time()-t0:.1f}秒)", flush=True)
        prev, t0 = v, time.time()
    time.sleep(0.5)
print(f"--- 終了: {dur:.0f}秒間で {moves} 回の変化 / 最終値 {vol()*100:.1f}% ---")
