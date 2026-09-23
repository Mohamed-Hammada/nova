"""
Asset generator for Nova's children's game platform.
Generates clean, warm, child-friendly illustrated art assets in pure Python
using math, procedural shapes, smoothstep anti-aliasing, and zlib/struct.
No third-party image libraries required.
"""
from __future__ import annotations

import math
import os
import struct
import zlib
from pathlib import Path

# --- PNG Writing Helper ---

def write_png(path: str | Path, width: int, height: int, rgba_bytes: bytearray) -> None:
    raw_rows = []
    stride = width * 4
    for y in range(height):
        offset = y * stride
        raw_rows.append(b'\x00' + bytes(rgba_bytes[offset:offset + stride]))
    raw_data = b''.join(raw_rows)
    compressed = zlib.compress(raw_data, level=9)

    def chunk(chunk_type: bytes, data: bytes) -> bytes:
        c = chunk_type + data
        crc = zlib.crc32(c) & 0xFFFFFFFF
        return struct.pack('>I', len(data)) + c + struct.pack('>I', crc)

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    png_bytes = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', compressed) + chunk(b'IEND', b'')

    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(png_bytes)


# --- Procedural RGBA Canvas ---

class Canvas:
    def __init__(self, width: int, height: int):
        self.w = width
        self.h = height
        self.buffer = bytearray(width * height * 4)

    def fill_rect(self, x0: int, y0: int, x1: int, y1: int, r: int, g: int, b: int, a: int = 255):
        for y in range(max(0, y0), min(self.h, y1)):
            for x in range(max(0, x0), min(self.w, x1)):
                self.blend_pixel(x, y, r, g, b, a / 255.0)

    def set_pixel(self, x: int, y: int, r: int, g: int, b: int, a: int = 255):
        if 0 <= x < self.w and 0 <= y < self.h:
            idx = (y * self.w + x) * 4
            self.buffer[idx] = r
            self.buffer[idx + 1] = g
            self.buffer[idx + 2] = b
            self.buffer[idx + 3] = a

    def blend_pixel(self, x: int, y: int, r: int, g: int, b: int, alpha: float):
        if 0 <= x < self.w and 0 <= y < self.h and alpha > 0.001:
            idx = (y * self.w + x) * 4
            dst_a = self.buffer[idx + 3] / 255.0
            src_a = min(1.0, max(0.0, alpha))
            out_a = src_a + dst_a * (1.0 - src_a)
            if out_a > 0:
                out_r = (r * src_a + self.buffer[idx] * dst_a * (1.0 - src_a)) / out_a
                out_g = (g * src_a + self.buffer[idx + 1] * dst_a * (1.0 - src_a)) / out_a
                out_b = (b * src_a + self.buffer[idx + 2] * dst_a * (1.0 - src_a)) / out_a
                self.buffer[idx] = int(round(out_r))
                self.buffer[idx + 1] = int(round(out_g))
                self.buffer[idx + 2] = int(round(out_b))
                self.buffer[idx + 3] = int(round(out_a * 255.0))

    def save(self, path: str | Path):
        write_png(path, self.w, self.h, self.buffer)


