#!/usr/bin/env python3
"""夜間観測: 入力音量・出力音量・マイク使用状態を記録する（読み取り専用・自動終了）"""
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

def default_dev(kind):  # "dIn " or "dOut"
    r = get(1, fc(kind), fc("glob"))
    return struct.unpack("<I", r)[0] if r else None

def volume(dev, scope):
    for elem in (0, 1, 2):
        r = get(dev, fc("volm"), fc(scope), elem)
        if r:
            return struct.unpack("<f", r)[0] * 100
    return None

def mic_running(dev):
    r = get(dev, fc("gone"), fc("glob"))
    return bool(struct.unpack("<I", r)[0]) if r else False

def ts(): return datetime.now().strftime("%m/%d %H:%M:%S")

HOURS = float(sys.argv[1]) if len(sys.argv) > 1 else 10
INTERVAL = 5
HEARTBEAT = 1800  # 30分ごとに生存記録

din, dout = default_dev("dIn "), default_dev("dOut")
state = {"in": volume(din, "inpt"), "out": volume(dout, "outp"), "mic": mic_running(din)}

print(f"[{ts()}] === 夜間観測開始（{HOURS:.0f}時間で自動終了） ===")
print(f"[{ts()}] 初期  入力={state['in']:.1f}%  出力={state['out']:.1f}%  "
      f"マイク={'使用中' if state['mic'] else '停止'}", flush=True)

start = last_hb = last_tick = time.time()
while time.time() - start < HOURS * 3600:
    now = time.time()

    # スリープ復帰の検出（想定より大きく時間が飛んだら記録）
    if now - last_tick > INTERVAL * 6:
        print(f"[{ts()}] ⏸ 時間が {now - last_tick:.0f}秒 飛びました（スリープの可能性）", flush=True)
    last_tick = now

    d_in, d_out = default_dev("dIn "), default_dev("dOut")
    v_in, v_out, mic = volume(d_in, "inpt"), volume(d_out, "outp"), mic_running(d_in)

    if v_in is not None and state["in"] is not None and abs(v_in - state["in"]) > 0.2:
        print(f"[{ts()}] 🎙 入力音量  {state['in']:.1f}% → {v_in:.1f}%  "
              f"({'↑' if v_in > state['in'] else '↓'}{abs(v_in - state['in']):.1f}pt)", flush=True)
        state["in"] = v_in
    if v_out is not None and state["out"] is not None and abs(v_out - state["out"]) > 0.2:
        print(f"[{ts()}] 🔊 出力音量  {state['out']:.1f}% → {v_out:.1f}%", flush=True)
        state["out"] = v_out
    if mic != state["mic"]:
        print(f"[{ts()}] 🔴 マイク状態 → {'使用中' if mic else '停止'}", flush=True)
        state["mic"] = mic

    if now - last_hb >= HEARTBEAT:
        print(f"[{ts()}] ·· 生存確認  入力={v_in:.1f}%  出力={v_out:.1f}%  "
              f"マイク={'使用中' if mic else '停止'}", flush=True)
        last_hb = now

    time.sleep(INTERVAL)

print(f"[{ts()}] === 観測終了  最終: 入力={volume(default_dev('dIn '), 'inpt'):.1f}% ===")
