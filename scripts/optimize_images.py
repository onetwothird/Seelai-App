#!/usr/bin/env python3
"""
Batch convert PNG/JPG images under assets/ to WebP to reduce size.
Requires Pillow: `pip install -r scripts/requirements.txt`.
Run from repo root: `python scripts/optimize_images.py --dry-run` to preview changes.
Use `--apply` to actually write WebP files and move originals to `assets/_backup_images/`.
"""
import argparse
import os
from pathlib import Path
from PIL import Image

ROOT = Path.cwd()
ASSETS = ROOT / 'assets'
BACKUP = ASSETS / '_backup_images'

def find_images():
    exts = ('.png', '.jpg', '.jpeg')
    for p in ASSETS.rglob('*'):
        if p.suffix.lower() in exts and 'icon' not in p.parts and '_backup_images' not in p.parts:
            yield p

def convert(p: Path, apply: bool):
    rel = p.relative_to(ROOT)
    target = p.with_suffix('.webp')
    print(f"-> {rel} -> {target.relative_to(ROOT)}")
    if not apply:
        return
    BACKUP.mkdir(parents=True, exist_ok=True)
    target_tmp = target.with_suffix('.tmp')
    try:
        img = Image.open(p).convert('RGBA')
        img.save(target_tmp, 'webp', quality=80, method=6)
        target_tmp.replace(target)
        # move original to backup
        dest = BACKUP / p.name
        p.replace(dest)
    except Exception as e:
        print(f"Failed to convert {p}: {e}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    imgs = list(find_images())
    print(f"Found {len(imgs)} image(s) to optimize.")
    for p in imgs:
        convert(p, args.apply)
    if args.apply:
        print('Conversion complete. Originals moved to assets/_backup_images/')

if __name__ == '__main__':
    main()
