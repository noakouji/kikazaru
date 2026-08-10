#!/usr/bin/env python3
"""Sonos ローカルUPnP制御の最小ライブラリ（認証不要・ポート1400）"""
import html, re, socket, urllib.request, xml.sax.saxutils as sx

RC = ("urn:schemas-upnp-org:service:RenderingControl:1", "/MediaRenderer/RenderingControl/Control")
AV = ("urn:schemas-upnp-org:service:AVTransport:1", "/MediaRenderer/AVTransport/Control")
ZT = ("urn:schemas-upnp-org:service:ZoneGroupTopology:1", "/ZoneGroupTopology/Control")


def soap(ip, service, action, args=None, timeout=5):
    """SOAPを1発投げて、返ってきた要素を dict で返す"""
    urn, path = service
    body = "".join(f"<{k}>{sx.escape(str(v))}</{k}>" for k, v in (args or {}).items())
    env = (
        '<?xml version="1.0"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
        f'<u:{action} xmlns:u="{urn}">{body}</u:{action}>'
        "</s:Body></s:Envelope>"
    ).encode()
    req = urllib.request.Request(
        f"http://{ip}:1400{path}", data=env,
        headers={"Content-Type": 'text/xml; charset="utf-8"',
                 "SOAPACTION": f'"{urn}#{action}"'})
    raw = urllib.request.urlopen(req, timeout=timeout).read().decode("utf-8", "replace")
    return {k: v for k, v in re.findall(r"<(\w+)>([^<]*)</\1>", raw)
            if k not in ("s:Body", "s:Envelope")}


def discover(timeout=3):
    """SSDPでSonosを探して [(ip, room, model)] を返す"""
    msg = ("M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\n"
           'MAN: "ssdp:discover"\r\nMX: 1\r\n'
           "ST: urn:schemas-upnp-org:device:ZonePlayer:1\r\n\r\n").encode()
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.settimeout(timeout)
    ips = set()
    try:
        for _ in range(2):
            s.sendto(msg, ("239.255.255.250", 1900))
        while True:
            try:
                _, addr = s.recvfrom(2048)
                ips.add(addr[0])
            except socket.timeout:
                break
    finally:
        s.close()
    out = []
    for ip in sorted(ips):
        try:
            xml = urllib.request.urlopen(
                f"http://{ip}:1400/xml/device_description.xml", timeout=4).read().decode()
            room = re.search(r"<roomName>(.*?)</roomName>", xml)
            model = re.search(r"<modelName>(.*?)</modelName>", xml)
            out.append((ip, room.group(1) if room else "?", model.group(1) if model else "?"))
        except Exception:
            out.append((ip, "?", "?"))
    return out


def topology(ip):
    """ゾーン構成を返す: [{coordinator_ip, name, members:[...], satellites:[...]}]"""
    raw = soap(ip, ZT, "GetZoneGroupState").get("ZoneGroupState", "")
    st = html.unescape(html.unescape(raw))  # 二重エスケープされている
    groups = []
    for cid, body in re.findall(r'<ZoneGroup Coordinator="([^"]+)"[^>]*>(.*?)</ZoneGroup>', st, re.S):
        g = {"coordinator_ip": None, "name": "?", "members": [], "satellites": []}
        for tag in ("ZoneGroupMember", "Satellite"):
            for m in re.finditer(r"<%s ([^>]*?)/?>" % tag, body):
                a = dict(re.findall(r'(\w+)="([^"]*)"', m.group(1)))
                loc = re.search(r"//([\d.]+):1400", a.get("Location", ""))
                e = {"ip": loc.group(1) if loc else None,
                     "name": a.get("ZoneName", "?"),
                     "invisible": a.get("Invisible") == "1"}
                if tag == "Satellite":
                    g["satellites"].append(e)
                else:
                    g["members"].append(e)
                    if a.get("UUID") == cid:
                        g["coordinator_ip"], g["name"] = e["ip"], e["name"]
        groups.append(g)
    return groups


def coordinators(ip):
    """再生を制御すべき「親機」のIPだけを返す"""
    return [(g["coordinator_ip"], g["name"]) for g in topology(ip) if g["coordinator_ip"]]


def rooms(ip):
    """音量を個別に持つ実体（可視メンバー）を全部返す。
    サテライト(Sub/サラウンド)は親機に追従するので除外する。"""
    out, seen = [], set()
    for g in topology(ip):
        for m in g["members"]:
            if m["ip"] and not m["invisible"] and m["ip"] not in seen:
                seen.add(m["ip"])
                out.append((m["ip"], m["name"]))
    return out


def find_rooms():
    """SSDPで発見 → トポロジが引ける機体から全ルームを取得"""
    devices = discover()
    for ip, _, _ in devices:
        try:
            r = rooms(ip)
            if r:
                return r
        except Exception:
            continue
    return []


def get_volume(ip):
    return int(soap(ip, RC, "GetVolume", {"InstanceID": 0, "Channel": "Master"})["CurrentVolume"])


def set_volume(ip, v):
    soap(ip, RC, "SetVolume", {"InstanceID": 0, "Channel": "Master", "DesiredVolume": int(v)})


def ramp_to_volume(ip, v, ramp="ALARM_RAMP_TYPE"):
    r = soap(ip, RC, "RampToVolume", {
        "InstanceID": 0, "Channel": "Master", "RampType": ramp,
        "DesiredVolume": int(v), "ResetVolumeAfter": 0, "ProgramURI": ""})
    return int(r.get("RampTime", -1))


def restore_volume(ip):
    soap(ip, RC, "RestoreVolumePriorToRamp", {"InstanceID": 0, "Channel": "Master"})


def transport_state(ip):
    try:
        return soap(ip, AV, "GetTransportInfo", {"InstanceID": 0}).get("CurrentTransportState", "?")
    except Exception:
        return "?"
