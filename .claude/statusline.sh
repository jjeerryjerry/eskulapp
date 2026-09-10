#!/usr/bin/env bash
# Pasek statusu agenta - STANDARD Jerry (memory: rule-agent-statusline-standard).
# Format: Jerry<Name> X.Y beta | Opus 4.8 (high) | tok: 63.2k/1M | 5h: 45% (reset) | tydz: 8% (reset)
# Regula: KAZDA zmiana funkcjonalna bumpuje VERSION o +0.1 (recznie).
NAME="JerryEskulapp"
VERSION="1.0"
input=$(cat)
echo "$input" | NAME="$NAME" VERSION="$VERSION" python3 -c '
import json, sys, time, os
E = chr(27)
def col(code, s): return f"{E}[{code}m{s}{E}[0m"
def human(n):
    n = float(n)
    if n >= 1_000_000:
        v = f"{n/1_000_000:.1f}".rstrip("0").rstrip(".")
        return v + "M"
    if n >= 1_000:
        return f"{n/1_000:.1f}".rstrip("0").rstrip(".") + "k"
    return str(int(n))
def reset(ts):
    rem = int(ts - time.time())
    if rem < 0: rem = 0
    d, r = divmod(rem, 86400)
    h, r = divmod(r, 3600)
    m = r // 60
    if d > 0: return f"{d}d{h}h"
    if h > 0: return f"{h}h{m:02d}"
    return f"{m}m"
def pct_color(p):
    return "32" if p < 50 else ("33" if p < 80 else "31")
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
name = os.environ.get("NAME","Agent")
ver = os.environ.get("VERSION","")
parts = [col("34", f"{name} {ver} beta" if ver else name)]
model = (data.get("model") or {}).get("display_name") or ""
eff = (data.get("effort") or {}).get("level") or ""
if model:
    if eff:
        model = f"{model[:-1]}, {eff})" if model.endswith(")") else f"{model} ({eff})"
    parts.append(col("33", model))
cw = data.get("context_window") or {}
used = cw.get("total_input_tokens")
size = cw.get("context_window_size")
if used is not None and size:
    parts.append("tok: " + col("36", f"{human(used)}/{human(size)}"))
rl = data.get("rate_limits") or {}
def limit(key, label):
    d = rl.get(key) or {}
    p = d.get("used_percentage")
    ts = d.get("resets_at")
    if p is None: return None
    seg = f"{label}: " + col(pct_color(p), f"{round(p)}%")
    if ts: seg += " \U0001f552" + reset(ts)
    return seg
for seg in (limit("five_hour","5h"), limit("seven_day","tydz")):
    if seg: parts.append(seg)
print(" | ".join(parts))
'