def smoothstep(edge0: float, edge1: float, x: float) -> float:
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def dist_point_to_segment(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    pax = px - ax
    pay = py - ay
    bax = bx - ax
    bay = by - ay
    h = max(0.0, min(1.0, (pax * bax + pay * bay) / (bax * bax + bay * bay + 1e-9)))
    dx = pax - bax * h
    dy = pay - bay * h
    return math.hypot(dx, dy)


# --- Asset Renderers ---

def render_apple(path: Path):
    W, H = 256, 256
    canvas = Canvas(W, H)

    # Shading colors
    # Warm ruby red body, bright highlight, deep shade, rich leaf
    for y in range(H):
        for x in range(W):
            nx = (x - 128) / 90.0
            ny = (y - 140) / 90.0

            # Apple heart/lobed shape SDF approximation
            # Left and right lobes
            d_left = math.hypot(nx + 0.35, ny + 0.05) - 0.72
            d_right = math.hypot(nx - 0.35, ny + 0.05) - 0.72
            # Bottom taper
            d_bottom = math.hypot(nx, ny - 0.25) - 0.78
            d_body = min(d_left, d_right, d_bottom)
            # Indent top and bottom
            top_indent = 0.35 * math.exp(-((nx * 2.8) ** 2) - ((ny + 0.6) * 3) ** 2)
            bot_indent = 0.25 * math.exp(-((nx * 2.8) ** 2) - ((ny - 0.8) * 3) ** 2)
            d_body += top_indent + bot_indent

            alpha = smoothstep(0.04, -0.04, d_body)

            if alpha > 0:
                # Radial gradient from upper-left
                light_dist = math.hypot(nx + 0.45, ny + 0.45)
                # Base gradient: Ruby red #E03535 to Deep Crimson #9E1616
                r_base = 224 - int(light_dist * 60)
                g_base = 53 - int(light_dist * 35)
                b_base = 53 - int(light_dist * 30)

                # Soft 3D rim lighting
                rim = math.hypot(nx, ny)
                r_col = max(110, min(245, r_base + int(rim * 15)))
                g_col = max(20, min(80, g_base))
                b_col = max(20, min(80, b_base))

                # Glossy specular shine
                d_shine = math.hypot(nx + 0.35, ny + 0.25)
                if d_shine < 0.28:
                    shine_factor = (1.0 - d_shine / 0.28) ** 2 * 0.75
                    r_col = int(r_col + (255 - r_col) * shine_factor)
                    g_col = int(g_col + (240 - g_col) * shine_factor)
                    b_col = int(b_col + (240 - b_col) * shine_factor)

                canvas.blend_pixel(x, y, r_col, g_col, b_col, alpha)

    # Stem and Leaf
    for y in range(H):
        for x in range(W):
            nx = (x - 128) / 90.0
            ny = (y - 140) / 90.0

            # Stem: curved brown cylinder
            d_stem = dist_point_to_segment(nx, ny, 0.0, -0.65, 0.12, -1.05) - 0.045
            stem_alpha = smoothstep(0.02, -0.02, d_stem)
            if stem_alpha > 0:
                canvas.blend_pixel(x, y, 107, 68, 35, stem_alpha)

            # Leaf: oval rotated on right side
            lx = (nx - 0.32) * 1.5
            ly = (ny + 0.88) * 2.2
            # Rotate -30 degrees
            rad = -0.52
            rlx = lx * math.cos(rad) - ly * math.sin(rad)
            rly = lx * math.sin(rad) + ly * math.cos(rad)
            d_leaf = math.hypot(rlx, rly * 1.8) - 0.32
            leaf_alpha = smoothstep(0.03, -0.03, d_leaf)
            if leaf_alpha > 0:
                # Leaf gradient
                lg = 0.5 + 0.5 * rlx
                lr = int(50 + 40 * lg)
                lg_c = int(160 + 50 * lg)
                lb = int(45 + 30 * lg)
                canvas.blend_pixel(x, y, lr, lg_c, lb, leaf_alpha)

    canvas.save(path)


def render_pear(path: Path):
    W, H = 256, 256
    canvas = Canvas(W, H)

    for y in range(H):
        for x in range(W):
            nx = (x - 128) / 90.0
            ny = (y - 140) / 90.0

            # Pear shape: small top sphere, wide bottom sphere
            d_top = math.hypot(nx, ny + 0.35) - 0.44
            d_bot = math.hypot(nx, ny - 0.32) - 0.72
            # Smooth min
            k = 0.35
            h = max(0.0, min(1.0, 0.5 + 0.5 * (d_bot - d_top) / k))
            d_body = (1.0 - h) * d_bot + h * d_top - k * h * (1.0 - h)

            # Bottom indent
            bot_indent = 0.22 * math.exp(-((nx * 3.0) ** 2) - ((ny - 0.95) * 3) ** 2)
            d_body += bot_indent

            alpha = smoothstep(0.04, -0.04, d_body)
            if alpha > 0:
                # Golden-pear gradient: #85B826 to #E6C229 to #D49B15
                light_dist = math.hypot(nx + 0.35, ny + 0.45)
                r_col = min(250, max(130, int(210 - light_dist * 40)))
                g_col = min(240, max(140, int(195 - light_dist * 35)))
                b_col = min(80, max(20, int(45 - light_dist * 20)))

                # Specular shine
                d_shine = math.hypot(nx + 0.3, ny - 0.1)
                if d_shine < 0.25:
                    sf = (1.0 - d_shine / 0.25) ** 2 * 0.65
                    r_col = int(r_col + (255 - r_col) * sf)
                    g_col = int(g_col + (255 - g_col) * sf)
                    b_col = int(b_col + (220 - b_col) * sf)

                canvas.blend_pixel(x, y, r_col, g_col, b_col, alpha)

    # Stem and Leaf
    for y in range(H):
        for x in range(W):
            nx = (x - 128) / 90.0
            ny = (y - 140) / 90.0

            d_stem = dist_point_to_segment(nx, ny, 0.0, -0.75, 0.1, -1.08) - 0.045
            stem_alpha = smoothstep(0.02, -0.02, d_stem)
            if stem_alpha > 0:
                canvas.blend_pixel(x, y, 107, 68, 35, stem_alpha)

            lx = (nx - 0.28) * 1.5
            ly = (ny + 0.95) * 2.2
            rad = -0.45
            rlx = lx * math.cos(rad) - ly * math.sin(rad)
            rly = lx * math.sin(rad) + ly * math.cos(rad)
            d_leaf = math.hypot(rlx, rly * 1.8) - 0.28
            leaf_alpha = smoothstep(0.03, -0.03, d_leaf)
            if leaf_alpha > 0:
                canvas.blend_pixel(x, y, 80, 165, 45, leaf_alpha)

    canvas.save(path)


def render_basket(path: Path, front_only: bool = False):
    W, H = 320, 260
    canvas = Canvas(W, H)

    # Wicker basket: curved tub with weave pattern
    cx, cy = 160, 160
    rx, ry = 130, 75

    if not front_only:
        # Handle (arches over top)
        for y in range(H):
            for x in range(W):
                nx = (x - cx) / 110.0
                ny = (y - (cy - 30)) / 110.0
                # Arch
                if ny < 0.2:
                    d_arch = abs(math.hypot(nx, ny * 1.25) - 0.95) - 0.075
                    h_alpha = smoothstep(0.025, -0.025, d_arch)
                    if h_alpha > 0:
                        # Handle wood/wicker twist
                        twist = math.sin((math.atan2(ny, nx) + 3.14) * 22) * 15
                        canvas.blend_pixel(x, y, int(175 + twist), int(120 + twist * 0.7), int(65 + twist * 0.5), h_alpha)

        # Basket interior background (dark cavity)
        for y in range(H):
            for x in range(W):
                nx = (x - cx) / rx
                ny = (y - (cy - 10)) / (ry * 0.55)
                d_interior = math.hypot(nx, ny) - 0.95
                if d_interior < 0:
                    int_alpha = smoothstep(0.02, -0.02, d_interior)
                    canvas.blend_pixel(x, y, 75, 42, 20, int_alpha)

    # Basket bowl / body
    for y in range(H):
        for x in range(W):
            if y < (cy - 15) and front_only:
                continue

            nx = (x - cx) / rx
            ny = (y - cy) / ry

            # Taper toward bottom
            taper = 1.0 + (ny - 0.2) * 0.25 if ny > 0 else 1.0
            curved_x = nx / taper

            # Tub shape: rounded bottom
            if ny > -0.2:
                d_body = math.hypot(curved_x * 0.95, ny * 0.9) - 0.95
                if ny > 0.85:
                    d_body = max(d_body, (ny - 0.85) * 2.0)
                b_alpha = smoothstep(0.03, -0.03, d_body)

                if b_alpha > 0 and y >= (cy - 15):
                    # Wicker weave texture
                    weave_u = math.sin(x * 0.22 + y * 0.12)
                    weave_v = math.cos(x * 0.22 - y * 0.12)
                    weave = (weave_u * weave_v) * 25.0

                    # Vertical shading
                    v_shade = 1.0 - (ny * 0.3)
                    r_c = max(70, min(235, int((190 + weave) * v_shade)))
                    g_c = max(45, min(175, int((135 + weave * 0.7) * v_shade)))
                    b_c = max(25, min(110, int((78 + weave * 0.4) * v_shade)))

                    # Highlight on top rim
                    if abs(ny + 0.15) < 0.12:
                        rim_boost = (1.0 - abs(ny + 0.15) / 0.12) * 35
                        r_c = min(255, int(r_c + rim_boost))
                        g_c = min(220, int(g_c + rim_boost))
                        b_c = min(150, int(b_c + rim_boost))

                    canvas.blend_pixel(x, y, r_c, g_c, b_c, b_alpha)

    # Braided rim around top
    for y in range(H):
        for x in range(W):
            nx = (x - cx) / (rx * 1.04)
            ny = (y - (cy - 12)) / 16.0
            d_rim = math.hypot(nx, ny) - 0.98
            rim_alpha = smoothstep(0.04, -0.04, d_rim)
            if rim_alpha > 0:
                braid = math.sin(x * 0.3) * 20
                canvas.blend_pixel(x, y, int(220 + braid), int(160 + braid * 0.8), int(95 + braid * 0.5), rim_alpha)

    canvas.save(path)


def render_bear(path: Path, state: str = "idle"):
    W, H = 256, 256
    canvas = Canvas(W, H)

    cx, cy = 128, 140

    # Colors
    fur_r, fur_g, fur_b = 184, 115, 66     # Warm caramel bear fur
    fur_shade_r, fur_shade_g, fur_shade_b = 143, 84, 44
    muzzle_r, muzzle_g, muzzle_b = 247, 218, 182 # Soft cream muzzle
    pink_ear_r, pink_ear_g, pink_ear_b = 230, 160, 155
    ink_r, ink_g, ink_b = 44, 30, 24

    # Body / Torso
    for y in range(H):
        for x in range(W):
            nx = (x - cx) / 85.0
            ny = (y - (cy + 55)) / 65.0
            d_torso = math.hypot(nx, ny) - 0.95
            t_alpha = smoothstep(0.03, -0.03, d_torso)
            if t_alpha > 0:
                shade = 0.85 + 0.15 * math.cos(nx * 1.5)
                canvas.blend_pixel(x, y, int(fur_r * shade), int(fur_g * shade), int(fur_b * shade), t_alpha)

    # Ears (Left and Right)
    for ear_x, ear_y in [(cx - 62, cy - 58), (cx + 62, cy - 58)]:
        for y in range(H):
            for x in range(W):
                nx = (x - ear_x) / 32.0
                ny = (y - ear_y) / 32.0
                d_ear = math.hypot(nx, ny) - 0.9
                e_alpha = smoothstep(0.04, -0.04, d_ear)
                if e_alpha > 0:
                    # Outer fur
                    canvas.blend_pixel(x, y, fur_r, fur_g, fur_b, e_alpha)
                    # Inner pink
                    d_inner = math.hypot(nx, ny) - 0.55
                    i_alpha = smoothstep(0.04, -0.04, d_inner)
                    if i_alpha > 0:
                        canvas.blend_pixel(x, y, pink_ear_r, pink_ear_g, pink_ear_b, i_alpha)

    # Head (warm rounded dome)
    head_tilt = 0.08 if state == "thinking" else 0.0
    for y in range(H):
        for x in range(W):
            # Apply tilt for thinking state
            px = x - cx
            py = y - (cy - 10)
            rx = px * math.cos(head_tilt) - py * math.sin(head_tilt)
            ry = px * math.sin(head_tilt) + py * math.cos(head_tilt)

            nx = rx / 82.0
            ny = ry / 74.0
            d_head = math.hypot(nx, ny) - 0.96
            h_alpha = smoothstep(0.03, -0.03, d_head)
            if h_alpha > 0:
                # 3D spherical lighting from top-left
                l_dist = math.hypot(nx + 0.35, ny + 0.45)
                shade = max(0.72, min(1.15, 1.1 - l_dist * 0.35))
                cr = min(255, int(fur_r * shade))
                cg = min(255, int(fur_g * shade))
                cb = min(255, int(fur_b * shade))
                canvas.blend_pixel(x, y, cr, cg, cb, h_alpha)

    # Muzzle (cream oval)
    muzzle_cy = cy + 18
    for y in range(H):
        for x in range(W):
            px = x - cx
            py = y - muzzle_cy
            rx = px * math.cos(head_tilt) - py * math.sin(head_tilt)
            ry = px * math.sin(head_tilt) + py * math.cos(head_tilt)
            nx = rx / 45.0
            ny = ry / 34.0
            d_muz = math.hypot(nx, ny) - 0.95
            m_alpha = smoothstep(0.04, -0.04, d_muz)
            if m_alpha > 0:
                canvas.blend_pixel(x, y, muzzle_r, muzzle_g, muzzle_b, m_alpha)

    # Nose (soft triangular rounded button with highlight)
    nose_cy = cy + 6
    for y in range(H):
        for x in range(W):
            px = x - cx
            py = y - nose_cy
            rx = px * math.cos(head_tilt) - py * math.sin(head_tilt)
            ry = px * math.sin(head_tilt) + py * math.cos(head_tilt)
            nx = rx / 16.0
            ny = ry / 11.0
            d_nose = math.hypot(nx, ny) - 0.95
            n_alpha = smoothstep(0.05, -0.05, d_nose)
            if n_alpha > 0:
                # Nose shine
                if (nx + 0.25) ** 2 + (ny + 0.3) ** 2 < 0.2:
                    canvas.blend_pixel(x, y, 160, 150, 145, n_alpha)
                else:
                    canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, n_alpha)

    # Eyes & Expressions
    eye_y = cy - 14
    eye_offset_x = 32

    if state in ("happy", "celebrating"):
        # Happy crescent eyes (curved upwards arcs ^ ^)
        for side in (-1, 1):
            ex = cx + side * eye_offset_x
            for y in range(H):
                for x in range(W):
                    px = x - ex
                    py = y - (eye_y + 2)
                    rx = px * math.cos(head_tilt) - py * math.sin(head_tilt)
                    ry = px * math.sin(head_tilt) + py * math.cos(head_tilt)
                    # Inverted U: top arc of ellipse
                    d_arc = abs(math.hypot(rx / 13.0, (ry + 3) / 9.0) - 1.0) - 0.22
                    if ry > -1: # Cull bottom half so it is open at bottom
                        d_arc = 1.0
                    a_alpha = smoothstep(0.05, -0.05, d_arc)
                    if a_alpha > 0:
                        canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, a_alpha)

        # Cheerful open smiling mouth with pink tongue
        for y in range(H):
            for x in range(W):
                px = x - cx
                py = y - (muzzle_cy + 10)
                rx = px * math.cos(head_tilt) - py * math.sin(head_tilt)
                ry = px * math.sin(head_tilt) + py * math.cos(head_tilt)
                d_mouth = math.hypot(rx / 19.0, (ry - 2) / 13.0) - 0.95
                if ry < 0: # Only bottom half
                    d_mouth = 1.0
                m_alpha = smoothstep(0.05, -0.05, d_mouth)
                if m_alpha > 0:
                    if ry > 5:
                        canvas.blend_pixel(x, y, 235, 95, 110, m_alpha) # Tongue
                    else:
                        canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, m_alpha)

        # Rosy cheeks
        for side in (-1, 1):
            ch_x = cx + side * 48
            for y in range(H):
                for x in range(W):
                    d_cheek = math.hypot((x - ch_x) / 14.0, (y - (cy + 16)) / 9.0) - 0.9
                    c_alpha = smoothstep(0.08, -0.08, d_cheek) * 0.45
                    if c_alpha > 0:
                        canvas.blend_pixel(x, y, 245, 110, 110, c_alpha)

    elif state == "thinking":
        # Thoughtful looking-up eyes
        for side in (-1, 1):
            ex = cx + side * eye_offset_x
            for y in range(H):
                for x in range(W):
                    px = x - ex
                    py = y - eye_y
                    rx = px * math.cos(head_tilt) - py * math.sin(head_tilt)
                    ry = px * math.sin(head_tilt) + py * math.cos(head_tilt)
                    d_eye = math.hypot(rx / 9.0, ry / 10.0) - 0.95
                    e_alpha = smoothstep(0.05, -0.05, d_eye)
                    if e_alpha > 0:
                        # Pupil looking up & right
                        if (rx - 2) ** 2 + (ry + 3) ** 2 < 12:
                            canvas.blend_pixel(x, y, 255, 255, 255, e_alpha)
                        else:
                            canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, e_alpha)

        # Inquisitive curved small mouth
        for y in range(H):
            for x in range(W):
                px = x - (cx + 4)
                py = y - (muzzle_cy + 12)
                d_smile = abs(math.hypot(px / 12.0, (py - 1) / 7.0) - 1.0) - 0.18
                if py < 1:
                    d_smile = 1.0
                l_alpha = smoothstep(0.05, -0.05, d_smile)
                if l_alpha > 0:
                    canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, l_alpha)

    else: # "idle" / "waiting"
        # Friendly round eyes with glint
        for side in (-1, 1):
            ex = cx + side * eye_offset_x
            for y in range(H):
                for x in range(W):
                    px = x - ex
                    py = y - eye_y
                    d_eye = math.hypot(px / 9.0, py / 10.0) - 0.95
                    e_alpha = smoothstep(0.05, -0.05, d_eye)
                    if e_alpha > 0:
                        # Catchlight in upper-left of pupil
                        if (px + 3) ** 2 + (py + 3) ** 2 < 9:
                            canvas.blend_pixel(x, y, 255, 255, 255, e_alpha)
                        else:
                            canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, e_alpha)

        # Sweet gentle smile (bottom arc of ellipse)
        for y in range(H):
            for x in range(W):
                px = x - cx
                py = y - (muzzle_cy + 10)
                d_smile = abs(math.hypot(px / 16.0, (py - 1) / 8.0) - 1.0) - 0.18
                if py < 1: # Only bottom half
                    d_smile = 1.0
                s_alpha = smoothstep(0.05, -0.05, d_smile)
                if s_alpha > 0:
                    canvas.blend_pixel(x, y, ink_r, ink_g, ink_b, s_alpha)

    # Paws
    if state == "celebrating":
        # Raised happy celebration paws
        for side in (-1, 1):
            paw_x = cx + side * 85
            paw_y = cy - 25
            for y in range(H):
                for x in range(W):
                    d_paw = math.hypot((x - paw_x) / 18.0, (y - paw_y) / 18.0) - 0.95
                    p_alpha = smoothstep(0.05, -0.05, d_paw)
                    if p_alpha > 0:
                        canvas.blend_pixel(x, y, fur_r, fur_g, fur_b, p_alpha)
    else:
        # Relaxed rounded paws in front
        for side in (-1, 1):
            paw_x = cx + side * 48
            paw_y = cy + 72
            for y in range(H):
                for x in range(W):
                    d_paw = math.hypot((x - paw_x) / 18.0, (y - paw_y) / 14.0) - 0.95
                    p_alpha = smoothstep(0.05, -0.05, d_paw)
                    if p_alpha > 0:
                        canvas.blend_pixel(x, y, fur_r, fur_g, fur_b, p_alpha)

    canvas.save(path)


