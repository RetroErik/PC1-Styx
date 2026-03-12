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
| Startup screen | 320×200×4 (CGA mode 4) | 320×200×4 (unchanged) |
| Gameplay | 160×100×16 (tweaked CGA text mode) | 160×200×16 |
| Colors | 16 (fixed CGA palette) | 16 (programmable 512-color palette) |
| Pixel format | Character/attribute pairs at B800h | 4bpp, 2 pixels/byte at B000h |
| Mode setup | CRTC register programming | INT 10h mode 4 + port D8h unlock |

### Key modifications

- All pixel plotting, reading, and masking routines rewritten for 4bpp format
- VRAM segment changed from B800h to B000h
- Hidden mode enable sequence added (port D8h)
- CGA palette programming replaced with V6355D palette via ports DDh/DEh
- CGA snow wait elimination (V6355D has no snow)
- Screen redraw optimized with REP MOVSW block transfers
- 80186 immediate shift instructions used (NEC V40 CPU)
- Key remapping: Space = launch ball, F1 = pause

## Building

Requires [NASM](https://www.nasm.us/) and Python 3.

```
nasm -f bin -o STYX.BIN STYX.ASM
python make_exe.py STYX.BIN STYX.EXE
```

## Running

Copy `STYX.EXE` to your Olivetti Prodest PC1 (or compatible system) and run it from DOS.

Command-line options (inherited from Styx Remastered):
- `/Q` — Quiet mode (no sound)
- `/S:n` — Set speed (default 100)

## File Structure

| File | Purpose |
|------|---------|
| `STYX.ASM` | Combined NASM source (this gets compiled) |
| `STYX1.ASM` | I/O and graphics routines (A86 reference) |
| `STYX2.ASM` | Game logic (A86 reference) |
| `STYX3.ASM` | Additional game code (A86 reference) |
| `DATA.ASM` | Static data and variables (A86 reference) |
| `CODE.ASM` | Shared routines (A86 reference) |
| `PARSE.ASM` | Command-line parsing (A86 reference) |
| `PARSECMD.C` | Original C parser (compiled to PARSE.ASM) |
| `make_exe.py` | Converts flat binary to DOS EXE |
| `convert_a86_to_nasm.py` | A86-to-NASM syntax converter |

## Credits

- **Andrew Jenner** — Styx Remastered (1998–2004), reverse-engineered and remastered from the original Windmill Software game
- **Retro Erik** — Port to Olivetti Prodest PC1 hidden 160×200×16-color graphics mode

## License

This program is free software under the [GNU General Public License v2](COPYING).

Styx Remastered is Copyright © Andrew Jenner 1998–2004. The original Styx source code and binaries are Copyright © Windmill Software.
