import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def load_json(path: str) -> Any:
    # Some client dumps/configs contain UTF-8 BOM.
    with open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)


def write_json(path: str, obj: Any) -> None:
    out_dir = os.path.dirname(path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)


def norm_slash(s: str) -> str:
    return s.replace("\\", "/")


def stem_of_resource_path(res: str) -> str:
    # Accept both "foo/bar.ext" and "/foo/bar.ext".
    r = res.strip()
    if "/" in r:
        base = r.rsplit("/", 1)[-1]
    else:
        base = r
    if "." in base:
        return base.rsplit(".", 1)[0]
    return base


def build_shop_index(shop_config_json: Any) -> Dict[str, Any]:
    out: Dict[str, Any] = {"items": []}
    shop = (shop_config_json or {}).get("shop") if isinstance(shop_config_json, dict) else None
    cats = (shop or {}).get("categories") if isinstance(shop, dict) else None
    if not isinstance(cats, dict):
        return out

    for cat, cat_obj in cats.items():
        items = cat_obj.get("items") if isinstance(cat_obj, dict) else None
        if not isinstance(items, list):
            continue
        for it in items:
            if not isinstance(it, dict):
                continue
            sid = int(it.get("sid") or 0)
            resource = str(it.get("resource") or "")
            out["items"].append(
                {
                    "sid": sid,
                    "category": str(cat),
                    "type": int(it.get("type") or 0),
                    "grade": int(it.get("grade") or 0),
                    "resource": resource,
                    "stem": resource,
                    "display": str(it.get("display") or ""),
                    "description": str(it.get("description") or ""),
                }
            )
    return out


def build_stem_index(catalog_json: Any) -> Dict[str, Any]:
    items = catalog_json.get("items") if isinstance(catalog_json, dict) else None
    if not isinstance(items, list):
        raise ValueError("Unsupported catalog.json format: missing items[]")

    out: Dict[str, Any] = {"stems": {}}
    for it in items:
        if not isinstance(it, dict):
            continue
        stem = str(it.get("stem") or "")
        if not stem:
            continue
        out["stems"][stem] = {
            "exts": it.get("exts") or [],
            "count": int(it.get("count") or 0),
            "examples": it.get("examples") or [],
        }
    out["uniqueStems"] = len(out["stems"])
    out["totalFiles"] = int(catalog_json.get("totalFiles") or 0)
    return out


def build_lua_usage_index(lua_usage_json: Any) -> Dict[str, Any]:
    res = lua_usage_json.get("resources") if isinstance(lua_usage_json, dict) else None
    if not isinstance(res, dict):
        return {"resources": {}, "byStem": {}}

    by_stem: Dict[str, List[str]] = {}
    for path, meta in res.items():
        s = stem_of_resource_path(str(path))
        by_stem.setdefault(s, []).append(str(path))

    # cap lists for json size
    by_stem_capped = {k: v[:50] for k, v in by_stem.items()}
    return {"resources": res, "byStem": by_stem_capped, "uniqueResources": len(res), "uniqueStems": len(by_stem)}


def main() -> int:
    ap = argparse.ArgumentParser(description="Build a merged catalog for GM: stems + lua usage + shop config.")
    ap.add_argument("--catalog", default=os.path.join("tools", "resources", "catalog.json"))
    ap.add_argument("--lua-usage", default=os.path.join("tools", "resources", "lua_resource_usage.json"))
    ap.add_argument("--shop-config", default=os.path.join("Config", "shop_config.json"))
    ap.add_argument("--out", default=os.path.join("tools", "resources", "game_catalog.json"))
    args = ap.parse_args()

    catalog = load_json(args.catalog)
    stem_index = build_stem_index(catalog)

    lua_usage: Any = None
    if os.path.exists(args.lua_usage):
        lua_usage = load_json(args.lua_usage)
    lua_index = build_lua_usage_index(lua_usage or {})

    shop_cfg: Any = None
    if os.path.exists(args.shop_config):
        shop_cfg = load_json(args.shop_config)
    shop_index = build_shop_index(shop_cfg or {})

    out = {
        "version": 1,
        "sources": {
            "catalog": norm_slash(os.path.abspath(args.catalog)),
            "luaUsage": norm_slash(os.path.abspath(args.lua_usage)),
            "shopConfig": norm_slash(os.path.abspath(args.shop_config)),
        },
        "stems": stem_index["stems"],
        "lua": lua_index,
        "shop": shop_index,
        "stats": {
            "uniqueStems": stem_index["uniqueStems"],
            "luaUniqueResources": lua_index.get("uniqueResources", 0),
            "luaUniqueStems": lua_index.get("uniqueStems", 0),
            "shopItems": len(shop_index.get("items") or []),
        },
    }

    write_json(args.out, out)
    print(f"Wrote -> {args.out}")
    print(json.dumps(out["stats"], ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
