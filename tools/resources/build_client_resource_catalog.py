#!/usr/bin/env python
"""
Build a *human-friendly* resource catalog from:

1) Unpacked client asset folder (tga/dds/mesh/anim/...)
   default: D:\\Avatarstar\\UnPde\\AvatarStar
2) Unpacked/decrypted Lua scripts in this repo:
   default: unpacked_scripts/AvatarStar
3) (Optional but recommended) Decompiled Lua scripts:
   default: D:\\Avatarstar\\UnPde\\UnLuacBAT\\AvatarStar_Lua_Decompiled

Output:
  - JSON: tools/resources/client_resource_catalog.json
  - Markdown: docs/client_resource_catalog_YYYYMMDD.md

This is intentionally heuristic-based. It aims to give you a complete *index* of what exists
and a reasonable *classification* for server-side item definitions.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


ASSET_EXTS = {
    ".tga",
    ".dds",
    ".mesh",
    ".skel",
    ".anim",
    ".material",
    ".fx",
    ".particle",
    ".wav",
    ".ogg",
    ".mp3",
    ".lua",
    ".luac",
}


def norm_slash(s: str) -> str:
    return s.replace("\\", "/")


def try_read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def iter_files(root: Path) -> Iterable[Path]:
    # Avoid storing the full list in memory; stream.
    for base, _dirs, files in os.walk(root):
        for name in files:
            yield Path(base) / name


def top_prefix(rel: str, depth: int = 2) -> str:
    parts = [p for p in rel.split("/") if p]
    if not parts:
        return ""
    return "/".join(parts[: min(depth, len(parts))])


@dataclass
class ItemDef:
    key: str  # usually lua file stem
    category: str
    icon: str
    sources: List[str]


@dataclass
class WeaponDef:
    key: str  # usually lua file stem
    weapon_type: str
    name: str
    meshes: List[str]
    icon: str
    kill_icon: str
    ammo_icon: str
    crosshair_icon: str
    sources: List[str]


RE_SETICON = re.compile(r"""SetIcon\(\s*["'](?P<path>[^"']+)["']\s*\)""", re.IGNORECASE)
RE_TEXTURE = re.compile(r"""texture\(\s*["'](?P<path>[^"']+)["']\s*\)""", re.IGNORECASE)
RE_WEAPON_NAME = re.compile(r"""weapon\.name\s*=\s*["'](?P<name>[^"']+)["']""", re.IGNORECASE)
RE_SETMESH = re.compile(r"""SetMesh\([^,]+,\s*["'](?P<path>[^"']+\.mesh)["']""", re.IGNORECASE)
RE_ICON = re.compile(r"""weapon\.icon\s*=\s*texture\(\s*["'](?P<path>[^"']+)["']\s*\)""", re.IGNORECASE)
RE_KILL_ICON = re.compile(r"""weapon\.kill_icon\s*=\s*texture\(\s*["'](?P<path>[^"']+)["']\s*\)""", re.IGNORECASE)
RE_AMMO_ICON = re.compile(r"""weapon\.ammo_icon\s*=\s*texture\(\s*["'](?P<path>[^"']+)["']\s*\)""", re.IGNORECASE)
RE_CROSSHAIR = re.compile(r"""weapon\.cross_hair_icon\s*=\s*texture\(\s*["'](?P<path>[^"']+)["']\s*\)""", re.IGNORECASE)


def infer_item_category(stem: str) -> str:
    s = stem.lower()
    if s.startswith("food_"):
        return "道具/食物"
    if s.startswith("instrument_"):
        return "道具/仪器"
    if s.startswith("ticket_"):
        return "道具/活动券"
    if s.startswith("gift_"):
        return "道具/礼物"
    if s.startswith("bandage_") or s.startswith("bengdai"):
        return "道具/医疗"
    if s.startswith("leechdom_"):
        return "道具/药剂"
    if s.startswith("material_"):
        return "道具/强化材料"
    if s.startswith("item_"):
        return "道具/杂项"
    return "道具/未分类"


def infer_weapon_type(key: str, name: str, icon_path: str, crosshair_path: str) -> str:
    s = " ".join([key, name, icon_path, crosshair_path]).lower()
    # Order matters: more specific first
    if "sniper" in s or "sniperrifle" in s:
        return "武器/狙击枪"
    if "shotgun" in s:
        return "武器/散弹枪"
    if "pistol" in s:
        return "武器/手枪"
    if "smg" in s:
        return "武器/冲锋枪"
    if "machinegun" in s or "mg" in s:
        return "武器/机枪"
    if "bow" in s and "crossbow" not in s:
        return "武器/弓"
    if "crossbow" in s:
        return "武器/弩"
    if "rpg" in s or "rocket" in s or "artillery" in s:
        return "武器/RPG"
    if "grenade" in s:
        return "武器/手雷"
    if "shield" in s or "buckler" in s:
        return "武器/盾"
    if "knife" in s or "knives" in s:
        return "武器/刀"
    if "sprayer" in s:
        return "武器/喷雾器"
    if "grenadelauncher" in s or "m32" in s:
        return "武器/榴弹发射器"
    return "武器/其他"


def scan_lua_item(path: Path, rel: str) -> Optional[Tuple[str, str]]:
    stem = path.stem
    text = try_read_text(path)
    if not text:
        return None

    m = RE_SETICON.search(text)
    if m:
        icon = m.group("path").strip()
        return stem, icon

    # Some scripts use texture("...") only.
    m2 = RE_TEXTURE.search(text)
    if m2 and "/ui/" in (m2.group("path") or ""):
        return stem, m2.group("path").strip()

    return None


def scan_lua_weapon(path: Path) -> Optional[WeaponDef]:
    stem = path.stem
    text = try_read_text(path)
    if not text:
        return None

    meshes = [m.group("path").strip() for m in RE_SETMESH.finditer(text)]
    name = ""
    m_name = RE_WEAPON_NAME.search(text)
    if m_name:
        name = m_name.group("name").strip()

    icon = (RE_ICON.search(text).group("path").strip() if RE_ICON.search(text) else "")
    kill_icon = (RE_KILL_ICON.search(text).group("path").strip() if RE_KILL_ICON.search(text) else "")
    ammo_icon = (RE_AMMO_ICON.search(text).group("path").strip() if RE_AMMO_ICON.search(text) else "")
    cross = (RE_CROSSHAIR.search(text).group("path").strip() if RE_CROSSHAIR.search(text) else "")

    # If it doesn't look like a weapon config, skip.
    if not meshes and not (icon or kill_icon or ammo_icon or cross) and "weapon." not in text:
        return None

    wtype = infer_weapon_type(stem, name, icon, cross)
    return WeaponDef(
        key=stem,
        weapon_type=wtype,
        name=name,
        meshes=meshes,
        icon=icon,
        kill_icon=kill_icon,
        ammo_icon=ammo_icon,
        crosshair_icon=cross,
        sources=[],
    )


def merge_list_unique(items: List[str]) -> List[str]:
    out: List[str] = []
    seen = set()
    for x in items:
        if not x:
            continue
        if x in seen:
            continue
        seen.add(x)
        out.append(x)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Build a categorized client resource catalog.")
    ap.add_argument("--assets-root", default=r"D:\Avatarstar\UnPde\AvatarStar", help="Client unpacked root (tga/dds/mesh/...)")
    ap.add_argument(
        "--lua-root",
        action="append",
        default=[os.path.join("unpacked_scripts", "AvatarStar"), r"D:\Avatarstar\UnPde\UnLuacBAT\AvatarStar_Lua_Decompiled"],
        help="Lua roots to scan (repeatable). Defaults include repo unpacked_scripts + external decompiled Lua.",
    )
    ap.add_argument("--out-json", default=os.path.join("tools", "resources", "client_resource_catalog.json"))
    ap.add_argument("--out-md", default=os.path.join("docs", f"client_resource_catalog_{dt.datetime.now():%Y%m%d}.md"))
    ap.add_argument("--max-examples", type=int, default=8)
    args = ap.parse_args()

    assets_root = Path(args.assets_root)
    lua_roots = [Path(x) for x in (args.lua_root or [])]
    out_json = Path(args.out_json)
    out_md = Path(args.out_md)

    if not assets_root.exists():
        raise SystemExit(f"assets root not found: {assets_root}")

    # 1) Traverse assets root
    by_ext: Dict[str, Dict[str, Any]] = {}
    by_prefix: Dict[str, Dict[str, Any]] = {}
    total_files = 0
    total_bytes = 0

    for p in iter_files(assets_root):
        try:
            st = p.stat()
        except OSError:
            continue

        rel = norm_slash(str(p.relative_to(assets_root)))
        ext = p.suffix.lower()
        total_files += 1
        total_bytes += int(st.st_size)

        if ext in ASSET_EXTS:
            e = by_ext.setdefault(ext, {"count": 0, "bytes": 0, "examples": []})
            e["count"] += 1
            e["bytes"] += int(st.st_size)
            if len(e["examples"]) < args.max_examples:
                e["examples"].append(rel)

            pref = top_prefix(rel, 2)
            pr = by_prefix.setdefault(pref, {"count": 0, "bytes": 0, "examples": []})
            pr["count"] += 1
            pr["bytes"] += int(st.st_size)
            if len(pr["examples"]) < args.max_examples:
                pr["examples"].append(rel)

    # 2) Parse Lua roots for items + weapons
    item_defs: Dict[str, ItemDef] = {}
    weapon_defs: Dict[str, WeaponDef] = {}

    for root in lua_roots:
        if not root.exists():
            continue

        for base, _dirs, files in os.walk(root):
            for name in files:
                if not name.lower().endswith(".lua"):
                    continue
                p = Path(base) / name
                rel = norm_slash(str(p.relative_to(root)))
                stem = p.stem

                # Items: only focus item folder for now (this is where your consumables/tool icons live).
                if "/item/" in f"/{rel.lower()}/":
                    r = scan_lua_item(p, rel)
                    if r:
                        key, icon = r
                        cat = infer_item_category(key)
                        it = item_defs.get(key)
                        if it is None:
                            item_defs[key] = ItemDef(key=key, category=cat, icon=icon, sources=[f"{root}:{rel}"])
                        else:
                            if not it.icon and icon:
                                it.icon = icon
                            it.sources.append(f"{root}:{rel}")

                # Weapons: weapon folder contains most gun configs; also Other/** contains some weapon configs.
                if "/weapon/" in f"/{rel.lower()}/" or rel.lower().startswith("other/0x"):
                    w = scan_lua_weapon(p)
                    if w:
                        existing = weapon_defs.get(w.key)
                        if existing is None:
                            w.sources = [f"{root}:{rel}"]
                            weapon_defs[w.key] = w
                        else:
                            existing.sources.append(f"{root}:{rel}")
                            existing.meshes = merge_list_unique(existing.meshes + w.meshes)
                            if not existing.name and w.name:
                                existing.name = w.name
                            if not existing.icon and w.icon:
                                existing.icon = w.icon
                            if not existing.kill_icon and w.kill_icon:
                                existing.kill_icon = w.kill_icon
                            if not existing.ammo_icon and w.ammo_icon:
                                existing.ammo_icon = w.ammo_icon
                            if not existing.crosshair_icon and w.crosshair_icon:
                                existing.crosshair_icon = w.crosshair_icon
                            # keep the more specific type if possible
                            if existing.weapon_type == "武器/其他" and w.weapon_type != "武器/其他":
                                existing.weapon_type = w.weapon_type

    # 3) Build helper indices for "装备/徽章/戒指/背部装置/造型部件"
    # These are best derived from the *asset stem* catalog (tools/resources/catalog.json) if present.
    stem_catalog_path = Path("tools/resources/catalog.json")
    stem_hits: Dict[str, List[Dict[str, Any]]] = {"徽章": [], "戒指": [], "背部装置": [], "造型部件": []}

    if stem_catalog_path.exists():
        catalog = json.loads(stem_catalog_path.read_text(encoding="utf-8"))
        items = catalog.get("items") if isinstance(catalog, dict) else None
        if isinstance(items, list):
            for it in items:
                if not isinstance(it, dict):
                    continue
                stem = str(it.get("stem") or "")
                examples = it.get("examples") or []
                if not stem:
                    continue
                s = stem.lower()
                if re.match(r"^badge\d+", s):
                    stem_hits["徽章"].append({"stem": stem, "examples": examples[:3]})
                if "mesh_ring" in s or s.startswith("ring"):
                    stem_hits["戒指"].append({"stem": stem, "examples": examples[:3]})
                if "wing" in s or "back" in s or "jet" in s or "propeller" in s:
                    # noisy: keep only a small subset of stems that look like parts/props
                    if any(k in s for k in ("mesh_", "_lod0", "wing", "jet", "propeller")):
                        stem_hits["背部装置"].append({"stem": stem, "examples": examples[:3]})
                if any(
                    s.endswith(suf)
                    for suf in (
                        "_hair_lod0",
                        "_eye",
                        "_mouth",
                        "_nose",
                        "_ear",
                        "_outerwear",
                        "_trousers",
                        "_glove",
                        "_shoes",
                        "_helmet_lod0",
                        "_trinket_lod0",
                    )
                ):
                    stem_hits["造型部件"].append({"stem": stem, "examples": examples[:2]})

        # cap lists to keep json reasonable
        for k in list(stem_hits.keys()):
            stem_hits[k] = sorted(stem_hits[k], key=lambda x: x["stem"].lower())[:5000]

    # JSON output
    out_obj: Dict[str, Any] = {
        "version": 1,
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "sources": {
            "assetsRoot": str(assets_root),
            "luaRoots": [str(x) for x in lua_roots if x.exists()],
            "stemCatalog": str(stem_catalog_path) if stem_catalog_path.exists() else None,
        },
        "assets": {
            "totalFiles": total_files,
            "totalBytes": total_bytes,
            "byExt": dict(sorted(by_ext.items(), key=lambda x: (-x[1]["count"], x[0]))),
            "byPrefix": dict(sorted(by_prefix.items(), key=lambda x: (-x[1]["count"], x[0]))),
        },
        "luaIndex": {
            "items": [
                {"key": it.key, "category": it.category, "icon": it.icon, "sources": it.sources[:10]}
                for it in sorted(item_defs.values(), key=lambda x: (x.category, x.key))
            ],
            "weapons": [
                {
                    "key": w.key,
                    "weaponType": w.weapon_type,
                    "name": w.name,
                    "meshes": w.meshes[:8],
                    "icon": w.icon,
                    "killIcon": w.kill_icon,
                    "ammoIcon": w.ammo_icon,
                    "crosshairIcon": w.crosshair_icon,
                    "sources": w.sources[:10],
                }
                for w in sorted(weapon_defs.values(), key=lambda x: (x.weapon_type, x.key))
            ],
        },
        "semantic": stem_hits,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(out_obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Markdown output (short & readable)
    def fmt_bytes(n: int) -> str:
        units = ["B", "KB", "MB", "GB", "TB"]
        x = float(n)
        for u in units:
            if x < 1024 or u == units[-1]:
                return f"{x:.2f}{u}"
            x /= 1024
        return f"{n}B"

    lines: List[str] = []
    lines.append("# AvatarStar 客户端资源目录（自动生成）")
    lines.append("")
    lines.append(f"- 生成时间(UTC)：`{out_obj['generatedAt']}`")
    lines.append(f"- 资源根目录：`{assets_root}`")
    lines.append(f"- Lua Roots：")
    for r in out_obj["sources"]["luaRoots"]:
        lines.append(f"  - `{r}`")
    lines.append("")
    lines.append("## 资源概览")
    lines.append("")
    lines.append(f"- 总文件数：`{total_files}`")
    lines.append(f"- 总大小：`{fmt_bytes(total_bytes)}`")
    lines.append("")
    lines.append("### 按扩展名统计（Top 20）")
    lines.append("")
    exts_sorted = sorted(by_ext.items(), key=lambda x: (-x[1]["count"], x[0]))[:20]
    for ext, meta in exts_sorted:
        lines.append(f"- `{ext}`: {meta['count']} files, {fmt_bytes(int(meta['bytes']))} (e.g. `{meta['examples'][0]}`)")
    lines.append("")
    lines.append("### 按目录前缀统计（Top 30）")
    lines.append("")
    pref_sorted = sorted(by_prefix.items(), key=lambda x: (-x[1]["count"], x[0]))[:30]
    for pref, meta in pref_sorted:
        ex = meta["examples"][0] if meta["examples"] else ""
        lines.append(f"- `{pref}`: {meta['count']} files, {fmt_bytes(int(meta['bytes']))} (e.g. `{ex}`)")
    lines.append("")
    lines.append("## 道具（从 Lua item/*.lua 提取）")
    lines.append("")
    # Summarize by category
    cat_count: Dict[str, int] = {}
    for it in item_defs.values():
        cat_count[it.category] = cat_count.get(it.category, 0) + 1
    for cat, cnt in sorted(cat_count.items(), key=lambda x: (-x[1], x[0])):
        lines.append(f"- {cat}: {cnt}")
    lines.append("")
    lines.append("## 武器（从 Lua weapon/*.lua + Other/** 提取）")
    lines.append("")
    wtype_count: Dict[str, int] = {}
    for w in weapon_defs.values():
        wtype_count[w.weapon_type] = wtype_count.get(w.weapon_type, 0) + 1
    for wtype, cnt in sorted(wtype_count.items(), key=lambda x: (-x[1], x[0])):
        lines.append(f"- {wtype}: {cnt}")
    lines.append("")
    lines.append("## 装备/造型关键词命中（基于 stem catalog 的启发式）")
    lines.append("")
    for k in ["徽章", "戒指", "背部装置", "造型部件"]:
        lines.append(f"### {k}")
        lines.append("")
        arr = stem_hits.get(k) or []
        lines.append(f"- 命中数量（截断后）：`{len(arr)}`")
        if arr:
            lines.append(f"- 示例：`{arr[0]['stem']}`")
        lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    # Write with UTF-8 BOM for best compatibility with Windows tools.
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8-sig")

    print(f"Wrote JSON -> {out_json}")
    print(f"Wrote MD   -> {out_md}")
    print(f"Lua: items={len(item_defs)} weapons={len(weapon_defs)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
