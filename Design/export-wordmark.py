#!/usr/bin/env python3
"""
Export the Sugarfree wordmark as SVG (with embedded DynaPuff font) and PNG.

Outputs:
  Design/wordmark.svg       — self-contained SVG for browsers / static sites
  Design/wordmark@1x.png    — ~96px tall transparent PNG
  Design/wordmark@2x.png    — ~192px tall transparent PNG (recommended for README)

Usage:
  python3 Design/export-wordmark.py

Requires: Pillow  (pip install Pillow)
SVG only: no extra deps needed.
"""

import base64
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT  = os.path.dirname(SCRIPT_DIR)

FONT_PATH  = os.path.join(REPO_ROOT, "Sugarfree", "Fonts", "DynaPuff.ttf")
SVG_OUT    = os.path.join(SCRIPT_DIR, "wordmark.svg")
PNG_1X     = os.path.join(SCRIPT_DIR, "wordmark@1x.png")
PNG_2X     = os.path.join(SCRIPT_DIR, "wordmark@2x.png")

TEXT = "sugarfree"

# Cotton gradient stops — mirrors Theme.swift Cotton.gradient
GRAD_STOPS = [
    (0.00, (255, 111, 181)),   # #FF6FB5  pink
    (0.52, (255, 154, 107)),   # #FF9A6B  peach
    (1.00, (255, 200,  87)),   # #FFC857  gold
]

# SVG typographic params
SVG_FONT_SIZE   = 72
SVG_FONT_WEIGHT = 900
SVG_VB_W, SVG_VB_H = 392, 96
SVG_TEXT_X, SVG_TEXT_Y = 2, 76


# ── gradient helpers ────────────────────────────────────────────────────────

def lerp(a, b, t):
    return a + (b - a) * t

def sample_gradient(stops, t):
    """Interpolate colour at position t ∈ [0,1] through multi-stop gradient."""
    t = max(0.0, min(1.0, t))
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if t0 <= t <= t1:
            f = (t - t0) / (t1 - t0)
            return tuple(int(lerp(a, b, f)) for a, b in zip(c0, c1))
    return stops[-1][1]


# ── PNG export via Pillow ───────────────────────────────────────────────────

def render_png(out_path: str, font_size: int) -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Pillow not found — run: pip install Pillow", file=sys.stderr)
        sys.exit(1)

    font = ImageFont.truetype(FONT_PATH, font_size)

    # Measure text on a throw-away surface
    dummy = Image.new("RGBA", (1, 1))
    bb = ImageDraw.Draw(dummy).textbbox((0, 0), TEXT, font=font, spacing=0)
    # bb = (left, top, right, bottom) — add a little padding
    pad = max(4, font_size // 16)
    w = bb[2] - bb[0] + pad * 2
    h = bb[3] - bb[1] + pad * 2

    # Build a left-to-right gradient strip at full width
    gradient = Image.new("RGBA", (w, h))
    for x in range(w):
        t = x / (w - 1)
        r, g, b = sample_gradient(GRAD_STOPS, t)
        for y in range(h):
            gradient.putpixel((x, y), (r, g, b, 255))

    # Render text as a greyscale mask (white on black)
    mask_img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask_img).text(
        (-bb[0] + pad, -bb[1] + pad), TEXT, font=font, fill=255
    )

    # Apply mask: gradient where text is, transparent elsewhere
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    result.paste(gradient, mask=mask_img)
    result.save(out_path, "PNG")
    print(f"  → {out_path}  ({w}×{h}px)")


# ── SVG export ──────────────────────────────────────────────────────────────

def build_svg(font_b64: str) -> str:
    stops_xml = "\n      ".join(
        f'<stop offset="{int(pct*100)}%" stop-color="#{r:02X}{g:02X}{b:02X}"/>'
        for pct, (r, g, b) in GRAD_STOPS
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 {SVG_VB_W} {SVG_VB_H}" width="{SVG_VB_W}" height="{SVG_VB_H}">
  <defs>
    <style>
      @font-face {{
        font-family: 'DynaPuff';
        src: url('data:font/truetype;base64,{font_b64}') format('truetype');
        font-weight: {SVG_FONT_WEIGHT};
      }}
    </style>
    <!-- Cotton gradient: mirrors Theme.swift Cotton.gradient -->
    <linearGradient id="cotton" x1="0%" y1="0%" x2="100%" y2="15%">
      {stops_xml}
    </linearGradient>
  </defs>
  <text
    x="{SVG_TEXT_X}" y="{SVG_TEXT_Y}"
    font-family="'DynaPuff', system-ui, sans-serif"
    font-size="{SVG_FONT_SIZE}"
    font-weight="{SVG_FONT_WEIGHT}"
    letter-spacing="-0.7"
    fill="url(#cotton)">{TEXT}</text>
</svg>
"""


# ── main ────────────────────────────────────────────────────────────────────

def main() -> None:
    if not os.path.exists(FONT_PATH):
        print(f"Font not found: {FONT_PATH}", file=sys.stderr)
        sys.exit(1)

    print("Writing SVG (font embedded as base64)…")
    with open(FONT_PATH, "rb") as f:
        font_b64 = base64.b64encode(f.read()).decode("ascii")
    with open(SVG_OUT, "w", encoding="utf-8") as f:
        f.write(build_svg(font_b64))
    print(f"  → {SVG_OUT}")

    print("Rendering PNGs with Pillow…")
    render_png(PNG_1X, font_size=60)
    render_png(PNG_2X, font_size=120)

    print("Done.")


if __name__ == "__main__":
    main()
