#!/usr/bin/env python3
"""SSDPでSONOSを探す（読み取り専用）"""
import socket, re, sys

MSG = "\r\n".join([
    "M-SEARCH * HTTP/1.1",
    "HOST: 239.255.255.250:1900",
    "MAN: \"ssdp:discover\"",
    "MX: 2",
    "ST: urn:schemas-upnp-org:device:ZonePlayer:1",
    "", ""]).encode()

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.settimeout(4)
found = {}
try:
    for _ in range(3):
        s.sendto(MSG, ("239.255.255.250", 1900))
    while True:
        try:
            data, addr = s.recvfrom(2048)
        except socket.timeout:
            break
        txt = data.decode("utf-8", "replace")
        loc = re.search(r"LOCATION:\s*(\S+)", txt, re.I)
        found[addr[0]] = loc.group(1) if loc else "?"
except Exception as e:
    print(f"エラー: {e}", file=sys.stderr)
finally:
    s.close()

if not found:
    print("❌ SSDPで見つかりませんでした")
    sys.exit(1)
print(f"✅ {len(found)}台 発見")
for ip, loc in sorted(found.items()):
    print(f"  {ip}  →  {loc}")
