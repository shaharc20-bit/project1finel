import json
import os
import socket
import subprocess
from datetime import datetime

import psutil
import requests
from flask import Flask, jsonify, render_template

app = Flask(__name__)

# Windows (my PC) uses speedtest.exe, Linux (Docker / K8s) uses speedtest
SPEEDTEST = "speedtest.exe" if os.name == "nt" else "speedtest"


@app.route("/")
def home():
    now = datetime.now().strftime("%d/%m/%Y %H:%M")
    cpu = psutil.cpu_percent(interval=0.5)
    ram = psutil.virtual_memory().percent
    disk = psutil.disk_usage("/").percent
    return render_template("home.html", now=now, cpu=cpu, ram=ram, disk=disk)


@app.route("/api/stats")
def stats():
    return jsonify(
        cpu=psutil.cpu_percent(interval=0.5),
        ram=psutil.virtual_memory().percent,
        disk=psutil.disk_usage("/").percent,
    )


@app.route("/about")
def about():
    return render_template("about.html")


@app.route("/health")
def health():
    return "ok"


@app.route("/network")
def network():
    name = socket.gethostname()
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    ip = s.getsockname()[0]
    s.close()
    return render_template("network.html", name=name, ip=ip)


@app.route("/api/speed")
def speed():
    try:
        out = subprocess.run(
            [SPEEDTEST, "--accept-license", "--accept-gdpr", "--format=json"],
            capture_output=True, text=True, timeout=90, check=True,
        )
        data = json.loads(out.stdout)
    except (OSError, subprocess.SubprocessError, ValueError) as e:
        print("SPEED ERROR:", e)
        return jsonify(error="speed test failed"), 502
    download = round(data["download"]["bandwidth"] * 8 / 1_000_000, 2)
    upload = round(data["upload"]["bandwidth"] * 8 / 1_000_000, 2)
    ping = round(data["ping"]["latency"])
    return jsonify(download=download, upload=upload, ping=ping)


@app.route("/api/sites")
def sites():
    urls = ["https://google.com", "https://github.com", "https://youtube.com"]
    result = {}
    for url in urls:
        try:
            r = requests.get(url, timeout=3)
            result[url] = "🟢 Up" if r.status_code == 200 else "🔴 Down"
        except requests.RequestException:
            result[url] = "🔴 Down"
    return jsonify(result)


cache = {}


@app.route("/api/quote")
def quote():
    today = datetime.now().strftime("%Y-%m-%d")
    if cache.get("date") == today:
        return jsonify(cache["data"])
    try:
        r = requests.get("https://zenquotes.io/api/today", timeout=5)
        data = r.json()[0]
        t = requests.get("https://api.mymemory.translated.net/get",
                         params={"q": data["q"], "langpair": "en|he"}, timeout=5)
        hebrew = t.json()["responseData"]["translatedText"]
        cache["date"] = today
        cache["data"] = dict(text=data["q"], hebrew=hebrew, author=data["a"])
        return jsonify(cache["data"])
    except (requests.RequestException, ValueError, KeyError, IndexError) as e:
        print("QUOTE ERROR:", e)
        return jsonify(text="Keep going!", hebrew="תמשיך!", author="prOne")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 6555)))
