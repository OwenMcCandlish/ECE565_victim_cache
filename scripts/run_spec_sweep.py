#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime

DEFAULT_BENCHES = ["mcf_s", "lbm_s", "bwaves_s", "exchange2_s", "nab_s"]

def log(msg, **kwargs):
    current_datetime = datetime.now()
    print(f'[{current_datetime}] {msg}', flush=True, **kwargs)

@dataclass(frozen=True)
class ConfigCase:
    name: str
    args: List[str]


def stable_id(*parts: str) -> str:
    h = hashlib.sha1()
    for p in parts:
        h.update(p.encode("utf-8"))
        h.update(b"\0")
    return h.hexdigest()[:10]


def run_one(
    gem5_bin: str,
    spec_config_py: str,
    cfg: ConfigCase,
    bench: str,
    outdir: str,
    timeout_s: Optional[int],
    debug_flags: Optional[str],
    resume: bool,
) -> Tuple[str, int, str]:
    """
    Returns (outdir, returncode, status) where status in {"OK","FAIL","SKIP","TIMEOUT"}.
    """
    out = Path(outdir)
    out.mkdir(parents=True, exist_ok=True)

    stats_path = out / "stats.txt"
    if resume and stats_path.exists() and stats_path.stat().st_size > 0:
        return (str(out), 0, "SKIP")

    cmd = [gem5_bin, "-d", str(out)]
    if debug_flags:
        cmd.append(f"--debug-flags={debug_flags}")

    cmd.append(spec_config_py)
    cmd.extend(cfg.args)
    cmd.append(f"--benchmark={bench}")

    meta = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "gem5_bin": gem5_bin,
        "spec_config_py": spec_config_py,
        "config_name": cfg.name,
        "config_args": cfg.args,
        "bench": bench,
        "full_command": cmd,
        "cwd": os.getcwd(),
        "resume": resume,
    }
    (out / "run.json").write_text(json.dumps(meta, indent=2))

    stdout_path = out / "stdout.txt"
    stderr_path = out / "stderr.txt"

    try:
        with stdout_path.open("w") as so, stderr_path.open("w") as se:
            p = subprocess.run(
                cmd,
                stdout=so,
                stderr=se,
                timeout=timeout_s,
                check=False,
            )
        if p.returncode == 0:
            return (str(out), 0, "OK")
        return (str(out), p.returncode, "FAIL")
    except subprocess.TimeoutExpired:
        (out / "TIMEOUT").write_text(f"Timed out after {timeout_s} seconds\n")
        return (str(out), 124, "TIMEOUT")


def load_sweep(path: str) -> Dict[str, Any]:
    data = json.loads(Path(path).read_text())
    for k in ["gem5_bin", "spec_config_py", "configs"]:
        if k not in data:
            raise SystemExit(f"Config file missing required key: {k}")
    data.setdefault("out_root", "out")
    data.setdefault("common_args", [])
    return data


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sweep", required=True, help="Path to sweep_config.json")
    ap.add_argument("--max-workers", type=int, default=max(1, os.cpu_count() // 2))
    ap.add_argument("--reps", type=int, default=1)
    ap.add_argument("--timeout-s", type=int, default=0, help="0 means no timeout")
    ap.add_argument("--debug-flags", default="", help="Optional gem5 --debug-flags=...")
    ap.add_argument("--benches", nargs="*", default=DEFAULT_BENCHES)
    ap.add_argument(
        "--resume",
        action="store_true",
        help="Skip runs whose outdir already contains a non-empty stats.txt",
    )
    args = ap.parse_args()

    sweep = load_sweep(args.sweep)
    gem5_bin = sweep["gem5_bin"]
    spec_cfg = sweep["spec_config_py"]
    out_root = Path(sweep["out_root"])
    common_args: List[str] = list(sweep.get("common_args", []))

    timeout_s = None if args.timeout_s == 0 else args.timeout_s
    debug_flags = args.debug_flags or None

    configs: List[ConfigCase] = []
    for c in sweep["configs"]:
        name = c["name"]
        cfg_args = common_args + list(c.get("args", []))
        configs.append(ConfigCase(name=name, args=cfg_args))

    jobs: List[Tuple[ConfigCase, str, int, Path]] = []
    for cfg in configs:
        for bench in args.benches:
            for rep in range(args.reps):
                run_id = stable_id(cfg.name, bench, str(rep), json.dumps(cfg.args, sort_keys=True))
                outdir = out_root / cfg.name / bench / f"rep{rep:02d}_{run_id}"
                jobs.append((cfg, bench, rep, outdir))

    log(
        f"Planned runs: {len(jobs)} | max_workers={args.max_workers} | resume={args.resume}",
    )

    failures = 0
    with ProcessPoolExecutor(max_workers=args.max_workers) as ex:
        log(cfg)
        futs = [
            ex.submit(
                run_one,
                gem5_bin,
                spec_cfg,
                cfg,
                bench,
                str(outdir),
                timeout_s,
                debug_flags,
                args.resume,
            )
            for (cfg, bench, _rep, outdir) in jobs
        ]

        for fut in as_completed(futs):
            outdir, rc, status = fut.result()
            log(f"[{status}] {outdir}")
            if status in {"FAIL", "TIMEOUT"}:
                failures += 1

    log(f"Done. Failures: {failures} / {len(jobs)}")
    return 0 if failures == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
