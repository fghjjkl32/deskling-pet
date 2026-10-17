#!/usr/bin/env python3
"""Animates one still character drawing into a full Deskling Pet skin.

Every pose is the same drawing moved, tilted or squashed on a shared canvas,
so the character keeps its look and the window keeps its size between poses.

Usage: scripts/make-skin.py <drawing.png> <skin-dir> <display-name>
Requires Pillow (pip install pillow).
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image

# Character height on the canvas, in pixels. The canvas is drawn at twice the
# skin height so it stays sharp on Retina and high-DPI screens.
CHARACTER_HEIGHT = 224
CANVAS_WIDTH = 180
CANVAS_HEIGHT = 260
SKIN_HEIGHT = CANVAS_HEIGHT // 2


def load_character(path):
    image = Image.open(path).convert("RGBA")
    image = image.crop(image.getchannel("A").getbbox())
    width = round(image.width * CHARACTER_HEIGHT / image.height)
    return image.resize((width, CHARACTER_HEIGHT), Image.LANCZOS)


def frame(character, dx=0.0, dy=0.0, angle=0.0, pivot="feet", squash=1.0):
    """Draws the character with its feet on the canvas floor.

    dy moves it up, angle tilts it in degrees (counterclockwise), and squash
    scales its height around the feet while keeping the area roughly the same.
    """
    image = character
    if squash != 1.0:
        width = round(image.width / math.sqrt(squash))
        height = round(image.height * squash)
        image = image.resize((width, height), Image.LANCZOS)
    # Rotate around the feet or the head by padding the image so that point is the center.
    pad = Image.new("RGBA", (image.width, image.height * 2), (0, 0, 0, 0))
    pad.paste(image, (0, 0 if pivot == "feet" else image.height))
    rotated = pad.rotate(angle, resample=Image.BICUBIC, expand=True)
    canvas = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    center_x = CANVAS_WIDTH / 2 + dx
    if pivot == "feet":
        center_y = CANVAS_HEIGHT - 2 - dy
    else:
        center_y = CANVAS_HEIGHT - 2 - image.height - dy
    canvas.alpha_composite(rotated, (round(center_x - rotated.width / 2), round(center_y - rotated.height / 2)))
    return canvas


def idle(character):
    # A slow breath.
    return [frame(character, squash=1 - 0.012 * (1 - math.cos(2 * math.pi * i / 16)) / 2) for i in range(16)], 0.12


def walk(character):
    # Bobbing steps, leaning into each one.
    frames = []
    for i in range(8):
        phase = 2 * math.pi * i / 8
        frames.append(frame(character, dy=abs(math.sin(phase)) * 6, angle=math.sin(phase) * 4))
    return frames, 0.08


def happy(character):
    # Two hops with a squash on each landing.
    frames = []
    for hop in range(2):
        for i in range(8):
            t = i / 8
            height = math.sin(math.pi * t) * 28
            squash = 0.94 if i == 0 else 1.0
            frames.append(frame(character, dy=height, squash=squash, angle=(4 if hop else -4) * math.sin(math.pi * t)))
    return frames, 0.06


def working(character):
    # Busy little nods.
    offsets = [0, 2, 0, 2, 0, 1]
    return [frame(character, dy=-dy, angle=dy * 0.8) for dy in offsets], 0.1


def waiting(character):
    # Rocking side to side to get attention.
    return [frame(character, angle=math.sin(2 * math.pi * i / 12) * 6) for i in range(12)], 0.08


def drag(character):
    # Dangling from the cursor, swinging from the head.
    return [frame(character, dy=16, angle=math.sin(2 * math.pi * i / 10) * 10, pivot="head") for i in range(10)], 0.07


POSES = {"idle": idle, "walk": walk, "happy": happy, "working": working, "waiting": waiting, "drag": drag}


def save_apng(frames, delay, path):
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=round(delay * 1000),
                   loop=0, disposal=1, blend=0, optimize=True)


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: make-skin.py <drawing.png> <skin-dir> <display-name>")
    character = load_character(sys.argv[1])
    directory = Path(sys.argv[2])
    directory.mkdir(parents=True, exist_ok=True)
    for name, pose in POSES.items():
        frames, delay = pose(character)
        save_apng(frames, delay, directory / f"{name}.png")
    (directory / "skin.json").write_text(json.dumps({"name": sys.argv[3], "height": SKIN_HEIGHT}, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
