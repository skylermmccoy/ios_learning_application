#!/usr/bin/env python3
"""Validate teaching notes (docs/LESSON_FORMAT.md), including card visuals.

Usage: python3 .claude/scripts/validate_lessons.py [FILE ...]   (default: app/Data/lessons.json)
Prints every problem and exits 1 if there is one. Also prints how many cards have a visual.
"""
import json, sys

# SF Symbols allowed in `icons` visuals. The unit test `lessonVisualsAreValid` checks they exist.
SYMBOLS = set("""
lock.fill lock.open.fill lock.shield.fill key.fill shield.fill checkmark.shield.fill exclamationmark.shield.fill
xmark.shield.fill exclamationmark.triangle.fill eye.fill eye.slash.fill person.fill person.2.fill person.3.fill
clock.fill calendar bolt.fill cpu memorychip server.rack network wifi antenna.radiowaves.left.and.right globe
cloud.fill externaldrive.fill internaldrive.fill doc.fill doc.text.fill folder.fill terminal.fill
chevron.left.forwardslash.chevron.right gearshape.fill wrench.and.screwdriver.fill hammer.fill magnifyingglass
list.bullet list.number checklist checkmark.circle.fill xmark.circle.fill questionmark.circle.fill info.circle.fill
checkmark.seal.fill arrow.right arrow.left arrow.up arrow.down arrow.left.arrow.right arrow.up.arrow.down
arrow.triangle.2.circlepath arrow.triangle.branch repeat shuffle plus.circle.fill minus.circle.fill
equal.circle.fill function sum percent number textformat character.cursor.ibeam text.magnifyingglass book.fill
books.vertical.fill graduationcap.fill lightbulb.fill brain.head.profile puzzlepiece.fill flag.fill star.fill
heart.fill trophy.fill target scope chart.bar.fill chart.line.uptrend.xyaxis chart.pie.fill tablecells
square.stack.3d.up.fill square.grid.3x3.fill cube.fill shippingbox.fill tray.full.fill envelope.fill phone.fill
message.fill bubble.left.and.bubble.right.fill exclamationmark.bubble.fill megaphone.fill bell.fill hourglass
timer stopwatch.fill speedometer tortoise.fill hare.fill ant.fill ladybug.fill flame.fill drop.fill leaf.fill
building.2.fill building.columns.fill house.fill creditcard.fill dollarsign.circle.fill banknote.fill cart.fill
printer.fill desktopcomputer laptopcomputer iphone keyboard display cable.connector powerplug.fill waveform
waveform.path.ecg dot.radiowaves.left.and.right door.left.hand.closed hand.raised.fill hand.thumbsup.fill
hand.thumbsdown.fill scissors trash.fill pencil paintbrush.fill link pin.fill map.fill location.fill
binoculars.fill camera.fill photo.fill play.fill pause.fill stop.fill forward.fill backward.fill power rosette
crown.fill scalemass.fill ruler.fill parentheses curlybraces x.squareroot cup.and.saucer.fill
""".split())

errors = []
def err(where, msg): errors.append(f"{where}: {msg}")
def is_num(v): return isinstance(v, (int, float)) and not isinstance(v, bool)
def strs(v, n): return isinstance(v, list) and all(isinstance(x, str) and 0 < len(x) <= n for x in v)

def check_indices(w, v, key, count):
    for i in v.get(key, []) or []:
        if not (isinstance(i, int) and 0 <= i < count): err(w, f"{key} index {i!r} out of range")

def check_pointers(w, v, count):
    for name, i in (v.get("pointers") or {}).items():
        if len(name) > 4: err(w, f"pointer name '{name}' longer than 4")
        if not (isinstance(i, int) and 0 <= i < count): err(w, f"pointer {name} index {i!r} out of range")

def tree_stats(node, depth=1):
    if not isinstance(node, dict) or not isinstance(node.get("label"), str): return None
    count, deepest, labels = 1, depth, [node["label"]]
    for child in node.get("children") or []:
        if child is None: continue
        sub = tree_stats(child, depth + 1)
        if sub is None: return None
        count += sub[0]; deepest = max(deepest, sub[1]); labels += sub[2]
    return count, deepest, labels

