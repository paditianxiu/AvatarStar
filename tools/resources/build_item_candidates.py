import argparse
import json
import os
from collections import Counter
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple


@dataclass(frozen=True)
class Candidate:
    resource: str
    item_type: int  # client t/type (2=Equipment, 3=Item, 5=AvatarCard, 6=SkinCard)
    category: str


def infer_candidate(resource: str) -> Optional[Candidate]:
    r = resource.lower()

    # Skins
    if r.startswith("skin_"):
        return Candidate(resource=resource, item_type=6, category="Skins")

    # Pets / companions
    if r.startswith("pet_"):
        return Candidate(resource=resource, item_type=5, category="Pets")

    # Decorations / jewelry
    if r.startswith("deco_"):
        return Candidate(resource=resource, item_type=2, category="Decorations")

    # Enhancement / crafting materials
    if r.startswith("material_"):
        return Candidate(resource=resource, item_type=3, category="Materials")

    # Weapons (very rough prefixes used by our server db; extend as you discover more)
    weapon_prefixes = (
        "pistol_",
        "machinegun_",
        "bow_",
        "knives_",
        "grenade_",
    )
    if r.startswith(weapon_prefixes):
        return Candidate(resource=resource, item_type=2, category="Weapons")

    # Consumables / tools
    consumable_prefixes = (
        "bandage_",
        "food_",
        "instrument_",
        "ticket_",
        "leechdom_",
        "item_",
    )
    if r.startswith(consumable_prefixes):
        return Candidate(resource=resource, item_type=3, category="Consumables")

    return None


def load_catalog_stems(path: str) -> List[str]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # tools/resources/catalog.json format: { items: [{ stem: "...", ... }, ...] }
    if isinstance(data, dict) and isinstance(data.get("items"), list):
        out: List[str] = []
        for it in data["items"]:
            if isinstance(it, dict) and "stem" in it:
                out.append(str(it["stem"]))
        if out:
            return out

    # tools/assets/catalog.py legacy format: { "stems": [...], ... }
    if isinstance(data, dict) and isinstance(data.get("stems"), list):
        return [str(x) for x in data["stems"]]

    # Fallback: accept a plain list
    if isinstance(data, list):
        return [str(x) for x in data]

    raise ValueError(f"Unsupported catalog format: {path}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Build item candidates from asset stem catalog.")
    ap.add_argument(
        "--catalog",
        default=os.path.join("tools", "resources", "catalog.json"),
        help="Path to catalog.json (default: tools/resources/catalog.json)",
    )
    ap.add_argument(
        "--out",
        default=os.path.join("tools", "resources", "item_candidates.json"),
        help="Output json path (default: tools/resources/item_candidates.json)",
    )
    args = ap.parse_args()

    stems = load_catalog_stems(args.catalog)
    candidates: Dict[str, Candidate] = {}
    for stem in stems:
        c = infer_candidate(stem)
        if c is None:
            continue
        candidates[c.resource] = c

    # Build output
    out_dir = os.path.dirname(args.out)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    counts = Counter((c.category, c.item_type) for c in candidates.values())
    summary = [
        {"category": cat, "itemType": t, "count": cnt}
        for (cat, t), cnt in sorted(counts.items(), key=lambda x: (-x[1], x[0][0], x[0][1]))
    ]

    obj: Dict[str, Any] = {
        "version": 1,
        "sourceCatalog": os.path.normpath(args.catalog),
        "summary": summary,
        "items": [
            {"resource": c.resource, "type": c.item_type, "category": c.category}
            for c in sorted(candidates.values(), key=lambda x: (x.category, x.item_type, x.resource))
        ],
    }

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)

    print(f"Wrote {len(obj['items'])} candidates -> {args.out}")
    if summary:
        print("Top categories:")
        for row in summary[:10]:
            print(f"  {row['category']} (type={row['itemType']}): {row['count']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
