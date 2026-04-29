#!/usr/bin/env python3
import math
import os
import struct
import sys
import zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SOURCE = os.path.join(ROOT, "assets", "app_icon", "howlong_icon_1024.png")

DARK = (0, 54, 41, 255)
MINT = (214, 245, 231, 255)
MINT_BRIGHT = (0, 212, 170, 255)
WHITE = (246, 255, 251, 255)
SHADOW = (0, 29, 22, 90)


def write_png(path, width, height, pixels):
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride : (y + 1) * stride])

    def chunk(kind, data):
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    data = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as f:
        f.write(data)


def read_png_rgba(path):
    with open(path, "rb") as f:
        data = f.read()

    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"{path} is not a PNG file")

    offset = 8
    width = height = None
    bit_depth = color_type = None
    compressed = bytearray()

    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + length]
        offset += 12 + length

        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, png_filter, interlace = (
                struct.unpack(">IIBBBBB", payload)
            )
            if compression != 0 or png_filter != 0 or interlace != 0:
                raise ValueError("Only non-interlaced standard PNG files are supported")
            if bit_depth != 8 or color_type != 6:
                raise ValueError("Only 8-bit RGBA PNG files are supported")
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            break

    if width is None or height is None:
        raise ValueError("PNG is missing an IHDR chunk")

    raw = zlib.decompress(bytes(compressed))
    stride = width * 4
    pixels = bytearray(width * height * 4)
    previous = bytearray(stride)
    src = 0

    for y in range(height):
        filter_type = raw[src]
        src += 1
        row = bytearray(raw[src : src + stride])
        src += stride

        for i in range(stride):
            left = row[i - 4] if i >= 4 else 0
            up = previous[i]
            up_left = previous[i - 4] if i >= 4 else 0

            if filter_type == 1:
                row[i] = (row[i] + left) & 0xFF
            elif filter_type == 2:
                row[i] = (row[i] + up) & 0xFF
            elif filter_type == 3:
                row[i] = (row[i] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                row[i] = (row[i] + paeth(left, up, up_left)) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"Unsupported PNG filter type {filter_type}")

        start = y * stride
        pixels[start : start + stride] = row
        previous = row

    return width, height, pixels


def paeth(left, up, up_left):
    p = left + up - up_left
    pa = abs(p - left)
    pb = abs(p - up)
    pc = abs(p - up_left)
    if pa <= pb and pa <= pc:
        return left
    if pb <= pc:
        return up
    return up_left


def resize_rgba_to_square(source, src_w, src_h, size):
    crop = min(src_w, src_h)
    crop_x = (src_w - crop) // 2
    crop_y = (src_h - crop) // 2
    dst = bytearray(size * size * 4)

    for y in range(size):
        for x in range(size):
            sx0 = crop_x + int(x * crop / size)
            sx1 = crop_x + max(sx0 - crop_x + 1, int((x + 1) * crop / size))
            sy0 = crop_y + int(y * crop / size)
            sy1 = crop_y + max(sy0 - crop_y + 1, int((y + 1) * crop / size))
            total = [0, 0, 0, 0]
            count = 0
            for sy in range(sy0, min(crop_y + crop, sy1)):
                for sx in range(sx0, min(crop_x + crop, sx1)):
                    i = (sy * src_w + sx) * 4
                    for c in range(4):
                        total[c] += source[i + c]
                    count += 1
            o = (y * size + x) * 4
            dst[o : o + 4] = bytes(int(v / count) for v in total)

    return dst


def blend(dst, src):
    sa = src[3] / 255
    da = dst[3] / 255
    out_a = sa + da * (1 - sa)
    if out_a == 0:
        return (0, 0, 0, 0)
    return tuple(
        int((src[i] * sa + dst[i] * da * (1 - sa)) / out_a) for i in range(3)
    ) + (int(out_a * 255),)


def put(px, w, x, y, color):
    if x < 0 or y < 0 or x >= w or y >= w:
        return
    i = (y * w + x) * 4
    current = tuple(px[i : i + 4])
    px[i : i + 4] = bytes(blend(current, color))


def fill_circle(px, w, cx, cy, r, color):
    x0 = max(0, int(cx - r))
    x1 = min(w - 1, int(cx + r))
    y0 = max(0, int(cy - r))
    y1 = min(w - 1, int(cy + r))
    rr = r * r
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= rr:
                put(px, w, x, y, color)


def draw_round_line(px, w, x1, y1, x2, y2, width, color):
    steps = max(1, int(math.hypot(x2 - x1, y2 - y1) / max(1, width / 3)))
    for i in range(steps + 1):
        t = i / steps
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t
        fill_circle(px, w, x, y, width / 2, color)


def draw_arc(px, w, cx, cy, r, start_deg, end_deg, width, color):
    steps = int(abs(end_deg - start_deg) * 2)
    last = None
    for i in range(steps + 1):
        deg = start_deg + (end_deg - start_deg) * i / steps
        rad = math.radians(deg)
        point = (cx + math.cos(rad) * r, cy + math.sin(rad) * r)
        if last is not None:
            draw_round_line(px, w, last[0], last[1], point[0], point[1], width, color)
        last = point


