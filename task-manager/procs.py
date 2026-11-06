#!/usr/bin/env python3
# tacit-mem's counting for the task manager: one line of JSON per run.
# Counts each program's real share (PSS plus its share of swap), so shared libraries are not counted twice,
# and groups threads under their program like tacit-mem does. CPU is measured over a short sample,
# so a run costs 0.35 s and says what the programs are doing now, not since boot.
# Run with sudo to see root's programs; without it they join System services and cannot be ended.
import ctypes, glob, json, os, re, shutil, subprocess, time

APPS = {"claude": "Praxis", "code": "Graphis", "viewer": "Viewer", "tacit-settings": "Settings",
        "store": "Store", "activity": "Activity", "files": "Pinax",
        "launcher": "Launcher", "markdown-viwer": "Markdown viewer", "task-manager": "Task manager"}
HELPERS = {"swaybg", "hypridle", "hyprsunset", "quiet-btagent", "systemd-inhibit"}

def program(pid, args, comm):
    # the real executable; many programs rewrite their own command line
    try:
        path = os.readlink(f"/proc/{pid}/exe")
    except OSError:
        path = args[0].split()[0] if args and args[0].split() else comm
    parts = [p for p in path.replace(" (deleted)", "").split("/") if p]
    # a versioned install (…/claude/versions/2.1.3) is named by its folder
    while len(parts) > 1 and (re.fullmatch(r"[\d.]+", parts[-1]) or parts[-1] in ("versions", "bin")):
        parts.pop()
    name = parts[-1] if parts else comm
    name = re.split(r"[-_.]\d", name)[0]            # T3-Code-0.1.7.AppImage -> T3-Code
    for suffix in ("-bin", "-wrapped"):
        name = name.removesuffix(suffix)
    return "python" if name.lower().startswith("python") else name

def group(pid, comm, args, exe):
    line = " ".join(args)
    if comm in ("Hyprland", "Xwayland"):
        return "desktop", "Window manager (Hyprland)"
    if exe in ("qs", "quickshell") and "tacit" in line:
        target = args[args.index("-p") + 1] if "-p" in args else ""
        if target.endswith(".qml"):
            name = os.path.basename(target)[:-4]
            return "apps", APPS.get(name, name.title())
        return "desktop", "Shell: notch, dock, panel"
    if comm in ("pipewire", "wireplumber", "pipewire-pulse"):
        return "desktop", "Sound"
    if "xdg-desktop-portal" in line or "xdg-document-portal" in line or "xdg-permission-store" in line:
        return "desktop", "Desktop portals"
    if comm == "agent-host":
        return "desktop", "Praxis helper"
    if comm == "flowd" or line.endswith("/flowd"):
        return "desktop", "Dictation"
    if comm in HELPERS or "tacit" in exe:
        return "desktop", "Wallpaper and small helpers"
    return "other", exe

def cpu_ticks(pid):
    try:
        stat = open(f"/proc/{pid}/stat").read()
        fields = stat[stat.rindex(")") + 2:].split()
        return int(fields[11]) + int(fields[12])    # utime + stime
    except (OSError, ValueError, IndexError):
        return 0

def cpu_snap():
    parts = [int(x) for x in open("/proc/stat").readline().split()[1:]]
    return sum(parts), parts[3] + (parts[4] if len(parts) > 4 else 0)   # total, idle + iowait

def disk_snap():
    r = w = 0
    for dev in os.listdir("/sys/block"):
        if dev.startswith(("loop", "ram", "zram")):
            continue
        try:
            f = open(f"/sys/block/{dev}/stat").read().split()
            r += int(f[2]); w += int(f[6])          # sectors read and written, 512 bytes each
        except (OSError, IndexError, ValueError):
            continue
    return r, w

def gpu_info():
    # NVML answers in 20 ms while the driver is awake; a sleeping one costs a second and a half.
    # A short cache lets the figure ride through refreshes without paying the wake-up twice.
    cache = "/tmp/tacit-task-manager-gpu.json"
    try:
        c = json.load(open(cache))
        if time.time() - c["at"] < 8:
            return c["gpu"]
    except (OSError, ValueError, KeyError):
        pass
    gpu = _gpu_nvml() or _gpu_smi() or _gpu_sysfs()
    try:
        json.dump({"at": time.time(), "gpu": gpu}, open(cache, "w"))
    except OSError:
        pass
    return gpu

