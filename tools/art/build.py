"""Generates every sprite sheet and environment image, and the SpriteSheet resources
that describe them. Run from the project root:

    python3 tools/art/build.py [--preview DIR]

Writes assets/sprites/*.png, assets/env/*.png and content/art/*.tres. The PNGs are
ordinary assets: an artist can replace any of them as long as the frame size and
frame count stay the same (or the .tres is updated to match)."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
from pixel import strip

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODULES = ["notes", "rests", "elites", "bosses", "npcs", "props"]
PIXEL_SCALE = 3


def tres(name, png_rel, frame_size, origin, animations, scale):
    anims = ", ".join('"%s": [%s]' % (k, ", ".join(str(i) for i in v[0])) for k, v in animations.items())
    fps = ", ".join('"%s": %s' % (k, float(v[1])) for k, v in animations.items())
    return (
        '[gd_resource type="Resource" script_class="SpriteSheet" load_steps=3 format=3]\n\n'
        '[ext_resource type="Script" path="res://src/art/sprite_sheet.gd" id="1"]\n'
        '[ext_resource type="Texture2D" path="res://%s" id="2"]\n\n'
        "[resource]\n"
        'script = ExtResource("1")\n'
        'texture = ExtResource("2")\n'
        "frame_size = Vector2i(%d, %d)\n"
        "origin = Vector2i(%d, %d)\n"
        "pixel_scale = %d\n"
        "animations = {%s}\n"
        "fps = {%s}\n" % (png_rel, frame_size[0], frame_size[1], origin[0], origin[1], scale, anims, fps))


def main():
    preview_dir = None
    if "--preview" in sys.argv:
        preview_dir = sys.argv[sys.argv.index("--preview") + 1]
        os.makedirs(preview_dir, exist_ok=True)
    only = [m for m in MODULES if m in sys.argv] or MODULES
    count = 0
    for mod_name in only:
        try:
            mod = __import__(mod_name)
        except ModuleNotFoundError:
            continue
        for name, spec in mod.sheets().items():
            frames, animations, origin, size = spec[:4]
            scale = spec[4] if len(spec) > 4 else PIXEL_SCALE
            png_rel = "assets/sprites/%s.png" % name
            img = strip(frames)
            img.save(os.path.join(ROOT, png_rel))
            with open(os.path.join(ROOT, "content", "art", name + ".tres"), "w") as f:
                f.write(tres(name, png_rel, size, origin, animations, scale))
            if preview_dir:
                big = img.resize((img.width * 4, img.height * 4), Image.NEAREST)
                bg = Image.new("RGBA", big.size, (243, 236, 217, 255))
                bg.alpha_composite(big)
                bg.save(os.path.join(preview_dir, name + ".png"))
            count += 1
    try:
        import env
        count += env.build(ROOT, preview_dir)
    except ModuleNotFoundError:
        pass
    print("wrote %d sheets" % count)


if __name__ == "__main__":
    main()