def render_star(path: Path):
    W, H = 160, 160
    canvas = Canvas(W, H)
    cx, cy = 80, 80

    for y in range(H):
        for x in range(W):
            dx = x - cx
            dy = y - cy
            dist = math.hypot(dx, dy)
            angle = math.atan2(dy, dx) - math.pi / 2.0
            # 5 pointed star radius modulation
            r_star = 52.0 + 24.0 * math.cos(5.0 * angle)
            d = dist - r_star
            alpha = smoothstep(0.03 * r_star, -0.03 * r_star, d)
            if alpha > 0:
                # Golden yellow to warm amber gradient with shine
                g_factor = max(0.0, min(1.0, 1.0 - dist / 70.0))
                r_c = 255
                g_c = int(195 + 50 * g_factor)
                b_c = int(35 + 80 * g_factor)
                # Inner glow
                if dist < 25:
                    r_c, g_c, b_c = 255, 255, 200
                canvas.blend_pixel(x, y, r_c, g_c, b_c, alpha)

    canvas.save(path)


def render_sparkle(path: Path):
    W, H = 120, 120
    canvas = Canvas(W, H)
    cx, cy = 60, 60

    for y in range(H):
        for x in range(W):
            dx = abs(x - cx) / 50.0
            dy = abs(y - cy) / 50.0
            # 4-point diamond cross
            d = (dx ** 0.5 + dy ** 0.5) - 0.8
            alpha = smoothstep(0.05, -0.05, d)
            if alpha > 0:
                canvas.blend_pixel(x, y, 255, 245, 180, alpha)

    canvas.save(path)


