#!/usr/bin/env python3
"""マイクが開いている時間をミリ秒精度で計測する（読み取り専用）

短い単語を1回だけ喋って終了する、を数回繰り返すと
「発話後にマイクが開きっぱなしになる固定オーバーヘッド」が分かる。
"""
import ctypes, struct, sys, time
from datetime import datetime

ca = ctypes.CDLL("/System/Library/Frameworks/CoreAudio.framework/CoreAudio")
def fc(s): return struct.unpack(">I", s.encode())[0]

class Addr(ctypes.Structure):
    _fields_ = [("s", ctypes.c_uint32), ("sc", ctypes.c_uint32), ("e", ctypes.c_uint32)]

def prop(obj, sel, scope, size=4):
    a = Addr(sel, scope, 0)
    n = ctypes.c_uint32(size)
    b = ctypes.create_string_buffer(size)
    if ca.AudioObjectGetPropertyData(obj, ctypes.byref(a), 0, None, ctypes.byref(n), b) != 0:
        return None
    return b.raw[:n.value]

def mic_active():
    r = prop(1, fc("dIn "), fc("glob"))
    if not r:
        return False
    dev = struct.unpack("<I", r)[0]
    r = prop(dev, fc("gone"), fc("glob"))
    return bool(struct.unpack("<I", r)[0]) if r else False

dur = float(sys.argv[1]) if len(sys.argv) > 1 else 90
print(f"=== マイク開放時間の計測（{dur:.0f}秒）===")
print("短い単語を1回だけ喋って止める、を数回やってください\n")

start, prev, t_on = time.time(), mic_active(), None
sessions = []
while time.time() - start < dur:
    cur = mic_active()
    if cur and not prev:
        t_on = time.time()
        print(f"[{datetime.now():%H:%M:%S}] 🔴 開いた", flush=True)
    elif prev and not cur and t_on:
        d = time.time() - t_on
        sessions.append(d)
        print(f"[{datetime.now():%H:%M:%S}] ⚪️ 閉じた  開いていた時間 = {d:.2f}秒", flush=True)
    prev = cur
    time.sleep(0.02)

if sessions:
    print(f"\n--- {len(sessions)}回 / 最短 {min(sessions):.2f}秒 / "
          f"最長 {max(sessions):.2f}秒 / 平均 {sum(sessions)/len(sessions):.2f}秒 ---")
else:
    print("\n--- 発話が検出されませんでした ---")
