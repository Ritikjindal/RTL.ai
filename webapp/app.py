#!/usr/bin/env python3
# webapp/app.py — browser front end for the RTL.ai optimizer.
#
#   pip install flask
#   python3 webapp/app.py      -> http://127.0.0.1:5000
#
# Runs locally rather than hosted: the pipeline needs Yosys, OpenSTA and SymbiYosys on
# PATH plus an ANTHROPIC_API_KEY, none of which belong in a public deployment. The app
# is a thin shell around optimize.py -- it uploads the design, streams the real run
# output, and presents the artifacts the run leaves behind. No logic is duplicated
# here, so the web demo cannot drift from what the command line does.

import io
import json
import os
import queue
import re
import shutil
import signal
import subprocess
import threading
import uuid
import zipfile
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request, send_file

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Load .env if present. The web app is often launched from an IDE terminal that never
# sources ~/.bashrc, so relying on the shell's exported key makes the demo fragile.
_env_file = PROJECT_ROOT / ".env"
if _env_file.exists():
    for _line in _env_file.read_text().splitlines():
        _line = _line.strip()
        if _line and not _line.startswith("#") and "=" in _line:
            _k, _v = _line.split("=", 1)
            os.environ.setdefault(_k.strip(), _v.strip().strip('"').strip("'"))

# Put the EDA tools on PATH explicitly. The app is usually launched from an IDE
# terminal that never sourced the oss-cad-suite environment script, and the failure
# mode is an unhelpful FileNotFoundError deep inside a subprocess call.
_cad = os.environ.get("OSS_CAD_SUITE")
if _cad:
    os.environ["PATH"] = f"{Path(_cad) / 'bin'}:{os.environ['PATH']}"

JOBS_DIR = PROJECT_ROOT / "runs" / "_web"
JOBS_DIR.mkdir(parents=True, exist_ok=True)

app = Flask(__name__)

# job_id -> {"queue": Queue, "proc": Popen, "dir": Path, "done": bool, "result": dict}
JOBS = {}
REQUIRED_TOOLS = ["yosys", "sta", "sby"]