def render_cloud(path: Path):
    W, H = 256, 140
    canvas = Canvas(W, H)

    # 4 overlapping circles forming a friendly puffy cloud
    circles = [(75, 80, 38), (115, 60, 48), (160, 65, 42), (195, 82, 34)]
    for y in range(H):
        for x in range(W):
            min_d = 999.0
            for cx, cy, r in circles:
                d = math.hypot(x - cx, y - cy) - r
                if d < min_d:
                    min_d = d
            alpha = smoothstep(0.03 * 40, -0.03 * 40, min_d)
            if alpha > 0:
                # Soft vertical shading (white top, soft sky-tinted bottom)
                ny = y / 140.0
                r_c = int(255 - ny * 18)
                g_c = int(255 - ny * 12)
                b_c = int(255 - ny * 5)
                canvas.blend_pixel(x, y, r_c, g_c, b_c, alpha * 0.95)

    canvas.save(path)


def render_sun(path: Path):
    W, H = 180, 180
    canvas = Canvas(W, H)
    cx, cy = 90, 90

    for y in range(H):
        for x in range(W):
            dx = x - cx
            dy = y - cy
            dist = math.hypot(dx, dy)
            angle = math.atan2(dy, dx)
            # Radiant soft sun rays
            ray = 12.0 * math.cos(8.0 * angle)
            r_sun = 56.0 + max(0.0, ray)
            d = dist - r_sun
            alpha = smoothstep(0.05 * 56, -0.05 * 56, d)
            if alpha > 0:
                canvas.blend_pixel(x, y, 255, 215, 65, alpha * 0.92)

    canvas.save(path)


