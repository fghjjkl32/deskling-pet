#!/usr/bin/env python3
"""Turns sprite sheets of a character into a Deskling Pet skin.

The character folder holds one sheet per pose, named after the pose (idle.png,
walk.png, ...); idle.png is required. Each sheet is one row of frames on a white
or transparent background, as image generators make them.

For every sheet this script removes the background, cuts the row into frames at
the emptiest columns, and drops slivers of a neighboring frame. Image generators
draw each sheet at its own scale, so poses where the character stands upright are
scaled to STANDING_HEIGHT, and the others are scaled so the crown of the head is
as wide as in the idle pose.
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

# Pose: (frames in the sheet, seconds per frame, how its size is matched).
# "height" scales the full figure to STANDING_HEIGHT; "crown" matches the idle pose's head.
POSES = {
    "idle": (6, 0.25, "height"),
    "walk": (8, 0.11, "height"),
    "happy": (6, 0.12, "crown"),
    "working": (4, 0.2, "crown"),
    "waiting": (6, 0.15, "height"),
    "drag": (4, 0.15, "crown"),
    "fall": (4, 0.2, "height"),
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
    return [without_slivers(pixels[:, a:b]) for a, b in zip(cuts, cuts[1:])]


def without_slivers(frame):
    """Clears pieces that touch the left or right edge, other than the figure itself.

    Those are parts of a neighboring frame that reached across the cut."""
    solid = frame[..., 3] > 0
    labels, count = ndimage.label(solid, structure=np.ones((3, 3)))
    if count < 2:
        return frame
    figure = np.argmax(ndimage.sum(solid, labels, range(1, count + 1))) + 1
    edges = set(np.unique(np.concatenate([labels[:, 0], labels[:, -1]]))) - {0, figure}
    out = frame.copy()
    out[..., 3] = np.where(np.isin(labels, list(edges)), 0, out[..., 3])
    return out


def hair(pixels):
    """The crown of the head: left, top, right and bottom of the top 30% of the biggest patch of brown hair.

    Only the crown is measured because long hair flies out sideways when the character jumps or dangles,
    while the crown keeps the width of the head."""
    r, g, b, a = (pixels[..., i] for i in range(4))
    brown = (a > 128) & (r >= 60) & (r <= 200) & (g >= 25) & (g <= 125) & (b <= 90) & (r - g >= 35) & (g - b >= 8)
    labels, count = ndimage.label(brown)
    if not count:
        raise SystemExit("no hair found in a frame")
    sizes = ndimage.sum(brown, labels, range(1, count + 1))
    ys, xs = np.nonzero(labels == np.argmax(sizes) + 1)
    crown = ys < ys.min() + (ys.max() + 1 - ys.min()) * 0.3
    return xs[crown].min(), ys.min(), xs[crown].max() + 1, ys[crown].max() + 1


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: sheet-to-skin.py <character-dir> <skin-dir> <display-name>")
    source, target = Path(sys.argv[1]), Path(sys.argv[2])

    sheets = {}
    for name, (count, delay, match) in POSES.items():
        sheet = source / f"{name}.png"
        if sheet.exists():
            frames = split(remove_background(rgba(sheet)), count)
            sheets[name] = (frames, [hair(frame) for frame in frames], delay, match)
    if "idle" not in sheets:
        sys.exit("idle.png is required")

    def median_height(frames):
        return np.median([np.ptp(np.nonzero(frame[..., 3])[0]) + 1 for frame in frames])

    def median_crown(boxes):
        return np.median([box[2] - box[0] for box in boxes])

    idle_frames, idle_boxes, _, _ = sheets["idle"]
    crown_width = median_crown(idle_boxes) * STANDING_HEIGHT / median_height(idle_frames)

    # Every frame as (image, x of the crown's center, y of the pose's ground), already scaled.
    poses = {}
    for name, (frames, boxes, delay, match) in sheets.items():
        if match == "height":
            scale = STANDING_HEIGHT / median_height(frames)
        else:
            scale = crown_width / median_crown(boxes)
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
