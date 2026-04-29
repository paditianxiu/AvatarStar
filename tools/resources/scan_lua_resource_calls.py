import argparse
import json
import os
import re
from collections import defaultdict
from dataclasses import dataclass
from typing import Any, Dict, List, Optional


RESOURCE_EXTS = (
    "mesh",
    "dds",
    "tga",
    "png",
    "jpg",
    "jpeg",
    "bmp",
    "skel",
    "skeleton",
    "material",
    "anim",
    "ani",
    "fx",
    "particle",
    "wav",
    "ogg",
    "mp3",
)


LITERAL_RE = re.compile(
    r"""(?P<q>["'])(?P<val>[^"'\\\r\n]+?\.(?P<ext>"""
    + "|".join(re.escape(x) for x in RESOURCE_EXTS)
    + r"""))(?P=q)""",
    re.IGNORECASE,
)


def infer_kind(line: str) -> str:
    s = line.lower()
    if "setmaptexture" in s:
        return "map_texture"
    if "setmesh" in s or "addmesh" in s or "addedgemesh" in s:
        return "mesh"
    if "addphysx" in s:
        return "physx"
    if "setskeleton" in s or ".skel" in s or ".skeleton" in s:
        return "skeleton"
    if "gui.icon" in s:
        return "ui_icon"
    if "gui.image" in s or "texture(" in s:
        return "ui_texture"
    if ".material" in s:
        return "material"
    if ".particle" in s:
        return "particle"
    if ".anim" in s or ".ani" in s:
        return "animation"
    if ".wav" in s or ".ogg" in s or ".mp3" in s:
        return "audio"
    return "resource"


@dataclass
class Call:
    file: str
    line: int
    kind: str
    resource: str
    ext: str
    snippet: str


def iter_lua_files(root: str) -> List[str]:
    out: List[str] = []
    for base, _dirs, files in os.walk(root):
        for name in files:
            if not name.lower().endswith(".lua"):
                continue
            out.append(os.path.join(base, name))
    out.sort()
    return out


def scan_file(path: str, rel: str) -> List[Call]:
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError:
        return []

    text = data.decode("utf-8", errors="ignore")
    out: List[Call] = []
    for idx, line in enumerate(text.splitlines(), start=1):
        if "." not in line:
            continue
        kind = infer_kind(line)
        for m in LITERAL_RE.finditer(line):
            val = m.group("val").replace("\\", "/")
            ext = (m.group("ext") or "").lower()
            out.append(
                Call(
                    file=rel,
                    line=idx,
                    kind=kind,
                    resource=val,
                    ext=ext,
                    snippet=line.strip()[:300],
                )
            )
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Scan decrypted/unpacked Lua scripts for resource usage (mesh/texture/etc.).")
    ap.add_argument(
        "--root",
        default=os.path.join("unpacked_scripts", "AvatarStar"),
        help="Lua root to scan (default: unpacked_scripts/AvatarStar)",
    )
    ap.add_argument(
        "--out-calls",
        default=os.path.join("tools", "resources", "lua_resource_calls.json"),
        help="Output JSON (calls) path",
    )
    ap.add_argument(
        "--out-usage",
        default=os.path.join("tools", "resources", "lua_resource_usage.json"),
        help="Output JSON (usage summary) path",
    )
    args = ap.parse_args()

    root = args.root
    files = iter_lua_files(root)

    calls: List[Call] = []
    for p in files:
        rel = os.path.relpath(p, root).replace("\\", "/")
        calls.extend(scan_file(p, rel))

    usage: Dict[str, Dict[str, Any]] = defaultdict(lambda: {"count": 0, "ext": "", "kinds": defaultdict(int), "files": defaultdict(int)})
    for c in calls:
        u = usage[c.resource]
        u["count"] += 1
        u["ext"] = c.ext
        u["kinds"][c.kind] += 1
        u["files"][c.file] += 1

    usage_out: Dict[str, Any] = {}
    for res, u in usage.items():
        usage_out[res] = {
            "count": u["count"],
            "ext": u["ext"],
            "kinds": dict(sorted(u["kinds"].items(), key=lambda x: (-x[1], x[0]))),
            "topFiles": [
                {"file": f, "count": n}
                for f, n in sorted(u["files"].items(), key=lambda x: (-x[1], x[0]))[:20]
            ],
        }

    os.makedirs(os.path.dirname(args.out_calls), exist_ok=True)
    with open(args.out_calls, "w", encoding="utf-8") as f:
        json.dump(
            {
                "version": 1,
                "root": os.path.abspath(root),
                "totalCalls": len(calls),
                "calls": [c.__dict__ for c in calls],
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    os.makedirs(os.path.dirname(args.out_usage), exist_ok=True)
    with open(args.out_usage, "w", encoding="utf-8") as f:
        json.dump(
            {
                "version": 1,
                "root": os.path.abspath(root),
                "uniqueResources": len(usage_out),
                "resources": usage_out,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    print(f"Wrote {len(calls)} calls -> {args.out_calls}")
    print(f"Wrote {len(usage_out)} resources -> {args.out_usage}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