def render_tree_branch(path: Path):
    W, H = 384, 180
    canvas = Canvas(W, H)

    # Branch sweeping across top
    # Leaves clusters
    leaf_clusters = [
        (60, 40, 45), (120, 50, 52), (180, 35, 48), (240, 60, 50),
        (300, 45, 42), (340, 70, 38), (140, 85, 36), (220, 95, 35)
    ]
    for y in range(H):
        for x in range(W):
            # Brown branch stem
            d_branch = dist_point_to_segment(x, y, 0, 20, 360, 60) - 14.0
            b_alpha = smoothstep(0.04 * 14, -0.04 * 14, d_branch)
            if b_alpha > 0:
                canvas.blend_pixel(x, y, 115, 75, 40, b_alpha)

            # Leaves
            min_d = 999.0
            for lx, ly, lr in leaf_clusters:
                d = math.hypot(x - lx, y - ly) - lr
                if d < min_d:
                    min_d = d
            l_alpha = smoothstep(0.03 * 45, -0.03 * 45, min_d)
            if l_alpha > 0:
                # Sunlight dapple
                dapple = math.sin(x * 0.15 + y * 0.15) * 20
                canvas.blend_pixel(x, y, int(95 + dapple), int(175 + dapple), int(55 + dapple * 0.5), l_alpha * 0.95)

    canvas.save(path)


