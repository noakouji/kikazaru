#!/usr/bin/env python3
"""
マイクが有効な間だけSonosの音量を下げる常駐スクリプト。

  マイクON  → 全グループの音量をフェードダウン
  マイクOFF → 元の音量へフェードアップ

クラッシュしても次回起動時に元の音量へ復元する（state.json に退避）。
"""
import atexit, ctypes, json, os, signal, struct, sys, time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from threading import Lock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sonos

# ------------------------------ 設定 ------------------------------
DUCK_RATIO = 0.30      # 元の音量の何割まで下げるか
DUCK_FLOOR = 3         # 下げすぎ防止の下限
FADE_STEPS = 5         # フェードの段数
POLL_SEC = 0.05        # マイク状態の監視間隔
RELEASE_SEC = 0.4      # 発話が途切れてから戻すまでの猶予
STATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "duck_state.json")

# --------------------- マイク状態（CoreAudio） ---------------------
_ca = ctypes.CDLL("/System/Library/Frameworks/CoreAudio.framework/CoreAudio")


def _fc(s):
    return struct.unpack(">I", s.encode())[0]


class _Addr(ctypes.Structure):
    _fields_ = [("s", ctypes.c_uint32), ("sc", ctypes.c_uint32), ("e", ctypes.c_uint32)]


def _prop(obj, sel, scope, size=4):
    a = _Addr(sel, scope, 0)
    n = ctypes.c_uint32(size)
    b = ctypes.create_string_buffer(size)
    if _ca.AudioObjectGetPropertyData(obj, ctypes.byref(a), 0, None, ctypes.byref(n), b) != 0:
        return None
    return b.raw[:n.value]


def mic_active():
    """既定の入力デバイスが、いずれかのアプリに使われているか"""
    r = _prop(1, _fc("dIn "), _fc("glob"))
    if not r:
        return False
    dev = struct.unpack("<I", r)[0]
    r = _prop(dev, _fc("gone"), _fc("glob"))
    return bool(struct.unpack("<I", r)[0]) if r else False


# ------------------------------ 本体 ------------------------------
def log(msg):
    print(f"[{datetime.now():%H:%M:%S}] {msg}", flush=True)


class Ducker:
    def __init__(self, targets):
        self.targets = targets          # [(ip, name)]
        self.saved = {}                 # ip -> 元の音量

    def _fade(self, ip, start, end):
        for i in range(1, FADE_STEPS + 1):
            try:
                sonos.set_volume(ip, round(start + (end - start) * i / FADE_STEPS))
            except Exception:
                return

    def _parallel(self, fn):
        """部屋ごとの処理を同時に走らせる（部屋数が増えても所要時間が伸びない）"""
        with ThreadPoolExecutor(max_workers=max(1, len(self.targets))) as ex:
            list(ex.map(fn, self.targets))

    def duck(self):
        if self.saved:
            return
        lock = Lock()

        def one(t):
            ip, name = t
            try:
                orig = sonos.get_volume(ip)
                low = max(DUCK_FLOOR, min(orig, round(orig * DUCK_RATIO)))
                if low >= orig:
                    return
                with lock:
                    self.saved[ip] = orig
                self._fade(ip, orig, low)
                log(f"🔉 下げた  {name}  {orig} → {low}")
            except Exception as e:
                log(f"⚠️ 失敗 {name}: {e}")

        self._parallel(one)
        if self.saved:
            self._persist()

    def restore(self, quiet=False):
        if not self.saved:
            return

        def one(t):
            ip, name = t
            orig = self.saved.get(ip)
            if orig is None:
                return
            try:
                self._fade(ip, sonos.get_volume(ip), orig)
                if not quiet:
                    log(f"🔊 戻した  {name}  → {orig}")
            except Exception as e:
                log(f"⚠️ 復元失敗 {name}: {e}")

        self._parallel(one)
        self.saved.clear()
        self._persist()

    def _persist(self):
        try:
            if self.saved:
                with open(STATE, "w") as f:
                    json.dump(self.saved, f)
            elif os.path.exists(STATE):
                os.remove(STATE)
        except Exception:
            pass


def recover_previous_crash():
    """前回異常終了して音量が下がったままなら、起動時に戻す"""
    if not os.path.exists(STATE):
        return
    try:
        with open(STATE) as f:
            saved = json.load(f)
        for ip, orig in saved.items():
            sonos.set_volume(ip, orig)
            log(f"♻️ 前回の中断を検出 → {ip} を {orig} に復元")
        os.remove(STATE)
    except Exception as e:
        log(f"⚠️ 復元処理でエラー: {e}")


def main():
    log("Sonos ダッキングを開始します")
    recover_previous_crash()

    targets = sonos.find_rooms()
    if not targets:
        log("❌ Sonosが見つかりません")
        return 1
    for ip, name in targets:
        log(f"🎯 対象: {name} ({ip})")
    log(f"⚙️  {int(DUCK_RATIO*100)}%まで / フェード{FADE_STEPS}段 / 復帰猶予{RELEASE_SEC}秒")
    log("待機中（Ctrl+Cで終了）")

    d = Ducker(targets)
    atexit.register(lambda: d.restore(quiet=True))
    for sig in (signal.SIGINT, signal.SIGTERM):
        signal.signal(sig, lambda *_: sys.exit(0))

    last_active = 0.0
    ducked = False
    while True:
        if mic_active():
            last_active = time.time()
            if not ducked:
                d.duck()
                ducked = True
        elif ducked and time.time() - last_active > RELEASE_SEC:
            d.restore()
            ducked = False
        time.sleep(POLL_SEC)


if __name__ == "__main__":
    sys.exit(main() or 0)
