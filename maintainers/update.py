#!/usr/bin/env python3
"""Deterministic update helper for cuda-pkgs.

Subcommands:
  check       Report newer NVIDIA manifests, TensorRT releases, and pin revisions.
  fetch       Download specific redistrib manifests into cuda/manifests/.
  bump-patch  Move every selected manifest in pkgs-module.nix to the newest patch
              release of the same major.minor series (safe to run unattended).
  pins        Update the revisions in pins.nix to the latest upstream commit.

Only the Python standard library and `git` are required, so this can run in CI
or from a timer as well as from an agent. Judgement calls (new CUDA scopes, new
packages in a manifest, compatibility data in cuda/db/) are left to the
`update-cuda-pkgs` agent skill.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFESTS = ROOT / "cuda" / "manifests"
PKGS_MODULE = ROOT / "pkgs-module.nix"
PINS = ROOT / "pins.nix"

REDIST_BASE = "https://developer.download.nvidia.com/compute"
# Products whose manifests NVIDIA publishes as redistrib_<version>.json indexes.
INDEXED_PRODUCTS = ("cuda", "cudnn", "cutensor")
# TensorRT manifests are written by hand; we can only report new releases.
TENSORRT_GITHUB = "NVIDIA/TensorRT"

USER_AGENT = "cuda-pkgs-update"


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #


def vkey(version: str) -> tuple[int, ...]:
    return tuple(int(p) for p in re.findall(r"\d+", version))


def series(version: str) -> tuple[int, ...]:
    return vkey(version)[:2]


def newer_patches(upstream: list[str], current: str) -> list[str]:
    """Newer releases in the same major.minor series as `current`.

    Only versions with the same number of components are considered: NVIDIA sometimes
    publishes the same release under a longer name (cudnn 8.9.7 vs 8.9.7.29).
    """
    n = len(vkey(current))
    return [
        v for v in upstream if series(v) == series(current) and len(vkey(v)) == n and vkey(v) > vkey(current)
    ]


def http_get(url: str, headers: dict[str, str] | None = None) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, **(headers or {})})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def upstream_versions(product: str) -> list[str]:
    html = http_get(f"{REDIST_BASE}/{product}/redist/").decode()
    found = set(re.findall(r"redistrib_(\d+(?:\.\d+)+)\.json", html))
    return sorted(found, key=vkey)


def local_versions(product: str) -> list[str]:
    d = MANIFESTS / product
    if not d.is_dir():
        return []
    out = []
    for f in d.glob("redistrib_*.json"):
        out.append(f.name.removeprefix("redistrib_").removesuffix(".json"))
    return sorted(out, key=vkey)


def tensorrt_latest() -> str | None:
    import os

    headers = {"Accept": "application/vnd.github+json"}
    if token := os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    try:
        data = json.loads(http_get(f"https://api.github.com/repos/{TENSORRT_GITHUB}/releases?per_page=20", headers))
    except Exception as e:  # noqa: BLE001 - report and continue
        print(f"warning: could not query TensorRT releases: {e}", file=sys.stderr)
        return None
    versions = []
    for rel in data:
        if rel.get("prerelease") or rel.get("draft"):
            continue
        m = re.fullmatch(r"v?(\d+\.\d+(?:\.\d+)*)", rel.get("tag_name", ""))
        if m:
            versions.append(m.group(1))
    return max(versions, key=vkey) if versions else None


# --------------------------------------------------------------------------- #
# pkgs-module.nix parsing
# --------------------------------------------------------------------------- #

SCOPE_RE = re.compile(
    r"(?P<attr>cudaPackages_\w+)\s*=\s*mkCudaPackages\s*\{(?P<body>[^}]*)\}\s*\"(?P<cuda>[\d.]+)\"\s*;",
    re.DOTALL,
)
SELECTION_RE = re.compile(r"(?P<product>\w+)\s*=\s*\"(?P<version>[\d.]+)\"\s*;")


@dataclass
class Scope:
    attr: str
    selections: dict[str, str]
    cuda_version: str
    span: tuple[int, int] = field(repr=False)


def parse_scopes(text: str) -> list[Scope]:
    scopes = []
    for m in SCOPE_RE.finditer(text):
        sel = {s["product"]: s["version"] for s in SELECTION_RE.finditer(m["body"])}
        scopes.append(Scope(m["attr"], sel, m["cuda"], m.span()))
    return scopes


def rewrite_scope(text: str, scope: Scope, product: str, new: str) -> str:
    start, end = scope.span
    block = text[start:end]
    old = scope.selections[product]
    block = re.sub(
        rf'(\b{re.escape(product)}\s*=\s*"){re.escape(old)}(")', rf"\g<1>{new}\g<2>", block, count=1
    )
    if product == "cuda":
        block = re.sub(rf'(\}}\s*"){re.escape(old)}("\s*;)$', rf"\g<1>{new}\g<2>", block, count=1)
    return text[:start] + block + text[end:]


# --------------------------------------------------------------------------- #
# pins.nix
# --------------------------------------------------------------------------- #

PIN_RE = re.compile(
    r"(?P<name>\w+)\s*=\s*builtins\.fetchGit\s*\{[^}]*?url\s*=\s*\"(?P<url>[^\"]+)\"[^}]*?rev\s*=\s*\"(?P<rev>[0-9a-f]{40})\"",
    re.DOTALL,
)


def remote_head(url: str) -> str:
    out = subprocess.run(["git", "ls-remote", url, "HEAD"], check=True, capture_output=True, text=True).stdout
    return out.split()[0]


# --------------------------------------------------------------------------- #
# Subcommands
# --------------------------------------------------------------------------- #


def fetch_manifest(product: str, version: str) -> Path:
    url = f"{REDIST_BASE}/{product}/redist/redistrib_{version}.json"
    data = http_get(url)
    manifest = json.loads(data)
    got = manifest.get("release_product")
    if got not in (None, product):
        raise SystemExit(f"error: {url} has release_product={got!r}, expected {product!r}")
    dest = MANIFESTS / product / f"redistrib_{version}.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    # Store NVIDIA's bytes unchanged so the file can be diffed against upstream.
    dest.write_bytes(data)
    return dest


def collect(include_network_pins: bool = True) -> dict:
    text = PKGS_MODULE.read_text()
    scopes = parse_scopes(text)
    report: dict = {"manifests": {}, "patch_updates": [], "tensorrt": None, "pins": []}

    for product in INDEXED_PRODUCTS:
        up = upstream_versions(product)
        local = local_versions(product)
        report["manifests"][product] = {
            "local_latest": local[-1] if local else None,
            "upstream_latest": up[-1] if up else None,
            "newer_series": sorted(
                {f"{s[0]}.{s[1]}" for s in map(series, up) if not local or s > series(local[-1])},
                key=vkey,
            ),
        }
        for scope in scopes:
            cur = scope.selections.get(product)
            if not cur:
                continue
            same = newer_patches(up, cur)
            if same:
                report["patch_updates"].append(
                    {"scope": scope.attr, "product": product, "from": cur, "to": same[-1]}
                )

    trt_local = local_versions("tensorrt")
    trt_up = tensorrt_latest()
    report["tensorrt"] = {
        "local_latest": trt_local[-1] if trt_local else None,
        "upstream_latest": trt_up,
        "update_available": bool(trt_up and (not trt_local or vkey(trt_up) > vkey(trt_local[-1]))),
    }

    if include_network_pins:
        for m in PIN_RE.finditer(PINS.read_text()):
            head = remote_head(m["url"])
            report["pins"].append(
                {"name": m["name"], "url": m["url"], "rev": m["rev"], "latest": head, "outdated": head != m["rev"]}
            )
    return report


def has_updates(report: dict) -> bool:
    return bool(
        report["patch_updates"]
        or any(m["newer_series"] for m in report["manifests"].values())
        or (report["tensorrt"] and report["tensorrt"]["update_available"])
        or any(p["outdated"] for p in report["pins"])
    )


def cmd_check(args: argparse.Namespace) -> int:
    report = collect(include_network_pins=not args.no_pins)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("Manifests:")
        for product, m in report["manifests"].items():
            extra = f"  new series: {', '.join(m['newer_series'])}" if m["newer_series"] else ""
            print(f"  {product:9} local {m['local_latest']:<10} upstream {m['upstream_latest']:<10}{extra}")
        t = report["tensorrt"]
        flag = "  (manual manifest update needed)" if t["update_available"] else ""
        print(f"  {'tensorrt':9} local {t['local_latest']!s:<10} upstream {t['upstream_latest']!s:<10}{flag}")
        print("Patch updates (bump-patch):")
        for u in report["patch_updates"] or [None]:
            print(f"  {u['scope']}.{u['product']}: {u['from']} -> {u['to']}" if u else "  none")
        if report["pins"]:
            print("Pins:")
            for p in report["pins"]:
                state = f"{p['rev'][:12]} -> {p['latest'][:12]}" if p["outdated"] else f"{p['rev'][:12]} (up to date)"
                print(f"  {p['name']:5} {state}")
    return 1 if args.exit_code and has_updates(report) else 0


def cmd_fetch(args: argparse.Namespace) -> int:
    for spec in args.specs:
        product, _, version = spec.partition("=")
        if not version:
            raise SystemExit(f"error: expected PRODUCT=VERSION, got {spec!r}")
        if product not in INDEXED_PRODUCTS:
            raise SystemExit(f"error: {product!r} has no upstream manifest index ({', '.join(INDEXED_PRODUCTS)})")
        print(f"fetched {fetch_manifest(product, version).relative_to(ROOT)}")
    return 0


def cmd_bump_patch(args: argparse.Namespace) -> int:
    text = PKGS_MODULE.read_text()
    changes = []
    for product in INDEXED_PRODUCTS:
        up = upstream_versions(product)
        # Re-parse after every rewrite: spans shift when version lengths change.
        for attr in [s.attr for s in parse_scopes(text)]:
            scope = next(s for s in parse_scopes(text) if s.attr == attr)
            cur = scope.selections.get(product)
            if not cur:
                continue
            same = newer_patches(up, cur)
            if not same:
                continue
            new = same[-1]
            if not args.dry_run:
                fetch_manifest(product, new)
            text = rewrite_scope(text, scope, product, new)
            changes.append((attr, product, cur, new))

    for attr, product, old, new in changes:
        print(f"{attr}.{product}: {old} -> {new}")
    if not changes:
        print("no patch updates available")
        return 0
    if args.dry_run:
        return 0

    PKGS_MODULE.write_text(text)
    # Drop manifests that are no longer selected by any scope.
    still_used = {(p, v) for s in parse_scopes(text) for p, v in s.selections.items()}
    for _, product, old, _ in changes:
        if (product, old) not in still_used:
            old_file = MANIFESTS / product / f"redistrib_{old}.json"
            if old_file.exists():
                old_file.unlink()
                print(f"removed {old_file.relative_to(ROOT)}")
    return 0


def cmd_pins(args: argparse.Namespace) -> int:
    text = PINS.read_text()
    changed = False
    for m in PIN_RE.finditer(text):
        head = remote_head(m["url"])
        if head != m["rev"]:
            print(f"{m['name']}: {m['rev'][:12]} -> {head[:12]}")
            text = text.replace(m["rev"], head)
            changed = True
    if changed and not args.dry_run:
        PINS.write_text(text)
    if not changed:
        print("pins are up to date")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("check", help="report available updates")
    p.add_argument("--json", action="store_true", help="machine-readable output")
    p.add_argument("--exit-code", action="store_true", help="exit 1 when updates are available")
    p.add_argument("--no-pins", action="store_true", help="skip checking pins.nix")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("fetch", help="download manifests, e.g. cuda=13.5.0 cudnn=9.28.1")
    p.add_argument("specs", nargs="+", metavar="PRODUCT=VERSION")
    p.set_defaults(func=cmd_fetch)

    p = sub.add_parser("bump-patch", help="bump selected manifests to the newest patch release")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=cmd_bump_patch)

    p = sub.add_parser("pins", help="update pins.nix revisions")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=cmd_pins)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