def render_meadow_background(path: Path):
    W, H = 480, 480
    canvas = Canvas(W, H)

    # Sunny day sky + soft rolling hills + lush meadow
    for y in range(H):
        ny = y / float(H)
        for x in range(W):
            nx = x / float(W)

            # Sky gradient: pastel sky blue #BEE3F8 fading to warm sunlight gold #FEFCBF near horizon
            if ny < 0.45:
                sky_t = ny / 0.45
                r = int(185 + sky_t * 60)
                g = int(225 + sky_t * 25)
                b = int(248 - sky_t * 55)
                canvas.set_pixel(x, y, r, g, b, 255)
            else:
                # Rolling hills
                # Distant hill 1
                h1 = 0.45 + 0.05 * math.sin(nx * 4.5)
                # Midground hill 2
                h2 = 0.55 + 0.06 * math.cos(nx * 3.8 + 1.2)
                # Foreground meadow
                h3 = 0.68 + 0.04 * math.sin(nx * 2.5 + 2.0)

                if ny < h1:
                    sky_t = ny / 0.45
                    canvas.set_pixel(x, y, 245, 250, 205, 255)
                elif ny < h2:
                    # Distant hill: soft sage blue-green
                    t = (ny - h1) / 0.15
                    canvas.set_pixel(x, y, int(155 - t * 15), int(205 - t * 10), int(175 - t * 25), 255)
                elif ny < h3:
                    # Mid hill: sunny meadow green
                    t = (ny - h2) / 0.15
                    canvas.set_pixel(x, y, int(135 - t * 20), int(195 - t * 15), int(95 - t * 20), 255)
                else:
                    # Foreground grass: rich vibrant warm green
                    t = (ny - h3) / 0.32
                    canvas.set_pixel(x, y, int(115 - t * 25), int(178 - t * 20), int(72 - t * 15), 255)

    canvas.save(path)