def fill_polygon(px, w, points, color):
    min_x = max(0, int(min(x for x, _ in points)))
    max_x = min(w - 1, int(max(x for x, _ in points)))
    min_y = max(0, int(min(y for _, y in points)))
    max_y = min(w - 1, int(max(y for _, y in points)))
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            inside = False
            j = len(points) - 1
            for i in range(len(points)):
                xi, yi = points[i]
                xj, yj = points[j]
                if ((yi > y) != (yj > y)) and (
                    x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi
                ):
                    inside = not inside
                j = i
            if inside:
                put(px, w, x, y, color)


def downsample(src, src_w, scale):
    dst_w = src_w // scale
    dst = bytearray(dst_w * dst_w * 4)
    for y in range(dst_w):
        for x in range(dst_w):
            total = [0, 0, 0, 0]
            for yy in range(scale):
                for xx in range(scale):
                    i = (((y * scale + yy) * src_w) + (x * scale + xx)) * 4
                    for c in range(4):
                        total[c] += src[i + c]
            o = (y * dst_w + x) * 4
            samples = scale * scale
            dst[o : o + 4] = bytes(int(v / samples) for v in total)
    return dst


def resize_nearest_then_downsample(source, size):
    # Source is 1024 RGBA. Render to target directly by area sampling.
    dst = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            sx0 = int(x * 1024 / size)
            sx1 = max(sx0 + 1, int((x + 1) * 1024 / size))
            sy0 = int(y * 1024 / size)
            sy1 = max(sy0 + 1, int((y + 1) * 1024 / size))
            total = [0, 0, 0, 0]
            count = 0
            for sy in range(sy0, min(1024, sy1)):
                for sx in range(sx0, min(1024, sx1)):
                    i = (sy * 1024 + sx) * 4
                    for c in range(4):
                        total[c] += source[i + c]
                    count += 1
            o = (y * size + x) * 4
            dst[o : o + 4] = bytes(int(v / count) for v in total)
    return dst


def make_icon():
    scale = 3
    size = 1024 * scale
    px = bytearray(DARK * (size * size))
    c = size / 2

    # Soft centered glow.
    for radius, alpha in [(420, 20), (360, 28), (300, 34)]:
        fill_circle(px, size, c, c, radius * scale, (0, 212, 170, alpha))

    # Subtle shadow under the mark.
    fill_circle(px, size, c + 20 * scale, c + 28 * scale, 286 * scale, SHADOW)

    # Elapsed-time circular arrow.
    draw_arc(px, size, c, c, 292 * scale, -132, 210, 54 * scale, MINT)
    end = math.radians(210)
    ex = c + math.cos(end) * 292 * scale
    ey = c + math.sin(end) * 292 * scale
    fill_polygon(
        px,
        size,
        [
            (ex, ey),
            (ex + 94 * scale, ey - 16 * scale),
            (ex + 30 * scale, ey + 76 * scale),
        ],
        MINT,
    )

    # Clock face and hands.
    fill_circle(px, size, c, c, 206 * scale, WHITE)
    fill_circle(px, size, c, c, 154 * scale, DARK)
    draw_round_line(px, size, c, c, c, c - 116 * scale, 42 * scale, MINT_BRIGHT)
    draw_round_line(px, size, c, c, c + 104 * scale, c + 76 * scale, 42 * scale, MINT)
    fill_circle(px, size, c, c, 38 * scale, WHITE)
    fill_circle(px, size, c, c, 22 * scale, MINT_BRIGHT)

    # Small stopwatch crown.
    draw_round_line(
        px,
        size,
        c - 70 * scale,
        c - 350 * scale,
        c + 70 * scale,
        c - 350 * scale,
        42 * scale,
        MINT,
    )
    draw_round_line(
        px,
        size,
        c,
        c - 350 * scale,
        c,
        c - 296 * scale,
        46 * scale,
        MINT,
    )

    return downsample(px, size, scale)


def write_icon_set(source):
    os.makedirs(os.path.dirname(SOURCE), exist_ok=True)
    write_png(SOURCE, 1024, 1024, source)

    ios = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in ios_sizes.items():
        write_png(os.path.join(ios, name), size, size, resize_nearest_then_downsample(source, size))

    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        path = os.path.join(ROOT, "android", "app", "src", "main", "res", folder, "ic_launcher.png")
        write_png(path, size, size, resize_nearest_then_downsample(source, size))


if __name__ == "__main__":
    if len(sys.argv) > 1:
        image_path = os.path.abspath(sys.argv[1])
        width, height, pixels = read_png_rgba(image_path)
        icon = resize_rgba_to_square(pixels, width, height, 1024)
    else:
        icon = make_icon()

    write_icon_set(icon)
    print(f"Wrote {SOURCE}")
