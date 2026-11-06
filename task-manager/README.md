# task-manager

What the desktop is spending, and one way to take it back. A Quickshell 0.3 + Tacit.Kit app.

Run: `qs -p app.qml` (install.sh adds a .desktop entry and the window rules: floating, 900×700, centred).

## Parts and why

- **Four gauges** across the head, each a word, a figure, an accent bar and a quieter line under it:
  Memory (used / total, free and swap beneath), CPU (busy % of all cores, core count), Disk (space
  used / total, live Read and Write speed), GPU (busy %, its memory through NVML or sysfs — "No
  reading" when neither answers).
- **Field** ("Search programs") narrows the list as you type.
- **RowList of ListRows** — one tab stop, owns the arrows; typing jumps. Each row is a *program*,
  not a thread: its icon (resolved from desktop entries and the icon themes, blank when the program
  has none), its name, the group beside it (Tacit app / Desktop / System), and two facts:
  real memory share and CPU now.
- **Slab** `tone: "risk"` with `confirm` at the foot: the first press asks ("End Firefox?"), the
  second ends it. No dialog — the question lives in the action, per the kit's rules. Escape backs
  out of the question, leaving the window open.
- **Notice** says what happened ("Ended Firefox"), without Undo: an ended program does not return.

## Data

`procs.py` answers one line of JSON per run — tacit-mem's counting (PSS + SwapPss per process,
merged per program, versioned installs named by their folder) plus CPU measured over a 0.35 s
sample, whole-machine busy % from `/proc/stat`, disk sectors and space, and GPU through NVML
(libnvidia-ml directly — 20 ms when the driver is awake, with an 8 s cache so a sleeping GPU is
not woken every refresh). The app reruns it every two seconds, pauses while the ring is asking,
and keeps the cursor on the same program across refreshes. `kill` (SIGTERM) goes to every pid of
the chosen program at once. Without sudo, root's programs join System services and have no pids,
so the ring stays quiet.
