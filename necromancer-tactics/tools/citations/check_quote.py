#!/usr/bin/env python3
"""Check whether a quotation really appears on a web page.

Usage:  python3 -I check_quote.py URL 'the quoted text'
        python3 -I check_quote.py URL -        (reads the quote from standard input)

Comparison ignores case, line breaks, curly-vs-straight quotes, hyphen and dash variants,
non-breaking spaces, markdown backticks and link syntax. A quote containing "..." or the
ellipsis character is treated as several fragments that must all appear, in order.
Prints FOUND, or NOT_FOUND with the closest text on the page for each missing fragment.
Exit code: 0 found, 1 not found, 2 page could not be fetched.
"""
import difflib, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fetch import fetch  # noqa: E402

SUBS = {
    "‘": "'", "’": "'", "‚": "'", "′": "'",
    "“": '"', "”": '"', "„": '"', "″": '"',
    "‐": "-", "‑": "-", "‒": "-", "–": "-", "—": "-", "−": "-",
    " ": " ", " ": " ", " ": " ", " ": " ", " ": " ", " ": " ",
    "​": "", "﻿": "", "­": "",
}


def norm(s):
    # [title](link) -> title. Apple symbol links contain one level of parentheses.
    s = re.sub(r"\[([^\]]*)\]\((?:[^()]|\([^()]*\))*\)", r"\1", s)
    s = "".join(SUBS.get(c, c) for c in s)
    s = s.replace("`", "").replace("*", "")
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s+([.,;:!?)])", r"\1", s)
    return s.strip().lower()


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    url = sys.argv[1]
    quote = sys.stdin.read() if sys.argv[2] == "-" else " ".join(sys.argv[2:])
    status, final, path = fetch(url)
    if status != "200" or not path:
        print("PAGE_UNAVAILABLE status=%s final_url=%s" % (status, final))
        return 2
    page = norm(open(path, encoding="utf-8", errors="replace").read())
    fragments = [norm(f) for f in re.split(r"\.\.\.|…", quote)]
    fragments = [f.strip(" .") for f in fragments if len(f.strip(" .")) >= 3]
    pos, missing = 0, []
    for f in fragments:
        i = page.find(f, pos)
        if i < 0:
            i_any = page.find(f)
            missing.append((f, i_any))
        else:
            pos = i + len(f)
    if not missing:
        print("FOUND (%d fragment%s) status=200 final_url=%s" % (len(fragments), "" if len(fragments) == 1 else "s", final))
        return 0
    print("NOT_FOUND status=200 final_url=%s" % final)
    for f, i_any in missing:
        if i_any >= 0:
            print("  fragment appears, but out of order: %r" % f[:120])
            continue
        m = difflib.SequenceMatcher(None, f, page, autojunk=False).find_longest_match(0, len(f), 0, len(page))
        lo, hi = max(0, m.b - m.a - 20), min(len(page), m.b - m.a + len(f) + 20)
        print("  missing fragment: %r" % f[:300])
        print("  longest shared run: %d of %d characters" % (m.size, len(f)))
        print("  closest page text: %r" % page[lo:hi])
    return 1


if __name__ == "__main__":
    sys.exit(main())