def check_visual(w, v, nested=False):
    if not isinstance(v, dict) or "type" not in v: return err(w, "visual needs a type")
    t = v["type"]; w = f"{w} [{t}]"
    cap = v.get("caption")
    if cap is not None and not (isinstance(cap, str) and 0 < len(cap) <= 90): err(w, "caption must be 1-90 chars")
    if t == "bars":
        vals = v.get("values")
        if not (isinstance(vals, list) and 2 <= len(vals) <= 12 and all(is_num(x) and x >= 0 for x in vals)):
            return err(w, "values: 2-12 numbers >= 0")
        if "labels" in v and not (strs(v["labels"], 6) and len(v["labels"]) == len(vals)): err(w, "labels: one per value, <= 6 chars")
        for k in ("highlight", "done"): check_indices(w, v, k, len(vals))
        check_pointers(w, v, len(vals))
    elif t == "cells":
        items = v.get("items")
        if not (strs(items, 7) and 1 <= len(items) <= 10): return err(w, "items: 1-10 strings of <= 7 chars")
        for k in ("highlight", "done"): check_indices(w, v, k, len(items))
        check_pointers(w, v, len(items))
    elif t in ("flow", "stack"):
        key = "steps" if t == "flow" else "layers"
        items = v.get(key)
        if not (strs(items, 30) and 2 <= len(items) <= (6 if t == "flow" else 7)): return err(w, f"{key}: 2-{6 if t == 'flow' else 7} strings of <= 30 chars")
        check_indices(w, v, "highlight", len(items))
    elif t == "graph":
        nodes = v.get("nodes")
        if not (isinstance(nodes, list) and 2 <= len(nodes) <= 10): return err(w, "nodes: 2-10")
        ids = []
        for n in nodes:
            if not (isinstance(n, dict) and isinstance(n.get("id"), str) and is_num(n.get("x")) and is_num(n.get("y"))
                    and 0 <= n["x"] <= 1 and 0 <= n["y"] <= 1): err(w, f"bad node {n!r}"); continue
            if len(n.get("label", n["id"])) > 8: err(w, f"node label '{n.get('label', n['id'])}' longer than 8")
            ids.append(n["id"])
        if len(set(ids)) != len(ids): err(w, "duplicate node ids")
        for i, a in enumerate(nodes):
            for b in nodes[i + 1:]:
                if isinstance(a, dict) and isinstance(b, dict) and is_num(a.get("x")) and is_num(b.get("x")) \
                   and abs(a["x"] - b["x"]) < 0.12 and abs(a["y"] - b["y"]) < 0.12:
                    err(w, f"nodes {a.get('id')} and {b.get('id')} overlap; keep them 0.12 apart")
        for e in v.get("edges") or []:
            if not (isinstance(e, dict) and e.get("from") in ids and e.get("to") in ids): err(w, f"edge {e!r} names an unknown node")
            elif len(e.get("label", "")) > 5: err(w, f"edge label '{e['label']}' longer than 5")
        for h in v.get("highlight") or []:
            if h not in ids: err(w, f"highlight '{h}' is not a node id")
        for pair in v.get("highlightEdges") or []:
            if not (isinstance(pair, list) and len(pair) == 2 and all(x in ids for x in pair)): err(w, f"bad highlightEdges entry {pair!r}")
    elif t == "tree":
        stats = tree_stats(v.get("root"))
        if stats is None: return err(w, "root must be {label, children}")
        count, depth, labels = stats
        if count > 15: err(w, f"{count} nodes; max 15")
        if depth > 5: err(w, f"{depth} levels; max 5")
        for l in labels:
            if not 0 < len(l) <= 5: err(w, f"label '{l}' must be 1-5 chars")
        for h in v.get("highlight") or []:
            if h not in labels: err(w, f"highlight '{h}' is not a label")
    elif t == "table":
        rows = v.get("rows")
        if not (isinstance(rows, list) and 1 <= len(rows) <= 8 and all(strs(r, 16) for r in rows)): return err(w, "rows: 1-8 rows of non-empty strings <= 16 chars")
        width = len(rows[0])
        if not 1 <= width <= 6 or any(len(r) != width for r in rows): err(w, "rows must all have the same 1-6 cells")
        if "headers" in v and not (strs(v["headers"], 16) and len(v["headers"]) == width): err(w, "headers: one per column, <= 16 chars")
        for cell in v.get("highlight") or []:
            if not (isinstance(cell, list) and len(cell) == 2 and all(isinstance(x, int) for x in cell)
                    and 0 <= cell[0] < len(rows) and 0 <= cell[1] < width): err(w, f"highlight cell {cell!r} out of range")
        check_indices(w, v, "highlightRows", len(rows))
    elif t == "plot":
        series = v.get("series")
        if not (isinstance(series, list) and 1 <= len(series) <= 5): return err(w, "series: 1-5")
        for s in series:
            pts = s.get("points") if isinstance(s, dict) else None
            if not (isinstance(s.get("label") if isinstance(s, dict) else None, str) and 0 < len(s["label"]) <= 14): err(w, "series label: 1-14 chars")
            if not (isinstance(pts, list) and 2 <= len(pts) <= 30 and all(isinstance(p, list) and len(p) == 2 and all(is_num(c) for c in p) for p in pts)):
                err(w, "points: 2-30 [x, y] pairs")
        for k in ("xLabel", "yLabel"):
            if k in v and not (isinstance(v[k], str) and 0 < len(v[k]) <= 16): err(w, f"{k}: 1-16 chars")
        if "yMax" in v and not (is_num(v["yMax"]) and v["yMax"] > 0): err(w, "yMax must be a positive number")
    elif t == "timeline":
        ev = v.get("events")
        if not (isinstance(ev, list) and 2 <= len(ev) <= 7): return err(w, "events: 2-7")
        for e in ev:
            if not (isinstance(e, dict) and isinstance(e.get("when"), str) and 0 < len(e["when"]) <= 10
                    and isinstance(e.get("what"), str) and 0 < len(e["what"]) <= 60): err(w, f"bad event {e!r} (when <= 10, what <= 60)")
    elif t == "icons":
        items = v.get("items")
        if not (isinstance(items, list) and 2 <= len(items) <= 6): return err(w, "items: 2-6")
        for it in items:
            if not (isinstance(it, dict) and isinstance(it.get("label"), str) and 0 < len(it["label"]) <= 16): err(w, f"bad item {it!r} (label <= 16)")
            elif it.get("symbol") not in SYMBOLS: err(w, f"symbol '{it.get('symbol')}' is not in the allowed list")
    elif t == "compare":
        for side in ("left", "right"):
            s = v.get(side)
            if not (isinstance(s, dict) and isinstance(s.get("title"), str) and 0 < len(s["title"]) <= 16
                    and strs(s.get("points"), 36) and 1 <= len(s["points"]) <= 4): err(w, f"{side}: title <= 16 chars and 1-4 points of <= 36 chars")
    elif t == "frames":
        if nested: return err(w, "frames cannot be nested")
        fr = v.get("frames")
        if not (isinstance(fr, list) and 2 <= len(fr) <= 8): return err(w, "frames: 2-8")
        kinds = {f.get("type") for f in fr if isinstance(f, dict)}
        if len(kinds) != 1: err(w, f"all frames must share one type, found {sorted(map(str, kinds))}")
        for i, f in enumerate(fr):
            check_visual(f"{w} frame {i + 1}", f, nested=True)
            if isinstance(f, dict) and not f.get("caption"): err(f"{w} frame {i + 1}", "each frame needs a caption")
    else:
        err(w, f"unknown type '{t}'")