def _gpu_nvml():
    try:
        nvml = ctypes.CDLL("libnvidia-ml.so.1")
    except OSError:
        return None
    try:
        if nvml.nvmlInit_v2() != 0:
            return None
        h = ctypes.c_void_p()
        if nvml.nvmlDeviceGetHandleByIndex_v2(0, ctypes.byref(h)) != 0:
            return None

        class Util(ctypes.Structure):
            _fields_ = [("gpu", ctypes.c_uint), ("mem", ctypes.c_uint)]

        class MemInfo(ctypes.Structure):
            _fields_ = [("total", ctypes.c_ulonglong), ("free", ctypes.c_ulonglong), ("used", ctypes.c_ulonglong)]

        u = Util()
        if nvml.nvmlDeviceGetUtilizationRates(h, ctypes.byref(u)) != 0:
            return None
        m = MemInfo()
        nvml.nvmlDeviceGetMemoryInfo(h, ctypes.byref(m))
        return {"busy": float(u.gpu), "mem_used": m.used // 1024, "mem_total": m.total // 1024}
    except (OSError, ValueError):
        return None

def _gpu_smi():
    if shutil.which("nvidia-smi"):
        try:
            out = subprocess.run(["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total",
                                  "--format=csv,noheader,nounits"], capture_output=True, text=True, timeout=2.0)
            line = out.stdout.strip().splitlines()
            if out.returncode == 0 and line:
                busy, used, total = [float(x.strip()) for x in line[0].split(",")]
                return {"busy": busy, "mem_used": used * 1024, "mem_total": total * 1024}
        except (OSError, ValueError, subprocess.TimeoutExpired):
            pass
    return None

def _gpu_sysfs():
    busy = []
    for p in sorted(glob.glob("/sys/class/drm/card*/device/gpu_busy_percent") + glob.glob("/sys/class/drm/card*/gpu_busy_percent")):
        try:
            busy.append(int(open(p).read()))
        except (OSError, ValueError):
            continue
    return {"busy": max(busy), "mem_used": 0, "mem_total": 0} if busy else None

def desktop_icons():
    # program -> icon, from the app lists: an Exec name or a Name match
    names = {}
    for d in (os.path.expanduser("~/.local/share/applications"), "/usr/share/applications", "/usr/local/share/applications"):
        try:
            files = os.listdir(d)
        except OSError:
            continue
        for f in files:
            if not f.endswith(".desktop"):
                continue
            try:
                txt = open(os.path.join(d, f), errors="replace").read()
            except OSError:
                continue
            icon = nm = ""
            toks = []
            for l in txt.splitlines():
                if l.startswith("Icon=") and not icon:
                    icon = l[5:].strip()
                elif l.startswith("Name=") and not nm:
                    nm = l[5:].strip()
                elif l.startswith("Exec="):
                    for tok in re.findall(r"(?:^|[;&|])\s*([^\s;&|]+)", l[5:]):
                        b = os.path.basename(tok)
                        if b and not b.startswith("%"):
                            toks.append(b.lower())
            if not icon:
                continue                             # the whole file read first: Exec often sits above Icon
            for t in toks:
                names.setdefault(t, icon)
            if nm:
                names.setdefault(nm.lower(), icon)
    return names

def icon_index():
    # a lazy finder: the themes are listed once, each name checked at the biggest size first
    sizes = ("256x256", "128x128", "96x96", "64x64", "48x48", "32x32", "scalable")
    roots = [os.path.expanduser("~/.local/share/icons"), "/usr/share/icons"]
    places = []
    for root in roots:
        try:
            places += [(root, e.name) for e in os.scandir(root) if e.is_dir()]
        except OSError:
            continue
    places.append(("/usr/share/pixmaps", None))

    def find(base):
        for size in sizes:
            for root, theme in places:
                if theme is None:
                    for ext in (".png", ".svg", ".xpm"):
                        if os.path.exists(f"{root}/{base}{ext}"):
                            return f"{root}/{base}{ext}"
                    continue
                for ext in (".png", ".svg"):
                    p = f"{root}/{theme}/{size}/apps/{base}{ext}"
                    if os.path.exists(p):
                        return p
        return ""
    return find

def icon_for(kind, name, exe, names, find):
    # words the person would search by: the executable, the whole name, its first word, what brackets say
    cands = [exe.lower() if exe else "", name.lower(), re.sub(r"[^a-z0-9. ]", "", name.split(" ")[0].lower())]
    m = re.search(r"\(([^)]+)\)", name)
    if m:
        cands.append(m.group(1).lower())
    ic = ""
    for c in cands:
        if c and names.get(c):
            ic = names[c]
            break
    if not ic:                        # then a near name: qoder answers to qoder-ide
        for c in cands:
            if len(c) < 4:
                continue
            for k, v in names.items():
                if v and len(k) >= 4 and (c in k or k in c):
                    ic = v
                    break
            if ic:
                break
    if not ic:
        return ""
    if ic.startswith("/"):
        return ic if os.path.exists(ic) else ""
    return find(re.sub(r"\.(png|svg|xpm|ico)$", "", os.path.basename(ic)))

my_uid = int(os.environ.get("SUDO_UID", os.getuid()))
hz = os.sysconf("SC_CLK_TCK")
procs, shown, live = {}, {}, {}
for pid in filter(str.isdigit, os.listdir("/proc")):
    try:
        rollup = open(f"/proc/{pid}/smaps_rollup").read()
        pss = sum(int(v) for v in re.findall(r"^(?:Pss|SwapPss):\s+(\d+)", rollup, re.M))
        args = open(f"/proc/{pid}/cmdline", "rb").read().decode(errors="replace").split("\0")[:-1]
        comm = open(f"/proc/{pid}/comm").read().strip()
        owner = os.stat(f"/proc/{pid}").st_uid
    except OSError:
        continue
    if pid == str(os.getpid()) or pss == 0:
        continue
    line = " ".join(args)
    if "task-manager/app.qml" in line or "task-manager/procs.py" in line:
        continue                                   # this app's own shell does not list itself
    exe = program(pid, args, comm)
    kind, name = group(pid, comm, args, exe)
    if kind == "other":
        # t3code and T3-Code are one program: merge on a plain key, show the first spelling seen
        name = shown.setdefault(re.sub(r"[^a-z0-9]", "", name.lower()), name[:1].upper() + name[1:])
    killable = owner == my_uid or os.getuid() == 0
    if kind == "other" and not killable:
        kind, name = "system", "System services"
    ent = procs.setdefault((kind, name), {"pids": [], "mem": 0, "exe": exe})
    ent["mem"] += pss
    if killable:
        ent["pids"].append(int(pid))
        live[int(pid)] = cpu_ticks(pid)

t0 = time.monotonic()
cpu0, idle0 = cpu_snap()
r0, w0 = disk_snap()
time.sleep(0.35)
for pid, before in live.items():
    live[pid] = max(0, cpu_ticks(pid) - before)
cpu1, idle1 = cpu_snap()
r1, w1 = disk_snap()
wall = time.monotonic() - t0

span = max(1, cpu1 - cpu0)
cpu_busy = round(100 * (1 - (idle1 - idle0) / span), 1)
st = os.statvfs("/")
disk = {"read": round((r1 - r0) / 2 / 1024 / wall, 1), "write": round((w1 - w0) / 2 / 1024 / wall, 1),
        "total": st.f_blocks * st.f_frsize // 1024, "free": st.f_bavail * st.f_frsize // 1024}

names, find = desktop_icons(), icon_index()
out = []
for (kind, name), ent in procs.items():
    ticks = sum(live.get(p, 0) for p in ent["pids"])
    out.append({"name": name, "kind": kind, "mem": ent["mem"],
                "icon": icon_for(kind, name, ent["exe"], names, find),
                "cpu": round(100 * ticks / (wall * hz), 1) if wall > 0 else 0,
                "pids": sorted(ent["pids"])})
out.sort(key=lambda p: (-p["mem"], p["name"]))

mem = {l.split(":")[0]: int(l.split()[1]) for l in open("/proc/meminfo")}
print(json.dumps({"total": mem["MemTotal"], "free": mem["MemAvailable"],
                  "used": mem["MemTotal"] - mem["MemAvailable"],
                  "swap": max(0, mem["SwapTotal"] - mem["SwapFree"]),
                  "cpu": cpu_busy, "ncpu": os.cpu_count() or 1, "disk": disk, "gpu": gpu_info(),
                  "root": os.getuid() == 0, "procs": out}, separators=(",", ":")))
