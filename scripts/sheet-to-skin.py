#!/usr/bin/env python3
"""Turns sprite sheets of a character into a Deskling Pet skin.

The character folder holds original.png (the reference drawing) and one sheet
per pose, named after the pose (idle.png, walk.png, ...). Each sheet is one row
of frames on a white or transparent background, as image generators make them.

For every sheet this script removes the background, cuts the row into frames at
the emptiest columns, and scales the frames so the hair is as wide as in the
reference drawing, which keeps the character the same size in every pose.
Frames keep their height above the sheet's lowest point, so jumps stay jumps,
and are centered on the hair, so the head does not wobble sideways.
All poses share one canvas, which keeps the pet window the same size.

Usage: scripts/sheet-to-skin.py <character-dir> <skin-dir> <display-name>
Requires Pillow, numpy and scipy.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# Pose: (frames in the sheet, seconds per frame).
POSES = {
    "idle": (6, 0.25),
    "walk": (8, 0.11),
    "happy": (6, 0.12),
    "working": (4, 0.2),
    "waiting": (6, 0.15),
    "drag": (4, 0.15),
    "fall": (4, 0.2),
}

# Height of the standing character on the canvas, in pixels. The canvas is
# drawn at twice the skin height so it stays sharp on high-DPI screens.
STANDING_HEIGHT = 220


def rgba(path):
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.int32)


def remove_background(pixels):
    """Clears the white background that touches the border. Whites inside the outline stay."""
    rgb = pixels[..., :3]
    light = (rgb.min(axis=2) >= 228) & (rgb.max(axis=2) - rgb.min(axis=2) < 24)
    light |= pixels[..., 3] < 16
    labels, _ = ndimage.label(light)
    border = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    background = np.isin(labels, border[border > 0])
    alpha = np.where(background, 0, pixels[..., 3])
    # Soften the light anti-aliasing ring just inside the outline.
    ring = ndimage.binary_dilation(background, iterations=2) & ~background
    darkness = 255 - rgb.min(axis=2)
    alpha = np.where(ring, np.minimum(alpha, np.clip(darkness * 3, 0, 255)), alpha)
    # Drop specks left over from the generator's noise.
    solid = alpha > 0
    labels, count = ndimage.label(solid)
    if count:
        sizes = ndimage.sum(solid, labels, range(1, count + 1))
        alpha = np.where(np.isin(labels, np.flatnonzero(sizes < 40) + 1), 0, alpha)
    out = pixels.copy()
    out[..., 3] = alpha
    return out


def split(pixels, count):
    """Cuts a row of frames at the emptiest columns near the evenly spaced cut lines."""
    filled = (pixels[..., 3] > 0).sum(axis=0)
    width = pixels.shape[1]
    cell = width / count
    cuts = [0]
    for index in range(1, count):
        lower, upper = int(cell * (index - 0.35)), int(cell * (index + 0.35))
        window = filled[lower:upper]
        lowest = window.min()
        candidates = np.flatnonzero(window == lowest) + lower
        expected = cell * index
        cuts.append(int(candidates[np.argmin(np.abs(candidates - expected))]))
    cuts.append(width)
    return [pixels[:, a:b] for a, b in zip(cuts, cuts[1:])]


def hair(pixels):
    """The bounding box (left, top, right, bottom) of the biggest patch of brown hair."""
    r, g, b, a = (pixels[..., i] for i in range(4))
    brown = (a > 128) & (r >= 60) & (r <= 200) & (g >= 25) & (g <= 125) & (b <= 90) & (r - g >= 35) & (g - b >= 8)
    labels, count = ndimage.label(brown)
    if not count:
        raise SystemExit("no hair found in a frame")
    sizes = ndimage.sum(brown, labels, range(1, count + 1))
    ys, xs = np.nonzero(labels == np.argmax(sizes) + 1)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: sheet-to-skin.py <character-dir> <skin-dir> <display-name>")
    source, target = Path(sys.argv[1]), Path(sys.argv[2])

    reference = remove_background(rgba(source / "original.png"))
    ys, _ = np.nonzero(reference[..., 3])
    left, _, right, _ = hair(reference)
    hair_width = (right - left) * STANDING_HEIGHT / (ys.max() + 1 - ys.min())

    # Every frame as (image, x of the hair center, y of the pose's ground), already scaled.
    poses = {}
    for name, (count, delay) in POSES.items():
        sheet = source / f"{name}.png"
        if not sheet.exists():
            continue
        frames = split(remove_background(rgba(sheet)), count)
        boxes = [hair(frame) for frame in frames]
        scale = hair_width / np.median([box[2] - box[0] for box in boxes])
        ground = max(np.nonzero(frame[..., 3])[0].max() + 1 for frame in frames)
        scaled = []
        for frame, box in zip(frames, boxes):
            image = Image.fromarray(frame.astype(np.uint8), "RGBA")
            size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
            scaled.append((image.resize(size, Image.LANCZOS), (box[0] + box[2]) / 2 * scale, ground * scale))
        poses[name] = (scaled, delay)

    # One canvas for every pose, symmetric around the hair so a flipped pet stays in place.
    half_width = height = 0
    for frames, _ in poses.values():
        for image, center, ground in frames:
            alpha = np.asarray(image)[..., 3]
            ys, xs = np.nonzero(alpha)
            half_width = max(half_width, center - xs.min(), xs.max() + 1 - center)
            height = max(height, ground - ys.min())
    canvas_width = int(np.ceil(half_width)) * 2 + 4
    canvas_height = int(np.ceil(height)) + 4

    target.mkdir(parents=True, exist_ok=True)
    for name, (frames, delay) in poses.items():
        canvases = []
        for image, center, ground in frames:
            canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
            canvas.alpha_composite(image, (round(canvas_width / 2 - center), round(canvas_height - 2 - ground)))
            canvases.append(canvas)
        canvases[0].save(target / f"{name}.png", save_all=True, append_images=canvases[1:],
                         duration=round(delay * 1000), loop=0, disposal=1, blend=0, optimize=True)
    skin = {"name": sys.argv[3], "height": round(canvas_height / 2)}
    (target / "skin.json").write_text(json.dumps(skin, ensure_ascii=False, indent=2) + "\n")
    print(f"{target}: {canvas_width}x{canvas_height} px, poses: {', '.join(poses)}")


if __name__ == "__main__":
    main()
