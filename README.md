# PC1-Styx

A port of **Styx Remastered** to the Olivetti Prodest PC1's hidden 160×200×16-color graphics mode.

![Olivetti Prodest PC1](https://img.shields.io/badge/Platform-Olivetti%20Prodest%20PC1-blue)
![License](https://img.shields.io/badge/License-GPLv2-green)

## About

Styx is a territory-claiming arcade game where the player walks along borders and draws trails to claim territory while avoiding enemies. The original game was developed by Windmill Software in 1983 and used a little-known "tweaked" CGA text mode hack to display all 16 colors at 160×100 resolution — a paltry resolution, but quite effective on CGA monitors and ideal for games of this sort. **Andrew Jenner** later remastered it (1998–2004) as *Styx Remastered*, directly converting the original 160×100×16 graphics rather than redrawing them, and retaining the same resolution and 16-color look while making it run on all PCs with CGA or better.

This port adapts Styx Remastered to run on the **Olivetti Prodest PC1** (and compatible Olivetti M21/M24/AT&T 6300 systems), taking advantage of the Yamaha V6355D video chip's hidden 160×200×16-color graphics mode — providing 16 colors from a programmable 512-color palette instead of the original CGA's fixed 4-color palette.

## What Changed

| Aspect | Styx Remastered (CGA) | PC1 Hidden Mode |
|--------|----------------------|-----------------|
| Startup screen | 320×200×4 RLE-decoded logo | 320×200 BMP with per-scanline CGA palette flip + raster bars |
| Gameplay | 160×100×16 (tweaked CGA text mode) | 160×200×16 |
| Colors | 16 (fixed CGA palette) | 16 (programmable 512-color palette) |
| Pixel format | Character/attribute pairs at B800h | 4bpp, 2 pixels/byte at B000h |
| Mode setup | CRTC register programming | INT 10h mode 4 + port D8h unlock |

### Key modifications

- **Startup screen**: Custom 8-bit BMP viewer using per-scanline V6355D palette reprogramming (CGA palette flip) in 320×200×4 mode, providing 3 independent colors per scanline from a 512-color palette. Animated raster bars (red and blue sine-wave gradients) scroll behind the STYX title letters. Falls back to the original RLE title if `STYX.BMP` is not found.
- All pixel plotting, reading, and masking routines rewritten for 4bpp format
- VRAM segment changed from B800h to B000h
- Hidden mode enable sequence added (port D8h)
- CGA palette programming replaced with V6355D palette via ports DDh/DEh
- CGA snow wait elimination (V6355D has no snow)
- Screen redraw optimized with REP MOVSW block transfers
- 80186 immediate shift instructions used (NEC V40 CPU)
- Key remapping: Space = launch ball, F1 = pause

## CGA Palette Flip (Startup Screen)

The V6355D has two palette banks (PAL_EVEN and PAL_ODD), each with entries E0–E7. CGA mode 4 maps 2-bit pixel values to these entries. By alternating the active bank at each horizontal blanking interval (HBLANK) and writing different RGB values to the inactive bank, each scanline can display 3 independent colors from the 512-color palette — far beyond CGA's normal 4 fixed colors.

The startup screen renderer uses a 4-zone layout:

| Zone | Lines | Action |
|------|-------|--------|
| 1a | 0–47 | Flip-first: alternate banks, write E2–E7 to inactive bank (12 bytes via REP OUTSB) |
| 1b | 48–127 | Idle: palette has converged, both banks hold correct colors |
| 2 | 128–173 | Raster bars: write entry E0 only (background color), animated red/blue gradients |
| 3 | 174–199 | Idle: E2–E7 still correct from Zone 1a |

Zone 1a stops after 48 lines because the image colors are uniform from line 48 onward — both banks already have the same E2–E7 values, so no further flipping is needed. This saves ~1,200 I/O port writes per frame. The raster bar zone only modifies E0 (shared by both banks), so the STYX title letters (which use E2–E7 colors) remain visible.

Tunable parameters in the source (`STYX.ASM`):
- `SS_FLIP_LINES` — number of flip-first lines (default 48, must be even)
- `SS_BAR_START` — first scanline of bar zone (default 128)
- `SS_BAR_END` — first scanline after bar zone (default 174)
- `SS_BAR_HEIGHT` — height of each gradient bar (default 14)

## Building

Requires [NASM](https://www.nasm.us/) and Python 3.

```
nasm -f bin -o STYX.BIN STYX.ASM
python make_exe.py STYX.BIN STYX.EXE
```

## Running

Copy `STYX.EXE` and `STYX.BMP` to your Olivetti Prodest PC1 (or compatible system) and run from DOS.

Command-line options (inherited from Styx Remastered):
- `/Q` — Quiet mode (no sound)
- `/S:n` — Set speed (default 100)
- `/N` — No images (disable BMP loading)

## File Structure

| File | Purpose |
|------|---------|
| `STYX.ASM` | Combined NASM source (this gets compiled) |
| `STYX.BMP` | 320×200 8-bit BMP startup image (displayed with CGA palette flip) |
| `make_exe.py` | Converts flat binary to DOS EXE |

The original A86 source files and conversion script have been moved to `Old A86 Source Code/`:

| File | Purpose |
|------|---------|
| `STYX1.ASM` | I/O and graphics routines (A86 original) |
| `STYX2.ASM` | Game logic (A86 original) |
| `STYX3.ASM` | Additional game code (A86 original) |
| `DATA.ASM` | Static data and variables (A86 original) |
| `CODE.ASM` | Shared routines (A86 original) |
| `PARSE.ASM` | Command-line parsing (A86 original) |
| `PARSECMD.C` | Original C parser (compiled to PARSE.ASM) |
| `convert_a86_to_nasm.py` | A86-to-NASM syntax converter (merges the above into STYX.ASM) |

## Credits

- **Andrew Jenner** — Styx Remastered (1998–2004), reverse-engineered and remastered from the original Windmill Software game
- **Retro Erik** — Port to Olivetti Prodest PC1 hidden 160×200×16-color graphics mode

## License

This program is free software under the [GNU General Public License v2](COPYING).

Styx Remastered is Copyright © Andrew Jenner 1998–2004. The original Styx source code and binaries are Copyright © Windmill Software.
