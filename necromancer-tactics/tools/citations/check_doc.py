#!/usr/bin/env python3
"""Check the quotations in a Markdown document against the pages it cites.

Usage:  python3 check_doc.py FILE.md [FILE.md ...]

For every block of text (paragraph, list item or table row) this finds the quoted strings
("like this", 12 characters or more) and the links in the same block, and checks that each
quote appears on at least one of those pages. A block with quotes but no link falls back to
the links on the nearest "Source" line above it in the same section. Quotes with no link to
check against are listed separately; they are not failures (they may be a person's words).

Exit code 0 if every checkable quote was found, 1 otherwise.
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fetch import fetch            # noqa: E402
from check_quote import norm       # noqa: E402

# A link in angle brackets may contain parentheses (Apple symbol pages do); a bare link stops at one.
URL = re.compile(r"<(https?://[^>\s]+)>|(https?://[^\s<>)\]]+)")
QUOTE = re.compile(r'"([^"\n]{12,}?)"|“([^”\n]{12,}?)”')
_pages = {}


def page(url):
    url = url.rstrip(".,;")
    if url not in _pages:
        status, _, path = fetch(url)
        _pages[url] = norm(open(path, encoding="utf-8", errors="replace").read()) if status == "200" and path else None
    return _pages[url]


def found(quote, url):
    text = page(url)
    if text is None:
        return None
    pos = 0
    for frag in re.split(r"\.\.\.|…", quote):
        frag = norm(frag).strip(" .")
        if len(frag) < 3:
            continue
        i = text.find(frag, pos)
        if i < 0:
            return False
        pos = i + len(frag)
    return True


def blocks(lines):
    """Yields (first line number, text). List items and table rows are their own blocks."""
    start, buf = None, []
    for n, line in enumerate(lines, 1):
        new_item = re.match(r"\s*([-*]|\d+\.)\s+", line) or line.startswith("|") or line.startswith("#")
        if not line.strip() or new_item:
            if buf:
                yield start, " ".join(buf)
            start, buf = (n, [line.strip()]) if line.strip() else (None, [])
        else:
            if not buf:
                start = n
            buf.append(line.strip())
    if buf:
        yield start, " ".join(buf)


def check(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    section_sources, failures, unsourced, checked, unreachable = [], [], [], 0, []
    in_code = False
    cleaned = []
    for line in lines:
        if line.strip().startswith("```"):
            in_code = not in_code
            cleaned.append("")
        else:
            cleaned.append("" if in_code else line)
    for n, text in blocks(cleaned):
        if text.startswith("#"):
            section_sources = []
            continue
        urls = [(a or b).rstrip(".,;") for a, b in URL.findall(text)]
        if re.match(r"(\*\*)?(Main )?[Ss]ources?\b", text.lstrip("-* ")) and urls:
            section_sources = urls
        quotes = [a or b for a, b in QUOTE.findall(re.sub(r"`[^`]*`", lambda m: m.group(0).replace('"', "'"), text))]
        for q in quotes:
            candidates = urls + [s for s in section_sources if s not in urls]
            if not candidates:
                unsourced.append((n, q))
                continue
            results = [found(q, u) for u in candidates]
            checked += 1
            if any(r is True for r in results):
                continue
            if all(r is None for r in results):
                unreachable.append((n, q, candidates[0]))
            else:
                failures.append((n, q, candidates))
    print(f"{path}: {checked} quotes checked, {len(failures)} not found, {len(unreachable)} on unreachable pages, {len(unsourced)} with no link")
    for n, q, c in failures:
        print(f"  NOT FOUND line {n}: {q[:110]!r}\n      looked on: {', '.join(c)[:300]}")
    for n, q, u in unreachable:
        print(f"  unreachable line {n}: {u}")
    return not failures


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    ok = all([check(p) for p in sys.argv[1:]])
    sys.exit(0 if ok else 1)