def render_picnic_blanket(path: Path):
    W, H = 360, 200
    canvas = Canvas(W, H)
    cx, cy = 180, 100

    # Perspective rounded mat/blanket with red & white check pattern
    for y in range(H):
        ny = (y - cy) / 80.0
        for x in range(W):
            nx = (x - cx) / 160.0
            # Perspective trapezoid: wider in front
            taper = 1.0 + ny * 0.2
            px = nx / taper
            d_blanket = math.hypot(px * 0.95, ny) - 0.95
            b_alpha = smoothstep(0.04, -0.04, d_blanket)
            if b_alpha > 0:
                # Checkered pattern
                check_x = int((x + 20) / 28) % 2
                check_y = int((y + 10) / 22) % 2
                if (check_x + check_y) % 2 == 0:
                    # Cheerful red check
                    canvas.blend_pixel(x, y, 235, 78, 78, b_alpha)
                else:
                    # Soft white/cream check
                    canvas.blend_pixel(x, y, 252, 248, 242, b_alpha)

    canvas.save(path)


def main():
    root = Path(__file__).resolve().parents[1]
    art_dir = root / "app" / "assets" / "art"

    assets = {
        art_dir / "characters" / "bear_idle.png": lambda p: render_bear(p, "idle"),
        art_dir / "characters" / "bear_happy.png": lambda p: render_bear(p, "happy"),
        art_dir / "characters" / "bear_thinking.png": lambda p: render_bear(p, "thinking"),
        art_dir / "characters" / "bear_celebrate.png": lambda p: render_bear(p, "celebrating"),
        art_dir / "environments" / "forest_clearing_bg.png": render_meadow_background,
        art_dir / "environments" / "tree_branch.png": render_tree_branch,
        art_dir / "environments" / "picnic_blanket.png": render_picnic_blanket,
        art_dir / "environments" / "cloud_fluffy.png": render_cloud,
        art_dir / "environments" / "sun_warm.png": render_sun,
        art_dir / "objects" / "apple.png": render_apple,
        art_dir / "objects" / "pear.png": render_pear,
        art_dir / "objects" / "basket.png": lambda p: render_basket(p, front_only=False),
        art_dir / "objects" / "basket_rim.png": lambda p: render_basket(p, front_only=True),
        art_dir / "feedback" / "star_gold.png": render_star,
        art_dir / "feedback" / "sparkle.png": render_sparkle,
    }

    for path, renderer in assets.items():
        renderer(path)
        print(f"Generated {path.relative_to(root)}")

    print(f"Successfully generated {len(assets)} art assets.")


if __name__ == "__main__":
    main()