def _stream_process(job_id: str, cmd: list, cwd: Path, env: dict):
    """Run the pipeline, pushing each output line onto the job's queue."""
    job = JOBS[job_id]
    q = job["queue"]

    # Its own process group, so /stop can kill the whole tree (optimize.py plus
    # whichever yosys/opensta/symbiyosys child happens to be running under it) in
    # one shot instead of leaving orphans behind.
    popen_kwargs = {}
    if os.name == "nt":
        popen_kwargs["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        popen_kwargs["start_new_session"] = True

    proc = subprocess.Popen(
        cmd, cwd=str(cwd), env=env, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, bufsize=1, **popen_kwargs,
    )
    job["proc"] = proc

    transcript = []
    for line in proc.stdout:
        transcript.append(line)
        q.put(line.rstrip("\n"))

    proc.wait()
    (job["dir"] / "transcript.log").write_text("".join(transcript))

    job["result"] = _collect_results(job["run_name"], job["mode"])
    job["done"] = True
    q.put("__STOPPED__" if job.get("stopped") else "__DONE__")


def _stop_job(job: dict):
    """Kill a running job's whole process tree. Best-effort: if the process has
    already exited there is nothing to do. Only sends signals -- the background
    thread already blocked on proc.wait() in _stream_process notices the exit and
    finishes the job, so this never waits itself (that would race the other wait())."""
    proc = job.get("proc")
    if proc is None or proc.poll() is not None:
        return
    job["stopped"] = True
    try:
        if os.name == "nt":
            proc.send_signal(signal.CTRL_BREAK_EVENT)
        else:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
    except (ProcessLookupError, OSError):
        pass

    def _force_kill_if_still_alive():
        if proc.poll() is None:
            try:
                if os.name == "nt":
                    proc.kill()
                else:
                    os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except (ProcessLookupError, OSError):
                pass

    threading.Timer(5.0, _force_kill_if_still_alive).start()


def _collect_results(run_name: str, mode: str) -> dict:
    """
    Gather what the run left on disk: the baseline and best-candidate measurements,
    the formal verdicts, and the optimized RTL. Read from result.json rather than
    scraped from stdout, so the numbers shown are the same ones the tool recorded.

    run_name is the unique --name this job passed to analyze.py/optimize.py, so the
    glob below can only ever match the run directory this specific job produced --
    never a leftover directory from a previous or concurrent job.
    """
    out = {"baseline": None, "candidate": None, "formal": [], "files": [], "history": None}

    pattern = f"{run_name}_optimize_*" if mode == "optimize" else f"{run_name}_*"
    runs = sorted((PROJECT_ROOT / "runs").glob(pattern),
                  key=lambda p: p.stat().st_mtime, reverse=True)
    if not runs:
        return out
    run = runs[0]
    out["run_dir"] = str(run.relative_to(PROJECT_ROOT))

    base = run / "baseline" / "result.json"
    if base.exists():
        out["baseline"] = json.loads(base.read_text())

    # Every candidate that got as far as being measured -- the full audit trail,
    # including ones formally proven but not accepted (didn't improve enough).
    last_candidate_path = None
    for res in sorted(run.glob("**/candidate/result.json")):
        data = json.loads(res.read_text())
        out["formal"].append({
            "path": str(res.parent.parent.relative_to(run)),
            "summary": data.get("formal_summary"),
            "passed": data.get("formal_passed"),
        })
        last_candidate_path = res

    optimized = run / "optimized"

    # The definitive final result lives at optimized/result.json (written once,
    # unambiguously, by optimize.py). Falling back to the last candidate seen above
    # only covers analyze.py's --candidate A/B mode, which has no round structure.
    final_result = optimized / "result.json"
    if final_result.exists():
        out["candidate"] = json.loads(final_result.read_text())
    elif last_candidate_path is not None:
        out["candidate"] = json.loads(last_candidate_path.read_text())

    history_file = run / "history.json"
    if history_file.exists():
        out["history"] = json.loads(history_file.read_text())

    if optimized.exists():
        top_module = (out["baseline"] or {}).get("top_module")
        out["files"] = _files_top_first(optimized, top_module)

    return out


_MODULE_RE = re.compile(r"^\s*module\s+([A-Za-z_]\w*)", re.MULTILINE)


def _files_top_first(optimized_dir: Path, top_module: str | None) -> list:
    """File names for the UI, with whichever file defines the top module first."""
    files = sorted(f.name for f in optimized_dir.glob("*.v"))
    if not top_module:
        return files

    def defines_top(name: str) -> bool:
        text = (optimized_dir / name).read_text(errors="ignore")
        return top_module in _MODULE_RE.findall(text)

    return sorted(files, key=lambda name: 0 if defines_top(name) else 1)


@app.route("/")
def index():
    return render_template("index.html")

@app.route("/health")
def health():
    missing = [t for t in REQUIRED_TOOLS if shutil.which(t) is None]
    return jsonify({
        "ok": not missing and bool(os.environ.get("ANTHROPIC_API_KEY")),
        "missing_tools": missing,
        "api_key": bool(os.environ.get("ANTHROPIC_API_KEY")),
        "eqy": shutil.which("eqy") is not None,
    })

@app.route("/presets")
def presets():
    """Designs shipped with the repo, so a visitor can run something immediately."""
    return jsonify([
        {"name": "mac_unit — 4-lane MAC, fails timing at -0.22 ns (~2 min)",
         "rtl": ["designs/mac_unit.v"], "sdc": "constraints/mac_unit.sdc"},
        {"name": "bm_mac8 — 8-lane MAC, serial add chain (~2 min)",
         "rtl": ["designs/bm_mac8.v"], "sdc": "constraints/bm_mac8.sdc"},
        {"name": "benchmark_top — 48K cells, 5 clock domains (~40 min)",
         "rtl": ["designs/benchmark_top.v", "designs/mac_unit.v", "designs/bm_fir6.v",
                 "designs/bm_dot4.v", "designs/bm_mac8.v", "designs/bm_fsm_ctrl.v",
                 "designs/clk_divider.v", "designs/cdc_sync.v",
                 "designs/cdc_handshake.v", "designs/reset_sync.v"],
         "sdc": "constraints/benchmark_top.sdc",
         "targets": "config/targets_benchmark.json"},
    ])


@app.route("/run", methods=["POST"])
def run():
    job_id = uuid.uuid4().hex[:12]
    job_dir = JOBS_DIR / job_id
    job_dir.mkdir(parents=True, exist_ok=True)

    mode = request.form.get("mode", "optimize")
    preset = request.form.get("preset")

    if preset:
        spec = json.loads(preset)
        rtl = [str(PROJECT_ROOT / p) for p in spec["rtl"]]
        sdc = str(PROJECT_ROOT / spec["sdc"])
        targets = spec.get("targets")
    else:
        rtl = []
        for f in request.files.getlist("rtl"):
            dest = job_dir / Path(f.filename).name
            f.save(dest)
            rtl.append(str(dest))
        sdc_file = request.files.get("sdc")
        if sdc_file is None or not rtl:
            return jsonify({"error": "Provide at least one RTL file and one SDC file."}), 400
        sdc_dest = job_dir / Path(sdc_file.filename).name
        sdc_file.save(sdc_dest)
        sdc = str(sdc_dest)
        targets = None

    top = request.form.get("top")

    script = "optimize.py" if mode == "optimize" else "analyze.py"
    run_name = f"web_{job_id}"
    cmd = ["python3", "-u", script, "--rtl", *rtl, "--sdc", sdc, "--name", run_name]
    if top:
        cmd += ["--top", top]

    env = dict(os.environ)
    if targets:
        env["RTLAI_TARGETS"] = str(PROJECT_ROOT / targets)

    JOBS[job_id] = {"queue": queue.Queue(), "proc": None, "dir": job_dir,
                    "done": False, "result": None, "cmd": " ".join(cmd),
                    "mode": mode, "run_name": run_name}

    threading.Thread(target=_stream_process,
                     args=(job_id, cmd, PROJECT_ROOT, env), daemon=True).start()

    return jsonify({"job": job_id, "cmd": " ".join(cmd)})


@app.route("/stream/<job_id>")
def stream(job_id):
    job = JOBS.get(job_id)
    if job is None:
        return jsonify({"error": "unknown job"}), 404

    def gen():
        while True:
            line = job["queue"].get()
            if line == "__DONE__":
                yield f"event: done\ndata: {json.dumps(job['result'])}\n\n"
                return
            if line == "__STOPPED__":
                yield f"event: stopped\ndata: {json.dumps(job['result'])}\n\n"
                return
            yield f"data: {json.dumps(line)}\n\n"

    return Response(gen(), mimetype="text/event-stream",
                    headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})


