#!/usr/bin/env python3
"""Resize the screenshots in docs/ in place to the App Store size.

App Store Connect accepts 1284x2778 (6.5 inch) portrait screenshots. The
simulator shots are wider than that aspect, so each image is scaled to the
full target width and the missing height is padded on TOP with the image's
own top-row color (a flat background in every shot). Padding the bottom
would lift the home indicator off the screen edge, and cropping would clip
the card padding on both sides.

Raw simulator screenshots arrive at the device's native size with the
status bar (and, in debug builds, the DEBUG banner) still attached; the
top status-bar strip is cropped off first so every shot shares the same
framing.

Already-converted images are skipped, so the script is safe to re-run.
"""

import sys
from pathlib import Path

from PIL import Image

TARGET_W, TARGET_H = 1284, 2778
NATIVE_W, NATIVE_H = 1179, 2556
STATUS_BAR_H = 188
DOCS = Path(__file__).resolve().parent.parent / "docs"


def convert(path: Path) -> bool:
    img = Image.open(path).convert("RGB")
    if img.size == (TARGET_W, TARGET_H):
        return False
    if img.size == (NATIVE_W, NATIVE_H):
        img = img.crop((0, STATUS_BAR_H, NATIVE_W, NATIVE_H))
    scaled_h = round(img.height * TARGET_W / img.width)
    if scaled_h > TARGET_H:
        sys.exit(f"{path.name}: {img.width}x{img.height} is too tall to pad "
                 f"to {TARGET_W}x{TARGET_H}; re-take the screenshot")
    scaled = img.resize((TARGET_W, scaled_h), Image.LANCZOS)
    canvas = Image.new("RGB", (TARGET_W, TARGET_H), scaled.getpixel((0, 0)))
    canvas.paste(scaled, (0, TARGET_H - scaled_h))
    canvas.save(path)
    return True


def main() -> None:
    pngs = sorted(DOCS.glob("*.png"))
    if not pngs:
        sys.exit(f"no .png files found in {DOCS}")
    for path in pngs:
        status = "converted" if convert(path) else "already ok"
        print(f"{status}  {path.name}")


if __name__ == "__main__":
    main()