def check_file(path):
    notes = json.load(open(path))
    seen, cards, visual, code = set(), 0, 0, 0
    for n in notes:
        w = f"{n.get('subject')}/{n.get('topic')}"
        if (n.get("subject"), n.get("topic")) in seen: err(w, "duplicate note")
        seen.add((n.get("subject"), n.get("topic")))
        if not (isinstance(n.get("title"), str) and 0 < len(n["title"]) <= 24): err(w, "title: 1-24 chars")
        if not n.get("sources"): err(w, "needs at least one source")
        for s in n.get("sources") or []:
            if "url" in s and not str(s["url"]).startswith("https://"): err(w, f"source url must be https: {s['url']}")
        cs = n.get("cards") or []
        if not 3 <= len(cs) <= 6: err(w, f"{len(cs)} cards; need 3-6")
        for i, c in enumerate(cs):
            cw = f"{w} card {i + 1} '{c.get('title')}'"
            cards += 1
            if not c.get("title"): err(cw, "needs a title")
            if not (c.get("body") or c.get("code") or c.get("bullets") or c.get("visual")): err(cw, "needs body, code, bullets or visual")
            if c.get("body") and len(c["body"]) > 360: err(cw, f"body is {len(c['body'])} chars; max 360")
            if c.get("code"):
                code += 1
                lines = c["code"].split("\n")
                if len(lines) > 14 or max(map(len, lines)) > 36: err(cw, "code: max 14 lines of 36 chars")
            if "visual" in c:
                visual += 1
                check_visual(cw, c["visual"])
    return len(notes), cards, visual, code

for path in sys.argv[1:] or ["app/Data/lessons.json"]:
    n, cards, visual, code = check_file(path)
    either = f"{visual}/{cards} cards have a visual ({100 * visual // max(cards, 1)}%), {code} have code"
    print(f"{path}: {n} notes, {either}")
print(f"{len(errors)} errors")
for e in errors: print(" -", e)
sys.exit(1 if errors else 0)