@app.route("/stop/<job_id>", methods=["POST"])
def stop(job_id):
    job = JOBS.get(job_id)
    if job is None:
        return jsonify({"error": "unknown job"}), 404
    _stop_job(job)
    return jsonify({"ok": True})


def _optimized_file(job_id: str, name: str) -> Path:
    job = JOBS.get(job_id)
    if job is None or not job.get("result"):
        return None
    target = PROJECT_ROOT / job["result"]["run_dir"] / "optimized" / Path(name).name
    return target if target.exists() else None


@app.route("/view/<job_id>/<path:name>")
def view(job_id, name):
    """Raw source of one optimized file, for the in-page preview."""
    target = _optimized_file(job_id, name)
    if target is None:
        return jsonify({"error": "not found"}), 404
    return Response(target.read_text(), mimetype="text/plain")


@app.route("/download/<job_id>/<path:name>")
def download(job_id, name):
    target = _optimized_file(job_id, name)
    if target is None:
        return jsonify({"error": "not found"}), 404
    return send_file(target, as_attachment=True)


@app.route("/download-all/<job_id>")
def download_all(job_id):
    """Every optimized .v file as one zip, for designs with more than one file."""
    job = JOBS.get(job_id)
    if job is None or not job.get("result"):
        return jsonify({"error": "no result"}), 404
    optimized = PROJECT_ROOT / job["result"]["run_dir"] / "optimized"
    files = sorted(optimized.glob("*.v")) if optimized.exists() else []
    if not files:
        return jsonify({"error": "no files"}), 404

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in files:
            zf.write(f, arcname=f.name)
    buf.seek(0)
    return send_file(buf, as_attachment=True, download_name=f"{job_id}_optimized.zip",
                      mimetype="application/zip")


if __name__ == "__main__":
    app.run(debug=True, threaded=True, port=5000)