;============================================================================
;  STYX REMASTERED — Olivetti Prodest PC1 Port
;============================================================================
;  Original game:  Windmill Software, 1983
;  Remastered by:  Andrew Jenner, 1998-2004
;  NASM conversion & PC1 port: Retro Erik, 2026
;
;  Target CPU:   NEC V40 (80186 instruction set)
;  Target video: Olivetti V6355D — hidden 160×200×16-color mode
;                VRAM at B000:0000 (even scanlines) and B000:2000 (odd)
;                Each bank: 100 rows × 80 bytes/row = 8000 bytes
;                Each byte = 2 pixels (high nibble = left, low = right)
;  Shadow buffer: p12e in data segment — 8000-byte copy of VRAM (even bank
;                 layout), all game logic writes here first, then copies
;                 to both VRAM banks during screen refresh.
;
;  Palette:  16 colours × 2 bytes, programmed via I/O ports DDh/DEh
;            Port DDh: 40h = open palette for writing, 80h = close
;            Port DEh: sequential writes of 32 bytes (R then GB per color)
;            Format per color — byte 1: Red (bits 0-2, 0-7)
;                               byte 2: Green (bits 4-6) | Blue (bits 0-2)
;            CGA palette table:  cs_cga_colors (in code segment)
;            BMP palette table:  bmp_palette   (in data segment)
;
;  Sound:    PC speaker driven by PIT Timer channel 2 (ports 40h-43h)
;            Speaker gate via port 61h bits 0-1
;            INT 8 timer ISR handles timed speaker toggling for music/SFX
;
;  Input:    Keyboard via INT 9 handler (port 60h), optional joystick (201h)
;
;  BMP background: Optional STYX.BMP loaded at startup; territory colors
;            1-6 are substituted with corresponding BMP pixels during VRAM
;            writes, creating a "reveal the picture" effect as territory
;            is claimed.
;
;----------------------------------------------------------------------------
;  FILE STRUCTURE  (merged from original multi-file project)
;----------------------------------------------------------------------------
;  Lines ~119-4190     STYX1.ASM — Core engine
;                        MAIN entry, stack/segment init, command-line parse
;                        Random number generator (o227)
;                        Trig library: abs (o2a9), sin (o2c1), cos (o2e7)
;                        Speed calibration (calibrate) & delay loops
;                        CGA mode setup (o44b) & PC1 hidden mode (o543)
;                        Palette programming (pc1_set_cga_palette)
;                        Screen refresh / BMP reveal (o5c3)
;                        Territory color fill (o64o) & pixel scanning
;                        Pixel read/write: oa6e (coord→addr), oa7d (read),
;                          oa89 (write+BMP sub), bmp_vram_write
;                        Screen clear (o8c1), VBlank wait
;                        Keyboard INT 9 handler (od2e) & key dispatch table
;                        Key state vars: pbo-pb7 (arrows), pd3/pd4 (direction)
;                        Screen wobble effect
;                        Timer INT 8 handler (o11dd) — sound timing
;                        Enemy init (o1227) & AI movement loop (o1391)
;                        Player tail manager (o1bab)
;                        Player init (o1def) & movement logic
;
;  Lines ~4194-4346    PARSE.ASM — Command-line parser (_parsecmd / cmdline)
;                        Supports: /S:nn speed, /Q quiet, /N no images
;
;  Lines ~4347-8146    STYX2.ASM — Game logic & scoring
;                        Player movement state machine (o21do)
;                        Territory claiming & enclosure detection (o235f)
;                        Flood fill for claimed areas (o3o89)
;                        Score / level management, difficulty progression
;                        Joystick support (o35ee, o37oo)
;                        High score file I/O — STYX.SCO (o37cf)
;                        Score / lives / level display (o3cc3, o3d8b, o3dc8)
;
;  Lines ~8147-12430   STYX3.ASM — Sound, rendering, main loop, math library
;                        PIT / speaker sound system (o4427)
;                        Sound effects: death (o48bd), birth (o49oa), level
;                        Character / digit rendering (o4b72, o4c8a)
;                        Text string printing (o4feb)
;                        Color palette cycling effects (o5o29, o5odd)
;                        *** MAIN GAME ENTRY: o556a — startup screen ***
;                          → loads STYX.BMP → shows BMP title with
;                            per-scanline palette flip + high scores
;                          → fallback: attract mode loop (o55a8)
;                            with RLE title (o1142) if no BMP
;                          → game init (o55do): load level BMP,
;                            set PC1 mode, draw border, init state
;                          → level loop (o56dd): calls player logic,
;                            enemy AI, sound, tail, difficulty each frame
;                        32-bit fixed-point math: mul (o5993), div (o5ca2),
;                          add (o5f1b), compare (o6of2), normalize (o689c),
;                          denormalize (o68ce)
;                        printf-like formatter (o6o56)
;                        BMP background loader (load_bmp_background)
;                        BMP palette conversion & rearrangement
;
;  Lines ~12430-13800  Startup BMP screen engine (ss_* routines)
;                        load_startup_bmp — Pass 1: analyze STYX.BMP
;                        show_startup_screen — Pass 2: render + display loop
;                        Per-scanline V6355D palette reprogramming using
;                        CGA palette flip (dual bank flip-first technique)
;                        in 320×200×4 mode. 4-zone renderer:
;                          Zone 1a (0-47):   flip-first E2-E7 streaming
;                          Zone 1b (48-127):  idle (colors converged)
;                          Zone 2  (128-173): E0 raster bars (animated)
;                          Zone 3  (174-199): idle
;                        Loading experience:
;                          ANSI splash screen (text mode) with C64-style
;                          border color cycling during BMP analysis.
;                          Off-screen rendering to bmp_background buffer
;                          keeps splash visible during Pass 2. Quick mode
;                          switch + REP MOVSW copy (~8ms) for seamless
;                          transition to startup screen.
;                        Bulk buffered file reads:
;                          ss_read_bmp_row reads SS_BULK_ROWS (10) rows
;                          per DOS INT 21h call, reducing 400 calls to 40.
;                        VRAM caching:
;                          DOS-allocated 16K segment caches the rendered
;                          startup screen. After game over, the cached
;                          image is restored instantly without re-reading
;                          STYX.BMP from disk.
;
;  Lines ~13780+       .data section (DATA.ASM)
;                        All game state variables, buffers, sprite data,
;                        lookup tables, character bitmaps, string constants.
;                        Key variables:
;                          p12e     — shadow VRAM buffer (8000 bytes)
;                          p38ca/ce — diamond (safe) positions (x/y arrays)
;                          p3cf8/fa — player position (x, y)
;                          p3doo    — player direction
;                          p74d2    — lives remaining
;                          p74d4    — current level
;                          pbo-pb7  — keyboard arrow-key pressed flags
;                          pco      — sound enabled flag (FFh = on)
;                          pc9      — CGA snow wait skip flag
;                          bmp_loaded/bmp_background — level BMP system
;                          ss_loaded/ss_palette_stream — startup BMP data
;                          ss_vram_cache_seg — DOS segment for cached startup screen
;                          ss_vram_cached — flag: 1 if startup VRAM is cached
;
;============================================================================

; Styx Remastered - NASM conversion for Olivetti Prodest PC1
; Copyright (c) Windmill Software in 1983
; Copyright (c) Andrew Jenner 1998-2004
; Converted from A86 to NASM syntax by Retro Erik, 2026
; Ported to Olivetti Prodest PC1 by Retro Erik, 2026

bits 16
cpu 186                     ; NEC V40 supports 80186 instructions

;--- Startup screen raster bar parameters ---
SS_FLIP_LINES  equ 48        ; Lines of flip-first palette streaming (must be even)
SS_BAR_START   equ 128       ; First scanline of raster bar zone
SS_BAR_END     equ 174       ; First scanline after bar zone
SS_BAR_HEIGHT  equ 14        ; Height of each gradient bar in scanlines
SS_BULK_ROWS   equ 10        ; Rows per DOS read call (bulk buffering)

section .text start=0 vstart=0

;============================================================================
;  STYX1.ASM — Core Engine (video, input, math, enemies, player movement)
;============================================================================

; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

; PUBLIC o172,o17b,o227,o2a9,o2c1,o2e7,o41c,o44b,o4c3,o4f2,o543,o55o,o562,o5c3
; PUBLIC o64o,o6a7,o71d,o793,o82b,o8c1,o9ob,o933,o95b,oa59,oa6e,oa7d,oa89,oab6
; PUBLIC oae7,ob18,ob49,oc43,oc63,oc83,oca3,occf,ocec,od2e,od5a,od7o,od8d,odb7
; PUBLIC odd4,odfe,oeoe,oe1e,oe2e,oe3e,oe4e,oe5e,oe6e,oe7e,oe8e,oe9e,oeae,oebe
; PUBLIC oec9,oecf,oed7,oedd,oee5,oeeb,oef3,oef9,ofoc,of12,of18,ofce
; PUBLIC o1o5o,o1o61,o1o77,o1o9a,o1oc3,o1ofe,o1142,o117f,o11dd,o1227,o135f,o1391
; PUBLIC o17ae,o18bf,o18ec,o1a11,o1add,o1ae5,o1bo9,o1bab,o1dcb,o1def,o1e72,o1f25
; PUBLIC o1f49,o1f6f,o1fa8
; PUBLIC pc1_set_cga_palette,pc1_disable_mode
; PUBLIC _exit,_print,_quiet,volume,int8speed,lmul,ldiv,_setspeedmul,_setmode
; PUBLIC _printhelp,delay1,delay2


;----------------------------------------------------------------------------
; MAIN — Program entry point
; Sets up DS/SS segments to immediately after the code section,
; establishes stack at top of 64KB, copies command-line args to
; a local buffer, then calls o17b which parses args and enters
; the main game function chain.
;----------------------------------------------------------------------------
MAIN:
  CLI
  MOV AX,codeend          ;AX = first byte after code section
  ADD AX,0xf              ;Round up to next paragraph
  SHR AX,4                ;Convert to segment
  MOV BX,CS
  ADD AX,BX               ;DS = CS + code_paragraphs (data segment)
  MOV DS,AX
  MOV SS,AX
  MOV BX,0x1000           ;64KB
  SUB BX,AX               ;Space remaining
  TEST BX,0xf000          ;Check overflow
  MOV BX,0xfff0           ;SP at top of 64KB
  MOV SP,BX
  STI

  ; Shrink DOS memory block so we can allocate VRAM cache segment.
  ; At entry ES = PSP segment. Resize to: DS + 0x1000 - ES paragraphs.
  PUSH ES                 ; Save PSP segment for later
  MOV BX,DS
  ADD BX,0x1000           ; End of 64K data segment (paragraph)
  MOV AX,ES
  SUB BX,AX               ; BX = total paragraphs from PSP to end of DS
  MOV AH,0x4A             ; DOS resize memory block (ES already = PSP)
  INT 0x21

  ; Allocate 1024 paragraphs (16384 bytes) for VRAM cache
  MOV word [ss_vram_cache_seg],0
  MOV BX,1024             ; 16K (enough for 16192-byte CGA buffer)
  MOV AH,0x48             ; DOS allocate memory
  INT 0x21
  JC .no_cache            ; If alloc fails, cache stays 0
  MOV [ss_vram_cache_seg],AX
.no_cache:
  POP ES                  ; Restore ES = PSP (needed by existing code below)

  MOV BX,0xfff0           ; Restore BX for [p] assignment
  MOV word [p],BX
  MOV AX,p763o
  MOV word [p2],AX
  PUSH ES
  XOR AX,AX
  PUSH AX
  MOV BP,SP
  MOV SI,0x80
  MOV CL,0
  INC SI
  XOR CH,CH
  MOV BX,CX
  ADD BX,4
  AND BX,0xfffe
  SUB SP,BX
  MOV DI,SP
  MOV byte [DI],0x63
  INC DI
  JCXZ o161
  MOV byte [DI],0x20
  INC DI
o159:
  MOV AL,0x20
  MOV byte [DI],AL
  INC SI
  INC DI
  LOOP o159
o161:
  XOR AX,AX
  MOV byte [DI],AL
  MOV AX,DS
  MOV ES,AX
  MOV AX,SP
  PUSH AX
  CALL o17b
  MOV SP,BP
  RETF

o172:
  MOV AX,word [p]
  SUB AX,4
  MOV SP,AX
  RETF

;----------------------------------------------------------------------------
; o17b — Post-init dispatcher
; Parses command line, calibrates CPU speed, then parses the
; already-split argv[] array (at [BP+8]) following C-style calling
; convention. Eventually calls into the main game entry (o556a).
;----------------------------------------------------------------------------
o17b:
  CALL cmdline            ;Parse /S /Q command-line switches
  CALL calibrate          ;Measure CPU speed → volume (KIPS value)
  PUSH BP
  SUB SP,4
  MOV BP,SP
o181:
  MOV SI,word [BP+8]
  MOV AL,byte [SI]
  XOR AH,AH
  INC AX
  MOV DI,AX
  MOV AL,byte [DI+p751c]
  XOR AH,AH
  AND AX,8
  JZ o19b
  INC word [BP+8]
  JMP o181
o19b:
  MOV SI,word [BP+8]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  JZ o2od
  CMP word [p4],0x20
  JGE o2od
  MOV AX,word [p4]
  INC word [p4]
  SHL AX,1
  MOV DI,AX
  MOV AX,SI
  MOV word [DI+6],AX
o1be:
  MOV SI,word [BP+8]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  MOV word [BP],AX
  JZ o1df
  INC AX
  MOV DI,AX
  MOV AL,byte [DI+p751c]
  XOR AH,AH
  AND AX,8
  JNZ o1df
  INC word [BP+8]
  JMP o1be
o1df:
  MOV SI,word [BP+8]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  JZ o2od
  MOV SI,word [BP+8]
  INC word [BP+8]
  MOV byte [SI],0
o1f3:
  MOV SI,word [BP+8]
  MOV AL,byte [SI]
  XOR AH,AH
  INC AX
  MOV DI,AX
  MOV AL,byte [DI+p751c]
  XOR AH,AH
  AND AX,8
  JZ o19b
  INC word [BP+8]
  JMP o1f3
o2od:
  MOV AX,6
  PUSH AX
  PUSH word [p4]
  CALL o556a
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  CALL o5ac5
  MOV SP,BP
  ADD SP,4
  POP BP
  RET

o227:
  PUSH BP
  SUB SP,0xa
  MOV BP,SP
  XOR AX,AX
  OUT 0x43,AL
  IN AL,0x40
  MOV BL,AL
  MOV word [BP],AX
  IN AL,0x40
  MOV BH,AL
  MOV word [BP+4],BX
  MOV AL,0x40
  OUT 0x43,AL
  IN AL,0x41    ;RAM refresh counter?
  MOV BL,AL
  IN AL,0x41
  MOV BH,AL
  MOV AX,word [BP+4]
  IMUL BX
  MOV CL,8
  SAR AX,CL
  AND AX,0xff
  MOV CX,word [BP+0xe]
  INC CX
  MOV word [BP+8],AX
  IMUL CX
  MOV word [BP+0xe],CX
  MOV CL,8
  SAR AX,CL
  MOV word [BP+6],BX
  ADD SP,0xa
  POP BP
  RET

;----------------------------------------------------------------------------
; o2a9 — Absolute value
; Input: word on stack    Output: AX = |input|
;----------------------------------------------------------------------------
o2a9:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  TEST AX,AX
  JNS o2b9
  NEG word [BP+6]
o2b9:
  MOV AX,word [BP+6]
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o2c1 — Cosine (calls sine with +90° offset)
; Input: angle on stack (degrees)   Output: AX = cos(angle) scaled 0-100
;----------------------------------------------------------------------------
o2c1:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  ADD AX,0x5a
  CMP AX,0x168
  MOV word [BP+6],AX
  JL o2da
  SUB word [BP+6],0x168
o2da:
  PUSH word [BP+6]
  CALL o2e7
  MOV SP,BP
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o2e7 — Sine function
; Input: angle on stack (degrees, 0-359)   Output: AX = sin(angle) scaled
; Uses a 10-entry lookup table (o3fo) for 0-90° range, mirrors for
; other quadrants via the dispatch table at o343.
;----------------------------------------------------------------------------
o2e7:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  MOV AX,word [BP+0xc]
  MOV BX,0x5a              ;90 degrees
  CWD
  IDIV BX                  ;AX = quadrant (0-3), DX = angle within quadrant
  JMP o34b
o2f8:
  MOV AX,word [BP+0xc]
  MOV word [BP+6],1
  MOV word [BP+4],AX
  JMP o35b
o3o5:
  MOV AX,0xb4
  SUB AX,word [BP+0xc]
  MOV word [BP+6],1
  MOV word [BP+4],AX
  JMP o35b
o315:
  MOV AX,word [BP+0xc]
  SUB AX,0xb4
  MOV word [BP+6],-1
  MOV word [BP+4],AX
  JMP o35b
o325:
  MOV AX,0x168
  SUB AX,word [BP+0xc]
  MOV word [BP+6],-1
  MOV word [BP+4],AX
  JMP o35b
o335:
  PUSH word [BP+0xc]
  MOV AX,p46
  PUSH AX
  CALL o6o56
  MOV SP,BP
  JMP o35b

o343:
  DW o2f8,o3o5,o315,o325

o34b:
  MOV SI,AX
  CMP SI,4
  JNB o359
  SHL SI,1
  JMP word [cs:SI+o343]
o359:
  JMP o335
o35b:
  MOV AX,word [BP+4]
  MOV BX,0xa
  CWD
  IDIV BX
  MOV SI,AX
  CMP SI,0xa
  JNB o3e5
  SHL SI,1
  MOV BX,word [cs:SI+o3fo]
  MOV AX,word [BP+6]
  IMUL BX
o414:
  ADD SP,8
  POP BP
  RET
o3e5:
  MOV AX,0x5e
  PUSH AX
  CALL o6o56
  MOV SP,BP
  MOV AX,word [BP+2]
  JMP o414

o3fo:
  DW 0,0x11,0x22,0x31,0x40,0x4c,0x56,0x5d,0x62,0x64

;----------------------------------------------------------------------------
; o41c — Delay loop (variable count)
; Input: count on stack   Uses 'volume' (calibrated KIPS) for timing
; Each iteration burns cycles proportional to CPU speed.
;----------------------------------------------------------------------------
o41c:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  PUSH AX
  PUSH DX
  PUSH CX
  MOV word [BP+2],0
o427:
  MOV AX,word [BP+2]
  CMP AX,word [BP+0xa]
  JGE o444
  MOV AX,word [cs:volume]
  MOV DX,word [cs:volume+2]
  MOV CX,10
o434:
  LOOP o434
  MOV CX,10
  SUB AX,1
  SBB DX,0
  JC o43f
  JMP o434
o43f:
  INC word [BP+2]
  JMP o427
o444:
  POP CX
  POP DX
  POP AX
  ADD SP,6
  POP BP
  RET

delay1:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  PUSH AX
  PUSH DX
  PUSH CX
  MOV AX,word [cs:volume]
  MOV DX,word [cs:volume+2]
  MOV CX,1
o434x1:
  LOOP o434x1
  MOV CX,1
  SUB AX,1
  SBB DX,0
  JNC o434x1
  POP CX
  POP DX
  POP AX
  ADD SP,6
  POP BP
  RET

delay2:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  PUSH AX
  PUSH DX
  PUSH CX
  MOV AX,word [cs:volume]
  MOV DX,word [cs:volume+2]
  MOV CX,2
o434x2:
  LOOP o434x2
  MOV CX,2
  SUB AX,1
  SBB DX,0
  JNC o434x2
  POP CX
  POP DX
  POP AX
  ADD SP,6
  POP BP
  RET


;--- Speed calibration data ---
speed0:
  DW 291              ;Reference KIPS value for speed normalization
_speedmul:
  DW 100              ;Speed multiplier (set by /S:nn switch)
_mode:
  DW 0                ;Video mode: 0=auto, 1=CGA, 2=VGA (PC1 always 1)

volume:
  DW 0,0              ;Calibrated speed value (32-bit KIPS×speedmul/speed0)

;----------------------------------------------------------------------------
; lmul — 32-bit multiply:  DX:AX = DX:AX × CX:BX
;----------------------------------------------------------------------------
lmul:       ;DXAX = DXAX * CXBX
  PUSH SI
  XCHG SI,AX
  XCHG DX,AX
  TEST AX,AX
  JZ m1
  MUL BX
m1:
  XCHG CX,AX
  TEST AX,AX
  JZ m2
  MUL SI
  ADD CX,AX
m2:
  XCHG SI,AX
  MUL BX
  ADD DX,CX
  POP SI
  RET

;----------------------------------------------------------------------------
; ldiv — 32-bit divide:  DX:AX = DX:AX ÷ CX:BX
;----------------------------------------------------------------------------
ldiv:       ;DXAX = DXAX / CXBX
  PUSH BP
  PUSH SI
  PUSH DI
  MOV BP,SP
  XOR DI,DI ;Or 1 or ludiv, 2 for lmod, 3 for lumod
  OR CX,CX
  JNZ d1
  OR DX,DX
  JZ d9
  OR BX,BX
  JZ d9
d1:
  TEST DI,1
  JNZ d3
  OR DX,DX
  JNS d2
  NEG DX
  NEG AX
  SBB DX,0
  OR DI,0xc
d2:
  OR CX,CX
  JNS d3
  NEG CX
  NEG BX
  SBB CX,0
  XOR DI,4
d3:
  MOV BP,CX
  MOV CX,0x20
  PUSH DI
  XOR DI,DI
  XOR SI,SI
d4:
  SHL AX,1
  RCL DX,1
  RCL SI,1
  RCL DI,1
  CMP DI,BP
  JB d6
  JA d5
  CMP SI,BX
  JB d6
d5:
  SUB SI,BX
  SBB DI,BP
  INC AX
d6:
  LOOP d4
  POP BX
  TEST BX,2
  JZ d7
  MOV AX,SI
  MOV DX,DI
  SHR BX,1
d7:
  TEST BX,4
  JZ d8
  NEG DX
  NEG AX
  SBB DX,0
d8:
  POP DI
  POP SI
  POP BP
  RET
d9:
  DIV BX
  TEST DI,2
  JZ d0
  MOV AX,DX
d0:
  XOR DX,DX
  JMP d8

;----------------------------------------------------------------------------
; calibrate — Measure CPU speed and compute game timing constant
; Calls getkips to measure iterations per BIOS tick, then:
;   volume = (KIPS × _speedmul) / speed0
; This value is used by all delay loops (o41c, delay1, delay2)
; to keep game speed consistent across different CPUs.
;----------------------------------------------------------------------------
calibrate:
  CALL getkips ;Now we have the computer KIPS speed in DX:AX
  MOV BX,word [cs:_speedmul]
  XOR CX,CX
  CALL lmul
  MOV BX,word [cs:speed0]
  XOR CX,CX
  CALL ldiv
  CMP AX,0
  JNE savevol
  CMP DX,0
  JNE savevol
  INC AX
savevol:
  MOV word [cs:volume],AX
  MOV word [cs:volume+2],DX
  RET

cmdline:
  PUSH ES
  PUSH BP
  MOV AX,CS
  SUB AX,0x10
  PUSH AX
  MOV AX,0x81
  PUSH AX
  CALL _parsecmd
  POP AX
  POP AX
  POP BP
  POP ES
  RET

;----------------------------------------------------------------------------
; getkips — Measure CPU speed in kilo-instructions per BIOS tick
; Waits for a BIOS timer tick (18.2 Hz at 0040:006C), then counts
; how many calls to timekips fit in one tick. Returns DX:AX = count.
;----------------------------------------------------------------------------
getkips:
  PUSH ES
  MOV AX,0x40
  MOV ES,AX
  XOR AX,AX
  XOR DX,DX
  MOV SI,word [es:0x6c]
zerotime:
  CMP SI,word [es:0x6c]
  JZ zerotime
  MOV SI,word [es:0x6c]
getkloop:
  CALL timekips
  CMP SI,word [es:0x6c]
  JNZ donetime
  INC AX
  JNZ getkloop
  INC DX
  JMP getkloop
donetime:
  POP ES
  RET

timekips:
  PUSH AX
  PUSH DX
  PUSH SI
  MOV BX,0
  MOV SI,0
  DW 0xa0f7,0
  DW 0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0
  DW 0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0
  DW 0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0
  DW 0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0,0x9801,0
  DW 0x9801,0,0x9801,0,0x9801,0,0x9801,0
  POP SI
  POP DX
  POP AX
  RET

o449:
  DW 0

;----------------------------------------------------------------------------
; o44b — CGA mode setup (not used on PC1, but kept for compatibility)
; Programs CGA CRTC registers directly, sets 320×200×4 mode via INT 10h.
; On PC1 we skip this and use o543 for hidden 16-color mode instead.
;----------------------------------------------------------------------------
o44b:
  PUSH BP
  MOV BP,SP
  MOV DX,0x3d8
  MOV AL,2           ;320x200 mode (disabled)
  OUT DX,AL
  MOV SI,p87  ;CGA registers
  MOV CX,0x10         ;16 of them
  MOV BL,0           ;This one first
o47a:
  MOV DX,0x3d4
  MOV AL,BL
  OUT DX,AL          ;Index register
  MOV DX,0x3d5
  MOV AL,byte [SI]
  OUT DX,AL          ;Output value (screws up VGA CRTC controller)
  INC SI
  INC BL
  LOOP o47a
  MOV DX,0x3d9
  MOV AL,0
  OUT DX,AL          ;Background 0
  INC DX             ;This wasn't here before - believed to be in error
o491:
  IN AL,DX
  TEST AL,8          ;Retrace
  JZ o491
  MOV DX,0x3d8
  MOV AL,0xa
  OUT DX,AL          ;Enable graphics
  PUSH DS
  MOV AX,0
  MOV DS,AX
  MOV AL,byte [0x410]     ;Equipment
  AND AL,0xcf
  OR AL,0x10
  MOV byte [0x410],AL     ;Initial video mode=1
  POP DS
  MOV AX,4
  INT 0x10            ;Set video mode to 320x200x4
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV BH,1
  MOV AH,0xb
  INT 0x10            ;Set palette value to argument (only 0 used)
  XOR BX,BX
  INT 0x10
  MOV AX,0xff         ;Success result
  POP BP
  RET

vgasave:
  DB 0

o4c3:
  PUSH DS
  MOV AX,0x40
  MOV DS,AX
  MOV AL,byte [0x89]
  POP DS
  MOV byte [cs:vgasave],AL
  MOV word [cs:_mode],1    ;PC1: always CGA mode
  RET

nonefound:
  MOV AX,errormsg
  PUSH AX
  CALL _print
  POP AX
_exit:
  MOV AX,0x4c01
  INT 0x21

_setmode:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [cs:_mode],AX
  POP BP
  RET

_setspeedmul:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [cs:_speedmul],AX
  POP BP
  RET

helpmsg:
  DB "STYX - Copyright (c) 1983 Windmill software",10,13
  DB "Restored 1998 by AJ Software",10,13
  DB "NASM conversion & PC1 port: Retro Erik, 2026",10,13,10,13
  DB "Command line syntax:",10,13
  DB "  STYX [[/S:]speed] [/Q] [/N]",10,13,10,13
  DB "/Q = Quiet mode (no sound at all)",10,13
  DB "/N = No images (use solid colors)",10,13,"$"

errormsg:
  DB "Olivetti PC1 required.",10,13,"$"

_printhelp:
  MOV AX,helpmsg
  PUSH AX
  CALL _print
  POP AX
  RET

_print:
  PUSH BP
  PUSH DS
  MOV BP,SP
  MOV AH,9
  MOV DX,word [BP+6]
  PUSH CS
  POP DS
  INT 0x21
  POP DS
  POP BP
  RET

_quiet:
  MOV word [pco],0
  RET

o4f2:
  PUSH BP
  MOV BP,SP
  MOV DX,0x201
  MOV word [es:pd9],0
  MOV word [es:pdb],0
  IN AL,DX
  TEST AL,0x10
  JNZ o512
  MOV word [es:pd9],0xff
o512:
  TEST AL,0x20
  JNZ o51d
  MOV word [es:pdb],0xff
o51d:
  MOV BX,0
  MOV CX,0
  MOV AH,0
  OUT DX,AL
o526:
  IN AL,DX
  RCR AL,1
  ADC BL,AH
  RCR AL,1
  ADC CL,AH
  RCR AL,1
  INC CH
  JNZ o526
  MOV CH,0
  MOV word [es:pd5],BX
  MOV word [es:pd7],CX
  POP BP
  RET

o543:      ;Set up PC1 hidden 160x200x16 mode
; NOTE: This routine calls pc1_set_cga_palette and clears VRAM.
; Callers do NOT need to reset the palette before calling o543.
; Video is ON after this returns (port D8h = 4Ah).
  PUSH BP
  MOV BP,SP
  ;--- Enable hidden graphics mode on V6355D ---
  ; Unlock 16-color mode via mode control port
  MOV AL,0x4a            ;Graphics mode, video ON
  OUT 0xd8,AL
  JMP SHORT $+2
  ; Border defaults to black (color 0) — no need to set
  ; Set CGA palette
  CALL pc1_set_cga_palette
  ; Clear VRAM at B000h (16KB = 8192 words)
  PUSH ES
  MOV AX,0xb000
  MOV ES,AX
  XOR DI,DI
  MOV CX,0x4000         ;16384 bytes
  XOR AL,AL
  REP STOSB
  POP ES
  POP BP
  RET

;--- PC1 palette programming routines ---
; V6355D palette I/O summary:
;   Port D8h: Mode control (02h=video off, 0Ah=CGA video on, 4Ah=hidden mode on)
;   Port D9h: Palette flip register (bit 5 selects which palette bank is active;
;             toggling this during HBLANK gives per-scanline color switching)
;   Port DAh: Status register (bit 0=display active, bit 3=VSYNC)
;   Port DDh: Palette bank control (40h=open for write, 44h=open at entry 2,
;             80h=close)
;   Port DEh: Palette data (sequential writes: R byte then GB byte per entry)
;
; IMPORTANT: INT 10h mode set resets the V6355D palette to BIOS defaults.
; Always program custom palette AFTER calling INT 10h, not before.
; Also: changing palette while video is ON shows a brief flash of the old
; colors. For clean transitions, disable video first (OUT D8h, 02h), then
; change palette, then re-enable video.
pc1_set_cga_palette:
  ; Always write CGA palette to hardware.
  ; Reads palette from code segment to avoid DS dependency.
  PUSH AX
  PUSH CX
  PUSH SI
  CLI                    ;Disable interrupts during palette writes
  MOV AL,0x40             ;Open palette for writing
  OUT 0xdd,AL
  JMP SHORT $+2
  MOV SI,cs_cga_colors
  MOV CX,0x20            ;32 bytes (16 colors x 2)
pc1_pal_loop:
  MOV AL,byte [cs:SI]     ;Read from code segment
  OUT 0xde,AL             ;Write palette byte
  JMP SHORT $+2
  INC SI
  LOOP pc1_pal_loop
  MOV AL,0x80             ;Close palette
  OUT 0xdd,AL
  STI                    ;Re-enable interrupts
  POP SI
  POP CX
  POP AX
  RET

;--- CGA palette in code segment (DS-independent) ---
cs_cga_colors:
  DB 0x0,0x0    ;0:  Black
  DB 0x0,0x5    ;1:  Blue
  DB 0x0,0x50   ;2:  Green
  DB 0x0,0x55   ;3:  Cyan
  DB 0x5,0x0    ;4:  Red
  DB 0x5,0x5    ;5:  Magenta
  DB 0x5,0x20   ;6:  Brown
  DB 0x5,0x55   ;7:  Light Gray
  DB 0x2,0x22   ;8:  Dark Gray
  DB 0x2,0x27   ;9:  Light Blue
  DB 0x2,0x72   ;10: Light Green
  DB 0x2,0x77   ;11: Light Cyan
  DB 0x7,0x22   ;12: Light Red
  DB 0x7,0x27   ;13: Light Magenta
  DB 0x7,0x70   ;14: Yellow
  DB 0x7,0x77   ;15: White

;--- PC1 hidden mode disable (for exit) ---
pc1_disable_mode:
  MOV AL,0x65
  OUT 0xdd,AL
  JMP SHORT $+2
  MOV AL,0x9
  OUT 0xde,AL
  JMP SHORT $+2
  MOV AL,0x28             ;Text mode
  OUT 0xd8,AL
  JMP SHORT $+2
  RET

  ; VGA code path removed - PC1 only
chartable:
  DB 0,0,126,129,126,255,108,254,16,56,56,124,16,56,0,0,255,255,0,60
  DB 255,195,15,7,60,102,63,51,127,99,24,219,128,224,2,14,24,60,102,102
  DB 127,219,62,97,0,0,24,60,24,60,24,24,0,24,0,48,0,0,0,36
  DB 0,24,0,255,0,0,24,60,102,102,108,108,24,62,0,198,56,108,24,24
  DB 12,24,48,24,0,102,0,24,0,0,0,0,0,0,6,12,56,108,24,56
  DB 124,198,124,198,28,60,254,192,56,96,254,198,124,198,124,198,0,24,0,24
  DB 6,12,0,0,96,48,124,198,124,198,56,108,252,102,60,102,248,108,254,98
  DB 254,98,60,102,198,198,60,24,30,12,230,102,240,96,198,238,198,230,124,198
  DB 252,102,124,198,252,102,60,102,126,126,198,198,198,198,198,198,198,198,102,102
  DB 254,198,60,48,192,96,60,12,16,56,0,0,48,24,0,0,224,96,0,0
  DB 28,12,0,0,60,102,0,0,224,96,24,0,6,0,224,96,56,24,0,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,48,48,0,0,0,0,0,0
  DB 0,0,0,0,0,0,14,24,24,24,112,24,118,220,0,16,124,198,204,0
  DB 12,24,124,130,198,0,48,24,48,48,0,0,124,130,198,0,48,24,102,0
  DB 124,130,48,24,198,56,56,108,24,48,0,0,62,108,124,130,198,0,48,24
  DB 120,132,96,48,198,0,198,56,198,0,24,24,56,108,102,102,248,204,14,27
  DB 24,48,12,24,12,24,24,48,118,220,118,220,60,108,56,108,24,0,0,0
  DB 0,0,99,230,99,230,24,0,0,51,0,204,34,136,85,170,119,221,24,24
  DB 24,24,24,24,54,54,0,0,0,0,54,54,54,54,0,0,54,54,54,54
  DB 24,24,0,0,24,24,24,24,0,0,24,24,0,0,24,24,24,24,54,54
  DB 54,54,0,0,54,54,0,0,54,54,0,0,54,54,24,24,54,54,0,0
  DB 0,0,54,54,24,24,0,0,0,0,54,54,24,24,24,24,0,0,255,255
  DB 0,0,240,240,15,15,255,255,0,0,120,204,254,198,0,0,254,198,0,0
  DB 0,0,0,118,126,24,56,108,56,108,14,24,0,0,6,12,30,48,0,124
  DB 0,254,24,24,48,24,12,24,14,27,24,24,0,24,0,118,56,108,0,0
  DB 0,0,15,12,108,54,120,12,0,0,0,0

;----------------------------------------------------------------------------
; o5c3 — Screen refresh (PC1 hidden mode)
; Copies shadow buffer (p12e, 8000 bytes) to both VRAM banks.
;
; Fast path (no BMP): memcpy shadow → bank0, memcpy shadow → bank1
;
; BMP reveal path: for each byte, checks both nibbles. If a pixel
; has color 1-6 (territory claim colors), substitutes the
; corresponding pixel from bmp_background to reveal the image.
; Non-territory colors (0=background, 7=border, 12=trail, 15=text)
; are written unchanged.
;
; VRAM layout: B000:0000 = even scanlines, B000:2000 = odd scanlines
; Each bank: 100 rows × 80 bytes = 8000 bytes
;----------------------------------------------------------------------------
o5c3:         ;Redraw screen (PC1 hidden mode — with BMP background reveal)
  PUSH BP
  MOV BP,SP
  PUSH ES
  MOV AX,0xb000
  MOV ES,AX

  ; If no BMP loaded, use fast original code path
  CMP byte [bmp_loaded],0
  JNZ .bmp_reveal

  ; --- Fast path: no BMP loaded, original double-draw ---
  MOV SI,p12e
  XOR DI,DI
  MOV CX,4000
  REP MOVSW
  MOV SI,p12e
  MOV DI,0x2000
  MOV CX,4000
  REP MOVSW
  JMP .o5c3_done

.bmp_reveal:
  ; --- BMP reveal path ---
  ; For each shadow byte, check both nibbles. If a nibble's color
  ; is in the range 1-6 (territory colors), substitute the
  ; corresponding BMP background pixel to reveal the image.
  ;
  ; Territory colors: 1 (blue round), 2 (green round), 4 (red round)
  ; Colors 0,7,8,12,15 are game elements and never revealed.
  ;
  ; DS = data segment, ES = B000h (VRAM)

  ; === Even bank: shadow → B000:0000, substitute from bmp_background ===
  MOV SI,p12e
  MOV BX,bmp_background
  XOR DI,DI
  MOV CX,8000
.even_loop:
  LODSB                  ;AL = shadow byte from DS:SI
  ; --- Check high nibble: is it territory (color 1-6)? ---
  MOV AH,AL
  AND AH,0xF0
  CMP AH,0x10            ;high nib >= 1?
  JB .keep_hi_e
  CMP AH,0x60            ;high nib <= 6?
  JA .keep_hi_e
  ; Reveal: replace high nibble with BMP pixel
  MOV AH,byte [BX]
  AND AH,0xF0
  AND AL,0x0F
  OR AL,AH
.keep_hi_e:
  ; --- Check low nibble: is it territory (color 1-6)? ---
  MOV AH,AL
  AND AH,0x0F
  DEC AH                 ;color-1; colors 1-6 become 0-5
  CMP AH,6
  JAE .keep_lo_e
  ; Reveal: replace low nibble with BMP pixel
  AND AL,0xF0
  MOV AH,byte [BX]
  AND AH,0x0F
  OR AL,AH
.keep_lo_e:
  STOSB                  ;Write to ES:DI (VRAM even bank)
  INC BX
  LOOP .even_loop

  ; === Odd bank: shadow → B000:2000, substitute from bmp_background+8000 ===
  MOV SI,p12e
  MOV BX,bmp_background+8000
  MOV DI,0x2000
  MOV CX,8000
.odd_loop:
  LODSB
  MOV AH,AL
  AND AH,0xF0
  CMP AH,0x10
  JB .keep_hi_o
  CMP AH,0x60
  JA .keep_hi_o
  MOV AH,byte [BX]
  AND AH,0xF0
  AND AL,0x0F
  OR AL,AH
.keep_hi_o:
  MOV AH,AL
  AND AH,0x0F
  DEC AH
  CMP AH,6
  JAE .keep_lo_o
  AND AL,0xF0
  MOV AH,byte [BX]
  AND AH,0x0F
  OR AL,AH
.keep_lo_o:
  STOSB
  INC BX
  LOOP .odd_loop

.o5c3_done:
  POP ES
  POP BP
  RET

o64o:
  PUSH BP
  MOV BP,SP
  MOV BX,word [BP+4]
  AND BX,0xf
  MOV BH,BL
  SHL BH,4
  MOV CX,0x56
  MOV DI,p12e
  ADD DI,0x371
o65a:
  MOV word [es:pc7],0
o661:
  MOV AL,byte [DI]
  MOV AH,AL
  AND AL,0xf
  CMP AL,8
  JZ o678
  TEST AL,8
  JNZ o673
  AND AL,0xf
  JNZ o678
o673:
  AND AH,0xf0
  OR AH,BL
o678:
  MOV AL,AH
  AND AH,0xf0
  CMP AH,0x80
  JZ o69o
  TEST AH,0x80
  JNZ o68c
  AND AH,0xf0
  JNZ o69o
o68c:
  AND AL,0xf
  OR AL,BH
o69o:
  MOV byte [DI],AL
  INC DI
  INC word [es:pc7]
  CMP word [es:pc7],0x4e
  JB o661
  ADD DI,2
  LOOP o65a
  POP BP
  RET

o6a7:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV word [pcd],AX
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV AX,word [BP+8]
  AND AL,0xf
  MOV CH,AL
  MOV CL,CH
  ROL CH,1
  ROL CH,1
  ROL CH,1
  ROL CH,1
  MOV AX,word [BP+0xa]
  MOV word [pcf],AX
  CALL oa59
  JZ o6d6
  JMP o717
o6d6:
  CALL oa6e
  ADD DI,p12e
  TEST AX,1
  JNZ o6fc
o6e4:
  MOV AL,byte [DI]
  AND AL,0xf0
  CMP AL,CH
  JNZ o717
  MOV AX,word [es:pcf]
  CMP word [es:pcd],AX
  JNB o717
  INC word [es:pcd]
o6fc:
  MOV AL,byte [DI]
  AND AL,0xf
  CMP AL,CL
  JNZ o717
  MOV AX,word [es:pcf]
  CMP word [es:pcd],AX
  JNB o717
  INC word [es:pcd]
  INC DI
  JMP o6e4
o717:
  MOV AX,word [es:pcd]
  POP BP
  RET

o71d:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV word [pcd],AX
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV AX,word [BP+8]
  AND AL,0xf
  MOV CH,AL
  MOV CL,CH
  ROL CH,1
  ROL CH,1
  ROL CH,1
  ROL CH,1
  MOV AX,word [BP+0xa]
  MOV word [pcf],AX
  CALL oa59
  JZ o74c
  JMP o78d
o74c:
  CALL oa6e
  ADD DI,p12e
  TEST AX,1
  JNZ o772
o75a:
  MOV AL,byte [DI]
  AND AL,0xf0
  CMP AL,CH
  JZ o78d
  MOV AX,word [es:pcf]
  CMP word [es:pcd],AX
  JNB o78d
  INC word [es:pcd]
o772:
  MOV AL,byte [DI]
  AND AL,0xf
  CMP AL,CL
  JZ o78d
  MOV AX,word [es:pcf]
  CMP word [es:pcd],AX
  JNB o78d
  INC word [es:pcd]
  INC DI
  JMP o75a
o78d:
  MOV AX,word [es:pcd]
  POP BP
  RET

o793:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV word [pcd],AX
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV AX,word [BP+8]
  AND AL,0xf
  MOV CH,AL
  MOV CL,CH
  ROL CH,1
  ROL CH,1
  ROL CH,1
  ROL CH,1
  CALL oa59
  JZ o7bc
  JMP o825
o7bc:
  CALL oa6e
  ADD DI,p12e
  TEST AX,1
  JNZ o7f6
o7ca:
  MOV AL,byte [DI]
  MOV AH,AL
  AND AL,0xf0
  CMP AL,0x70
  JZ o825
  CMP AL,0x80
  JZ o825
  CMP AL,CH
  JZ o825
  CMP word [es:pcd],0xa0
  JNB o825
  INC word [es:pcd]
  INC word [es:pd1]
  AND AH,0xf
  OR AH,CH
  MOV byte [DI],AH
o7f6:
  MOV AL,byte [DI]
  MOV AH,AL
  AND AL,0xf
  CMP AL,7
  JZ o825
  CMP AL,8
  JZ o825
  CMP AL,CL
  JZ o825
  CMP word [es:pcd],0xa0
  JNB o825
  INC word [es:pcd]
  INC word [es:pd1]
  AND AH,0xf0
  OR AH,CL
  MOV byte [DI],AH
  INC DI
  JMP o7ca
o825:
  MOV AX,word [es:pcd]
  POP BP
  RET

o82b:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV word [pcd],AX
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV AX,word [BP+8]
  AND AL,0xf
  MOV CH,AL
  MOV CL,CH
  ROL CH,1
  ROL CH,1
  ROL CH,1
  ROL CH,1
  CALL oa59
  JZ o854
  JMP o8bb
o854:
  CALL oa6e
  ADD DI,p12e
  TEST AX,1
  JZ o88d
o862:
  MOV AL,byte [DI]
  MOV AH,AL
  AND AL,0xf
  CMP AL,7
  JZ o8bb
  CMP AL,8
  JZ o8bb
  CMP AL,CL
  JZ o8bb
  CMP word [es:pcd],0
  JB o8bb
  INC word [es:pd1]
  DEC word [es:pcd]
  AND AH,0xf0
  OR AH,CL
  MOV byte [DI],AH
o88d:
  MOV AL,byte [DI]
  MOV AH,AL
  AND AL,0xf0
  CMP AL,0x70
  JZ o8bb
  CMP AL,0x80
  JZ o8bb
  CMP AL,CH
  JZ o8bb
  CMP word [es:pcd],0
  JB o8bb
  INC word [es:pd1]
  DEC word [es:pcd]
  AND AH,0xf
  OR AH,CH
  MOV byte [DI],AH
  DEC DI
  JMP o862
o8bb:
  MOV AX,word [es:pcd]
  POP BP
  RET

o8c1:         ;Clear screen to colour (PC1 hidden mode)
  PUSH BP
  MOV BP,SP
  MOV BX,word [BP+4]
  AND BX,0xf
  MOV BH,BL
  SHL BH,4
  OR BL,BH        ;BL = color in both nibbles
  ; Wait for VBlank
  MOV DX,0xda
o8e5:
  IN AL,DX
  TEST AL,8
  JZ o8e5
  ; Clear shadow buffer (8000 bytes) using word fill
  MOV DI,p12e
  MOV AL,BL
  MOV AH,BL
  MOV CX,4000
  REP STOSW
  ; Clear VRAM at B000h (both banks, 16384 bytes total)
  PUSH ES
  MOV AX,0xb000
  MOV ES,AX
  XOR DI,DI
  MOV AL,BL
  MOV AH,BL
  MOV CX,0x2000     ;8192 words = 16384 bytes
  REP STOSW
  POP ES
  ; Wait for VBlank after clear
  MOV DX,0xda
o8fd:
  IN AL,DX
  TEST AL,8
  JZ o8fd
  POP BP
  RET

o9ob:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV AX,word [BP+8]
  AND AL,0xf
  MOV CH,AL
  MOV BP,0
  MOV SI,0
  PUSH DS
  MOV AX,0xb000
  MOV DS,AX
  CALL o95b
  MOV AX,SI
  POP DS
  POP BP
  RET

o933:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV AX,word [BP+8]
  AND AL,0xf
  MOV CH,AL
  MOV BP,1
  MOV SI,0
  PUSH DS
  MOV AX,0xb000
  MOV DS,AX
  CALL o95b
  MOV AX,SI
  POP DS
  POP BP
  RET

o95b:
  CALL oa59
  JZ o961
  RET
o961:
  CMP BP,0
  JNZ o969
  JMP o984
o969:
  CMP BP,1
  JNZ o971
  JMP o984
o971:
  CMP BP,2
  JNZ o979
  JMP o9d9
o979:
  CMP BP,3
  JNZ o984
  JMP oao7
o984:
  CALL oa6e
  TEST AX,1
  JZ o9b4
  CALL oa7d
  PUSH AX
  AND AL,0xf
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  POP AX
  CMP BP,1
  JZ o9a9
  AND AL,0xf0
  OR AL,CH
  CALL oa89
  RET
o9a9:
  XOR AL,CH
  CMP CH,0
  JZ o9b3
  CALL oa89
o9b3:
  RET
o9b4:
  CALL oa7d
  PUSH AX
  AND AL,0xf0
  SHR AL,4
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  SHL CH,4
  POP AX
  CMP BP,1
  JZ o9a9
  AND AL,0xf
  OR AL,CH
  CALL oa89
  RET
o9d9:           ;Direct VRAM write (BP=2): write CH byte to VRAM + shadow
  CALL oa6e
  MOV DX,0xda
  CMP word [es:pc9],0
  JNZ o9f9
  CMP word [es:pcb],0
  JZ o9fb
o9ef:
  IN AL,DX
  TEST AL,1
  JNZ o9ef
o9f4:
  IN AL,DX
  TEST AL,1
  JZ o9f4
o9f9:
  CMP byte [ES:bmp_loaded],0
  JZ .o9_no_bmp
  MOV AH,CH
  CALL bmp_vram_write       ;Write BMP-substituted value to even+odd VRAM
  JMP o9fb
.o9_no_bmp:
  MOV byte [DI],CH          ;Write even row (bank 0)
  PUSH DI
  ADD DI,0x2000
  MOV byte [DI],CH          ;Write odd row (bank 1) — double-draw
  POP DI
o9fb:
  PUSH DI
  ADD DI,p12e
  MOV byte [es:DI],CH      ;Write shadow buffer (always game state)
  POP DI
  RET
oao7:
  CALL oa6e
  TEST AX,1
  JZ oa3o
  CALL oa7d
  PUSH AX
  AND AL,0xf
  MOV byte [es:pc6],AL
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  POP AX
  AND AL,0xf0
  CMP byte [es:pc6],CH
  JNZ oa2f
  CALL oa89
oa2f:
  RET
oa3o:
  CALL oa7d
  PUSH AX
  AND AL,0xf0
  MOV byte [es:pc6],AL
  SHR AL,4
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  SHL CH,4
  POP AX
  AND AL,0xf
  CMP byte [es:pc6],CH
  JNZ oa58
  CALL oa89
oa58:
  RET

oa59:
  CMP BL,160
  JB oa61
  JMP oa66
oa61:
  CMP BH,100
  JB oa6b
oa66:
  OR SI,0x80
  RET
oa6b:
  XOR AX,AX
  RET

oa6e:           ;Compute VRAM/shadow address from BL=x, BH=y (game coords)
                ;Returns: DI = even-row VRAM offset (= shadow index)
                ;         AX bit 0 = x parity (0=high nibble, 1=low nibble)
  XOR AX,AX
  MOV AL,BL
  AND AX,1      ;AX = x parity (save for return)
  PUSH AX
  ; Compute y*80 = (y*4+y)*16 using shifts (faster than MUL)
  MOV AL,BH
  XOR AH,AH     ;AX = y
  MOV DI,AX     ;DI = y
  SHL DI,2      ;DI = y*4
  ADD DI,AX     ;DI = y*5
  SHL DI,4      ;DI = y*80
  MOV BH,0
  SHR BL,1      ;BL = x/2 (byte offset in row)
  ADD DI,BX     ;DI = y*80 + x/2
  POP AX        ;Restore x parity in AX
  RET

oa7d:           ;Read shadow buffer byte at DI
  PUSH DI
  ADD DI,p12e
  MOV AL,byte [es:DI]
  POP DI
  RET

oa89:           ;Write AL to VRAM (both rows) + shadow buffer at DI
  MOV AH,AL
  MOV DX,0xda
  CMP word [es:pc9],0
  JNZ oaa8
  CMP word [es:pcb],0
  JZ oaaa
oa9e:
  IN AL,DX
  TEST AL,1
  JNZ oa9e
oaa3:
  IN AL,DX
  TEST AL,1
  JZ oaa3
oaa8:
  CMP byte [ES:bmp_loaded],0
  JZ .oa_no_bmp
  CALL bmp_vram_write       ;Write BMP-substituted value to even+odd VRAM
  JMP oaaa
.oa_no_bmp:
  MOV byte [DI],AH          ;Write even row (bank 0)
  PUSH DI
  ADD DI,0x2000           ;Odd row bank
  MOV byte [DI],AH          ;Write odd row (bank 1) — double-draw
  POP DI
oaaa:
  PUSH DI
  ADD DI,p12e
  MOV byte [es:DI],AH      ;Write shadow buffer (always game state)
  POP DI
  RET

;============================================================================
; bmp_vram_write — Write game-state byte to VRAM with BMP substitution
; For each nibble: if territory color (1-6), substitute BMP background pixel.
; Input:  AH = game state byte (two nibbles)
;         DI = VRAM offset (0-7999), DS = B000h, ES = data segment
; Output: Even VRAM bank at DS:DI, odd bank at DS:DI+2000h
; Preserves: AH, DI, BX, BP
;============================================================================
bmp_vram_write:
  PUSH SI
  PUSH CX
  ; === Even bank ===
  MOV SI,DI
  ADD SI,bmp_background     ;SI = bmp_background + DI (even bank pixel)
  MOV CL,byte [ES:SI]      ;CL = BMP even bank byte
  MOV AL,AH                 ;AL = working copy of game byte
  ; Check high nibble: territory color 1-6?
  MOV CH,AL
  SHR CH,4                  ;CH = high nibble value (0-15)
  DEC CH                    ;colors 1-6 → 0-5
  CMP CH,6
  JAE .he_keep
  AND AL,0x0F               ;clear game high nibble
  MOV CH,CL
  AND CH,0xF0               ;BMP high nibble
  OR AL,CH
.he_keep:
  ; Check low nibble: territory color 1-6?
  MOV CH,AL
  AND CH,0x0F
  DEC CH
  CMP CH,6
  JAE .le_keep
  AND AL,0xF0               ;clear game low nibble
  MOV CH,CL
  AND CH,0x0F               ;BMP low nibble
  OR AL,CH
.le_keep:
  MOV byte [DI],AL          ;Write even bank VRAM

  ; === Odd bank ===
  ADD SI,8000               ;SI = bmp_background + 8000 + DI (odd bank pixel)
  MOV CL,byte [ES:SI]      ;CL = BMP odd bank byte
  MOV AL,AH                 ;reload game byte
  ; Check high nibble
  MOV CH,AL
  SHR CH,4
  DEC CH
  CMP CH,6
  JAE .ho_keep
  AND AL,0x0F
  MOV CH,CL
  AND CH,0xF0
  OR AL,CH
.ho_keep:
  ; Check low nibble
  MOV CH,AL
  AND CH,0x0F
  DEC CH
  CMP CH,6
  JAE .lo_keep
  AND AL,0xF0
  MOV CH,CL
  AND CH,0x0F
  OR AL,CH
.lo_keep:
  PUSH DI
  ADD DI,0x2000
  MOV byte [DI],AL          ;Write odd bank VRAM
  POP DI
  POP CX
  POP SI
  RET

oab6:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [pa1],AX
  MOV AX,word [BP+6]
  MOV word [pa3],AX
  MOV AX,word [BP+8]
  MOV word [pa5],AX
  MOV AX,word [BP+0xa]
  MOV word [pa7],AX
  MOV AX,word [BP+0xc]
  AND AX,0xf
  MOV byte [pa9],AL
  MOV BP,0
  MOV SI,0
  CALL ob49
  MOV AX,SI
  POP BP
  RET

oae7:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [pa1],AX
  MOV AX,word [BP+6]
  MOV word [pa3],AX
  MOV AX,word [BP+8]
  MOV word [pa5],AX
  MOV AX,word [BP+0xa]
  MOV word [pa7],AX
  MOV AX,word [BP+0xc]
  AND AX,0xf
  MOV byte [pa9],AL
  MOV BP,3
  MOV SI,0
  CALL ob49
  MOV AX,SI
  POP BP
  RET

ob18:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [pa1],AX
  MOV AX,word [BP+6]
  MOV word [pa3],AX
  MOV AX,word [BP+8]
  MOV word [pa5],AX
  MOV AX,word [BP+0xa]
  MOV word [pa7],AX
  MOV AX,word [BP+0xc]
  AND AX,0xf
  MOV byte [pa9],AL
  MOV BP,1
  MOV SI,0
  CALL ob49
  MOV AX,SI
  POP BP
  RET

ob49:
  MOV AX,word [pa5]
  SUB AX,word [pa1]
  MOV word [p95],AX
  MOV AX,word [pa7]
  SUB AX,word [pa3]
  MOV word [p97],AX
  MOV byte [p9b],0
  MOV byte [p9c],1
  MOV byte [p9d],1
  MOV byte [p9e],0
  CMP word [p95],0
  JGE ob81
  MOV byte [p9d],0xff
  NEG word [p95]
ob81:
  CMP word [p97],0
  JGE ob91
  NEG word [p97]
  MOV byte [p9c],0xff
ob91:
  MOV AX,word [p97]
  CMP word [p95],AX
  JGE obbe
  PUSH word [p95]
  MOV AX,word [p97]
  MOV word [p95],AX
  POP word [p97]
  MOV AL,byte [p9d]
  MOV byte [p9b],AL
  MOV byte [p9d],0
  MOV AL,byte [p9c]
  MOV byte [p9e],AL
  MOV byte [p9c],0
obbe:
  MOV AX,word [p95]
  SHR AX,1
  MOV word [p99],AX
  MOV word [p9f],1
  MOV AX,word [pa1]
  MOV BL,AL
  MOV AX,word [pa3]
  MOV BH,AL
  CALL oc13
obd9:
  MOV AX,word [p95]
  CMP word [p9f],AX
  JLE obe3
  RET
obe3:
  ADD BL,byte [p9d]
  ADD BH,byte [p9e]
  MOV AX,word [p97]
  ADD word [p99],AX
  INC word [p9f]
  MOV AX,word [p95]
  CMP word [p99],AX
  JLE ocoe
  MOV AX,word [p95]
  SUB word [p99],AX
  ADD BL,byte [p9b]
  ADD BH,byte [p9c]
ocoe:
  CALL oc13
  JMP obd9

oc13:
  MOV CH,byte [pa9]
  PUSH BX
  PUSH DS
  MOV AX,0xb000
  MOV DS,AX
  CALL o95b
  POP DS
  POP BX
  RET

oc43:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV byte [paa],AL
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV DI,word [BP+8]
  MOV SI,0
  MOV BP,0
  CALL oca3
  MOV AX,SI
  POP BP
  RET

oc63:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV byte [paa],AL
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV DI,word [BP+8]
  MOV SI,0
  MOV BP,1
  CALL oca3
  MOV AX,SI
  POP BP
  RET

oc83:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV BL,AL
  MOV byte [paa],AL
  MOV AX,word [BP+6]
  MOV BH,AL
  MOV DI,word [BP+8]
  MOV SI,0
  MOV BP,2
  CALL oca3
  MOV AX,SI
  POP BP
  RET

oca3:
  MOV CL,byte [DI]
  MOV byte [pab],CL
  INC DI
  MOV CH,byte [DI]
  INC DI
ocad:
  CALL occf
  INC DI
  INC BL
  CMP BP,2
  JNZ ocba
  INC BL
ocba:
  DEC CL
  JNZ ocad
  INC BH
  DEC CH
  JZ occe
  MOV BL,byte [paa]
  MOV CL,byte [pab]
  JMP ocad
occe:
  RET

occf:
  PUSH CX
  MOV CH,byte [DI]
  CMP CH,0x58
  JZ ocea
  CMP CH,0x88
  JZ ocea
  PUSH BX
  PUSH DI
  PUSH DS
  MOV AX,0xb000
  MOV DS,AX
  CALL o95b
  POP DS
  POP DI
  POP BX
ocea:
  POP CX
  RET

int9save:
  DW 0,0

ocec:
  MOV AX,DS
  MOV word [cs:o449],AX
  PUSH DS
  MOV AX,0
  MOV DS,AX
  MOV DI,0x24
  MOV AX,word [DI]
  MOV BX,word [DI+2]
  MOV CX,od2e
  MOV DX,CS
  CLI
  MOV word [DI],CX
  MOV word [DI+2],DX
  STI
  POP DS
  MOV word [cs:int9save],AX
  MOV word [cs:int9save+2],BX
  RET

restoreint9:
  MOV CX,word [cs:int9save]
  MOV DX,word [cs:int9save+2]
  XOR AX,AX
  MOV DS,AX
  MOV word [0x24],CX
  MOV word [0x26],DX
  RET

od2e:
  STI
  PUSH AX
  PUSH CX
  PUSH SI
  PUSH DS
  CLD
  MOV AX,word [cs:o449]
  MOV DS,AX
  IN AL,0x60
  PUSH AX
  IN AL,0x61
  MOV AH,AL
  OR AL,0x80
  OUT 0x61,AL
  XCHG AH,AL
  OUT 0x61,AL
  POP AX
  MOV byte [pc3],AL
  CALL od5a
  CLI
  MOV AL,0x20
  OUT 0x20,AL
  POP DS
  POP SI
  POP CX
  POP AX
;  CS: JMP D[int9save]
  IRET

od5a:
  MOV SI,pdd
  MOV AL,byte [pc3]
  MOV CX,0x1d
od63:
  CMP AL,byte [SI]
  JZ od6d
  ADD SI,3
  LOOP od63
  CMP AL,0x44
  JNZ nokey
  JMP ofbe
nokey:
  RET
od6d:
  INC SI
  JMP word [SI]

od7o:
  MOV byte [pbo],0xff
  MOV byte [pd3],4
  MOV byte [pd4],4
  MOV byte [pb8],1
  MOV byte [pb9],1
  CALL ofce
  RET

od8d:
  MOV byte [pbo],0
  CMP byte [pd3],4
  JNZ od9c
  CALL of18
od9c:
  CMP byte [pb8],1
  JZ oda4
  RET
oda4:
  CMP byte [pb1],0xff
  JNZ odb1
  MOV byte [pb8],2
  RET
odb1:
  MOV byte [pb8],0
  RET

odb7:
  MOV byte [pb1],0xff
  MOV byte [pd3],0
  MOV byte [pd4],0
  MOV byte [pb8],2
  MOV byte [pb9],2
  CALL ofce
  RET

odd4:
  MOV byte [pb1],0
  CMP byte [pd3],0
  JNZ ode3
  CALL of18
ode3:
  CMP byte [pb8],2
  JZ odeb
  RET
odeb:
  CMP byte [pbo],0xff
  JNZ odf8
  MOV byte [pb8],1
  RET
odf8:
  MOV byte [pb8],0
  RET

odfe:
  MOV byte [pb2],0xff
  MOV byte [pd3],2
  MOV byte [pd4],2
  RET

oeoe:
  MOV byte [pb2],0
  CMP byte [pd3],2
  JNZ oe1d
  CALL of18
oe1d:
  RET

oe1e:
  MOV byte [pb3],0xff
  MOV byte [pd3],6
  MOV byte [pd4],6
  RET

oe2e:
  MOV byte [pb3],0
  CMP byte [pd3],6
  JNZ oe3d
  CALL of18
oe3d:
  RET

oe3e:
  MOV byte [pb4],0xff
  MOV byte [pd3],1
  MOV byte [pd4],1
  RET

oe4e:
  MOV byte [pb4],0
  CMP byte [pd3],1
  JNZ oe5d
  CALL of18
oe5d:
  RET

oe5e:
  MOV byte [pb5],0xff
  MOV byte [pd3],3
  MOV byte [pd4],3
  RET

oe6e:
  MOV byte [pb5],0
  CMP byte [pd3],3
  JNZ oe7d
  CALL of18
oe7d:
  RET

oe7e:
  MOV byte [pb6],0xff
  MOV byte [pd3],7
  MOV byte [pd4],7
  RET

oe8e:
  MOV byte [pb6],0
  CMP byte [pd3],7
  JNZ oe9d
  CALL of18
oe9d:
  RET

oe9e:
  MOV byte [pb7],0xff
  MOV byte [pd3],5
  MOV byte [pd4],5
  RET

oeae:
  MOV byte [pb7],0
  CMP byte [pd3],5
  JNZ oebd
  CALL of18
oebd:
  RET

oebe:
  MOV byte [pbb],0xff
  MOV byte [pba],0xff
  RET

oec9:
  MOV byte [pba],0
  RET

oecf:
  MOV byte [pbc],0xff
  JMP ofa6

oed7:
  MOV byte [pbc],0
  RET

oedd:
  MOV byte [pbd],0xff
  JMP ofa6

oee5:
  MOV byte [pbd],0
  RET

oeeb:
  MOV byte [pbe],0xff
  JMP ofa6

oef3:
  MOV byte [pbe],0
  RET

oef9:
  CMP byte [pbf],0xff
  JZ ofo1
  RET
ofo1:
  XOR byte [pco],0xff
  MOV byte [pbf],0
  RET

ofoc:
  MOV byte [pbf],0xff
  RET

of12:
  MOV byte [pc1],0xff
  RET

of18:
  MOV byte [pd3],0x63
  CMP byte [pb2],0
  JZ of2e
  MOV byte [pd3],2
  MOV byte [pd4],2
of2e:
  CMP byte [pb3],0
  JZ of3f
  MOV byte [pd3],6
  MOV byte [pd4],6
of3f:
  CMP byte [pbo],0
  JZ of5o
  MOV byte [pd3],4
  MOV byte [pd4],4
of5o:
  CMP byte [pb1],0
  JZ of61
  MOV byte [pd3],0
  MOV byte [pd4],0
of61:
  CMP byte [pb4],0
  JZ of72
  MOV byte [pd3],1
  MOV byte [pd4],1
of72:
  CMP byte [pb5],0
  JZ of83
  MOV byte [pd3],3
  MOV byte [pd4],3
of83:
  CMP byte [pb6],0
  JZ of94
  MOV byte [pd3],7
  MOV byte [pd4],7
of94:
  CMP byte [pb7],0
  JZ ofa5
  MOV byte [pd3],5
  MOV byte [pd4],5
ofa5:
  RET

ofa6:
  CMP byte [pbc],0xff
  JZ ofae
  RET
ofae:
  CMP byte [pbd],0xff
  JZ ofb6
  RET
ofb6:
  CMP byte [pbe],0xff
  JZ ofbe
  RET
;----------------------------------------------------------------------------
; ofbe — Exit game (Ctrl+Alt+Del handler / F10)
; Silences speaker, restores INT 8 & INT 9 vectors, restores CGA
; palette, switches back to text mode, and exits to DOS.
;----------------------------------------------------------------------------
ofbe:
  IN AL,0x61
  AND AL,0xfc
  OUT 0x61,AL
  MOV AL,0x20
  OUT 0x20,AL
  PUSH DS
  MOV AX,0x40
  MOV DS,AX
  MOV AL,byte [cs:vgasave]
  MOV byte [0x89],AL
  POP DS
  CALL pc1_set_cga_palette  ;Restore CGA palette while DS is valid and hidden mode active
  CALL restoreint8
  CALL restoreint9
  MOV AX,3
  INT 0x10
  MOV AX,0x4c00
  INT 0x21

;----------------------------------------------------------------------------
; ofce — Screen wobble effect (Ctrl + Left/Right shifts horizontal sync)
; Adjusts CRTC register 2 (horizontal sync position) to make the
; display wobble left/right. Currently commented out for PC1.
;----------------------------------------------------------------------------
ofce:
  CMP byte [pbc],0xff
  JZ ofd6
  RET
ofd6:
  CMP byte [pbo],0xff
  JNZ offe
  INC byte [pc2]
  CMP byte [pc2],0x5e
  JNZ ofed
  MOV byte [pc2],0x5d
ofed:
;  PUSH DX
;  MOV DX,03d4
;  MOV AL,2
;  OUT DX,AL
  MOV AL,byte [pc2]
;  INC DX
;  OUT DX,AL      ;Change horizontal synch position?  Make screen wobble???
  MOV byte [p7b],AL
;  POP DX
  RET
offe:
  CMP byte [pb1],0xff
  JNZ o1o26
  DEC byte [pc2]
  CMP byte [pc2],0x54
  JNZ o1o15
  MOV byte [pc2],0x55
o1o15:
;  PUSH DX
;  MOV DX,03d4
;  MOV AL,2
;  OUT DX,AL
  MOV AL,byte [pc2]
;  INC DX
;  OUT DX,AL      ;Change horizontal synch position?  Make screen wobble???
  MOV byte [p7b],AL
;  POP DX
  RET
o1o26:
  RET

o1o5o:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV AH,0xe
  MOV BX,word [BP+6]
  MOV BH,0
  INT 0x10        ;Output character
  POP BP
  RET

o1o61:
  PUSH BP
  MOV BP,SP
  MOV BX,0
  MOV AX,word [BP+4]
  MOV DH,AL
  MOV AX,word [BP+6]
  MOV DL,AL
  MOV AH,2
  INT 0x10        ;Set cursor position
  POP BP
  RET

;----------------------------------------------------------------------------
; o1o9a / o1oc3 — High score file I/O (STYX.SCO)
; o1o9a: Read 512 bytes from STYX.SCO into p215o buffer
; o1oc3: Write 512 bytes from p215o buffer to STYX.SCO
; Uses DOS INT 21h file operations (3Dh=open, 3Fh=read, 40h=write,
; 3Ch=create, 3Eh=close).
;----------------------------------------------------------------------------
filename:
  DB 'STYX.SCO',0

o1o9a:
  PUSH BP
  PUSH DS
  PUSH CS
  POP DS
  MOV AX,0x3d00
  MOV DX,filename
  INT 0x21
  POP DS
  JC readerror
  MOV BX,AX
  MOV AH,0x3f
  MOV CX,0x200
  MOV DX,p215o
  INT 0x21
  MOV AH,0x3e
  INT 0x21
readerror:
  POP BP
  RET

o1oc3:
  PUSH BP
  PUSH DS
  PUSH CS
  POP DS
  MOV AH,0x3c
  MOV CX,0x20
  MOV DX,filename
  INT 0x21
  POP DS
  JC writeerror
  MOV BX,AX
  MOV AH,0x40
  MOV CX,0x200
  MOV DX,p215o
  INT 0x21
  MOV AH,0x3e
  INT 0x21
writeerror:
  POP BP
  RET

;----------------------------------------------------------------------------
; o1142 — Decompress and draw RLE-encoded title screen
; Reads from p2354 (RLE data), writes to CGA VRAM at B800:0000.
; RLE format: 0xFE followed by count byte and value byte means
; "repeat value count times"; any other byte is literal.
; This draws the Styx logo / title art.
;----------------------------------------------------------------------------
o1142:
  PUSH ES
  PUSH BP
  MOV AX,0xb800
  MOV ES,AX
  MOV DI,0
  MOV SI,p2354
o114f:
  MOV AL,byte [SI]
  CMP AL,0xfe
  JZ o1163
  MOV byte [es:DI],AL
  INC DI
  INC SI
  CMP DI,0x4000
  JNZ o114f
  JMP o117a
o1163:
  INC SI
  MOV BL,byte [SI]
  INC SI
  MOV AL,byte [SI]
  INC SI
o116a:
  MOV byte [es:DI],AL
  INC DI
  CMP DI,0x4000
  JZ o117a
  DEC BL
  JNZ o116a
  JMP o114f
o117a:
  POP BP
  POP ES
  RET

o117d:
  DW 0

int8save:
  DW 0,0

;----------------------------------------------------------------------------
; o117f — Install custom INT 8 (timer) handler
; Saves the old INT 8 vector (at 0000:0020) and replaces it with
; our handler at o11dd. The old vector is saved in int8save for
; chaining and restoration.
;----------------------------------------------------------------------------
o117f:
  MOV AX,DS
  MOV word [cs:o117d],AX
  PUSH DS
  MOV AX,0
  MOV DS,AX
  MOV DI,0x20
  MOV AX,word [DI]
  MOV BX,word [DI+2]
  MOV CX,o11dd
  MOV DX,CS
  CLI
  MOV word [DI],CX
  MOV word [DI+2],DX
  STI
  POP DS
  MOV word [cs:int8save],AX
  MOV word [cs:int8save+2],BX
  RET

;----------------------------------------------------------------------------
; restoreint8 — Restore original INT 8 timer handler
; Also resets PIT channel 0 to default 18.2 Hz rate (count=0).
;----------------------------------------------------------------------------
restoreint8:
  CLI
  MOV AL,0x36
  OUT 0x43,AL
  XOR AL,AL
  OUT 0x40,AL
  OUT 0x40,AL
  MOV AX,word [cs:int8save]
  MOV BX,word [cs:int8save+2]
  MOV DI,0x20
  PUSH DS
  XOR CX,CX
  MOV DS,CX
  MOV word [DI],AX
  MOV word [DI+2],BX
  STI
  POP DS
  RET

;----------------------------------------------------------------------------
; o11dd — INT 8 timer interrupt service routine (sound/timing)
; Called at the PIT rate (programmable). Three modes:
;   p38bc=0: no sound (speaker off)
;   p38bc=1: timed pulse — turn speaker on for p38c3 cycles, then off
;   p38bc=2: toggle speaker state (square wave) for tone generation
;
; Also accumulates p38co timing counter (incremented by p38be each
; tick) and chains to the original INT 8 at the standard 18.2 Hz
; rate using int8count/int8speed as a fractional divider.
;----------------------------------------------------------------------------
o11dd:
  PUSHF
  STI
  PUSH AX
  PUSH CX
  PUSH DX
  PUSH DS
  CLD
  MOV AX,word [cs:o117d]
  MOV DS,AX
  CMP word [p38bc],0
  JZ o1211
  CMP word [p38bc],1
  JZ o12o1
  IN AL,0x61
  XOR AL,2
  OUT 0x61,AL       ;Toggle speaker position
  JMP o1211
o12o1:
  MOV CX,word [p38c3]
  IN AL,0x61
  OR AL,2
  OUT 0x61,AL       ;Turn speaker on
o12oc:
  LOOP o12oc
  AND AL,0xfd
  OUT 0x61,AL       ;Turn speaker off
o1211:
  MOV AX,word [p38be]
  ADD word [p38co],AX
  JNB o121e
  INC byte [p38c2]

o121e:
  MOV AX,word [cs:int8speed]
  ADD word [cs:int8count],AX
  JNC eoi

  POP DS
  POP DX
  POP CX
  POP AX
  POPF
  JMP far [cs:int8save]

eoi:
  MOV AL,0x20
  OUT 0x20,AL       ;End of interrupt
  POP DS
  POP DX
  POP CX
  POP AX
  POPF
  IRET

int8count:
  DW 0
int8speed:
  DW 0

;----------------------------------------------------------------------------
; o1227 — Initialize enemies for current level
; Sets p38f6 = number of enemies (1 if level<3, else 2).
; For each enemy: places at a diamond position, sets random
; direction and speed based on difficulty parameters.
;----------------------------------------------------------------------------
o1227:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  CALL o5891
  CMP AX,3
  JGE o123d
  MOV word [p38f6],1
  JMP o1243
o123d:
  MOV word [p38f6],2
o1243:
  MOV word [BP+4],0
o1248:
  MOV AX,word [BP+4]
  CMP AX,word [p38f6]
  JL o1254
  JMP o135a
o1254:
  SHL AX,1
  MOV SI,AX
  MOV word [SI+p38ca],0x50
  MOV word [SI+p38ce],0x1e
  XOR BX,BX
  MOV word [SI+p38de],BX
  MOV BX,0xa
  MOV word [SI+p38e6],BX
  MOV word [SI+p38ea],BX
  MOV word [BP+6],0
o127a:
  MOV AX,word [BP+6]
  CMP AX,8
  JL o1285
  JMP o1339
o1285:
  MOV CL,5
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+4]
  SHL AX,CL
  SHL AX,1
  ADD SI,AX
  MOV AX,word [BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,word [DI+p38ca]
  MOV word [SI+p38f8],AX
  MOV CL,5
  MOV AX,word [BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+4]
  SHL AX,CL
  SHL AX,1
  INC AX
  INC AX
  ADD SI,AX
  MOV AX,word [BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,word [DI+p38ce]
  MOV word [SI+p38f8],AX
  MOV CL,5
  MOV AX,word [BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+4]
  SHL AX,CL
  SHL AX,1
  ADD AX,4
  ADD SI,AX
  MOV AX,word [BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,word [DI+p38ca]
  MOV word [SI+p38f8],AX
  MOV CL,5
  MOV AX,word [BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+4]
  SHL AX,CL
  SHL AX,1
  ADD AX,6
  ADD SI,AX
  MOV AX,word [BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,word [DI+p38ce]
  MOV word [SI+p38f8],AX
  MOV CL,5
  MOV AX,word [BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+4]
  SHL AX,CL
  SHL AX,1
  ADD AX,8
  ADD SI,AX
  MOV word [SI+p38f8],0
  INC word [BP+6]
  JMP o127a
o1339:
  MOV AX,word [BP+4]
  SHL AX,1
  MOV SI,AX
  MOV word [SI+p38f2],0
  MOV word [SI+p38ee],9
  PUSH word [BP+4]
  CALL o17ae
  MOV SP,BP
  INC word [BP+4]
  JMP o1248
o135a:
  ADD SP,8
  POP BP
  RET

;----------------------------------------------------------------------------
; o135f — Enemy AI dispatcher
; Calls o1391 for each active enemy (0 to p38f6-1).
; Skips if game-over flag is set.
;----------------------------------------------------------------------------
o135f:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  CALL o586e
  TEST AX,AX
  JZ o1373
  XOR AX,AX
  ADD SP,4
  POP BP
  RET
o1373:
  MOV word [BP+2],0
o1378:
  MOV AX,word [BP+2]
  CMP AX,word [p38f6]
  JGE o138c
  PUSH AX
  CALL o1391
  MOV SP,BP
  INC word [BP+2]
  JMP o1378
o138c:
  ADD SP,4
  POP BP
  RET

;----------------------------------------------------------------------------
; o1391 — Enemy AI movement (single enemy)
; Input: enemy index on stack
; Per frame: computes new position using sin/cos of direction angle,
; boundary-checks (3 < x < 156, 11 < y < 96), detects collisions
; with player trail (bit 15 in ob18 result = tail hit → player death).
; On collision with border: reverts position, picks new random
; direction, may double speed temporarily.
; Also tracks proximity to player for pursuit behavior.
;
; Key enemy state arrays (indexed by enemy# × 2):
;   p38ca/ce = enemy x/y position
;   p38d2/d6 = x/y velocity components
;   p38da    = movement direction (angle in degrees)
;   p38de    = direction delta (angular velocity)
;   p38e2    = direction change rate
;   p38e6    = speed divisor (lower = faster)
;   p38ea    = target speed
;   p38ee    = sprite animation frame
;   p38f2    = animation cycle counter
;   p38f8    = enemy trail history ring buffer
;----------------------------------------------------------------------------
o1391:
  PUSH BP
  SUB SP,0x2c
  MOV BP,SP
  MOV word [BP+0x24],3
o139c:
  CMP word [BP+0x24],0
  JNZ o13a5
  JMP o17a9
o13a5:
  CALL o5891
  ADD AX,0x1e
  PUSH AX
  CALL o227
  MOV SP,BP
  CMP AX,0x1c
  JLE o13be
  PUSH word [BP+0x30]
  CALL o17ae
  MOV SP,BP
o13be:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p38e2]
  ADD word [SI+p38de],BX
  CMP word [SI+p38de],0x168
  MOV word [BP],AX
  JL o13de
  SUB word [SI+p38de],0x168
o13de:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p38de]
  TEST BX,BX
  MOV word [BP],AX
  JNS o13f6
  ADD word [SI+p38de],0x168
o13f6:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  PUSH word [SI+p38de]
  CALL o2c1
  MOV SP,BP
  MOV BX,word [BP+0x30]
  SHL BX,1
  CWD
  IDIV word [BX+p38e6]
  PUSH word [BX+p38de]
  MOV word [BP+0x1e],AX
  CALL o2e7
  MOV SP,BP
  MOV BX,word [BP+0x30]
  SHL BX,1
  CWD
  IDIV word [BX+p38e6]
  MOV CX,word [BX+p38ca]
  MOV DX,word [BX+p38ce]
  MOV word [BP+0x1a],CX
  MOV CX,word [BX+p38d2]
  ADD word [BX+p38ca],CX
  MOV CX,word [BX+p38d6]
  ADD word [BX+p38ce],CX
  MOV word [BP+0x1c],DX
  MOV word [BP+0x20],AX
  MOV AX,word [BP+0x1e]
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,word [BX+p38ca]
  SUB CX,AX
  MOV word [BP+8],AX
  MOV AX,word [BP+0x20]
  MOV word [BP+0x12],CX
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,word [BX+p38ce]
  SUB CX,AX
  MOV DX,word [BX+p38ca]
  ADD DX,word [BP+8]
  MOV BX,word [BX+p38ce]
  ADD BX,AX
  XOR AX,AX
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH word [BP+0x12]
  MOV word [BP+0x14],CX
  MOV word [BP+0x16],DX
  MOV word [BP+0x18],BX
  CALL ob18
  MOV SP,BP
  MOV word [BP+0x22],AX
  AND AX,0x7996
  JNZ o14do
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p38ca],3
  JL o14do
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p38ca],0x9c
  JG o14do
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p38ce],0xb
  JL o14do
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p38ce],0x60
  JLE o15oc
o14do:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [BP+0x1a]
  MOV word [SI+p38ca],BX
  MOV AX,word [BP+0x1c]
  MOV word [SI+p38ce],AX
  PUSH word [BP+0x30]
  CALL o17ae
  MOV SP,BP
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p38e6],0x32
  MOV word [BP],AX
  JGE o15o6
  MOV AX,word [SI+p38e6]
  ADD word [SI+p38e6],AX
o15o6:
  DEC word [BP+0x24]
  JMP o139c
o15oc:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV BX,word [SI+p38f2]
  SHL BX,CL
  MOV CL,3
  MOV DX,word [BP+0x30]
  SHL DX,CL
  SHL DX,1
  ADD BX,DX
  MOV CL,5
  MOV word [BP+6],BX
  MOV BX,word [SI+p38f2]
  SHL BX,CL
  MOV word [BP+4],DX
  INC DX
  INC DX
  ADD BX,DX
  MOV CL,5
  MOV DX,word [SI+p38f2]
  SHL DX,CL
  MOV DI,DX
  MOV DX,word [BP+4]
  ADD DX,4
  MOV CX,DI
  ADD CX,DX
  MOV word [BP+0xa],CX
  MOV CL,5
  MOV DX,word [SI+p38f2]
  SHL DX,CL
  MOV DI,DX
  MOV DX,word [BP+4]
  ADD DX,6
  MOV CX,DI
  ADD CX,DX
  MOV word [BP+0xc],CX
  MOV CL,5
  MOV AX,word [SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV AX,word [BP+4]
  ADD AX,8
  MOV DX,SI
  ADD DX,AX
  MOV SI,DX
  PUSH word [SI+p38f8]
  MOV SI,word [BP+0xc]
  PUSH word [SI+p38f8]
  MOV SI,word [BP+0xa]
  PUSH word [SI+p38f8]
  PUSH word [BX+p38f8]
  MOV SI,word [BP+6]
  PUSH word [SI+p38f8]
  CALL oae7
  MOV SP,BP
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,word [SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+0x30]
  SHL AX,CL
  SHL AX,1
  ADD SI,AX
  MOV AX,word [BP+0x12]
  MOV word [SI+p38f8],AX
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,word [SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+0x30]
  SHL AX,CL
  SHL AX,1
  INC AX
  INC AX
  ADD SI,AX
  MOV AX,word [BP+0x14]
  MOV word [SI+p38f8],AX
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,word [SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+0x30]
  SHL AX,CL
  SHL AX,1
  ADD AX,4
  ADD SI,AX
  MOV AX,word [BP+0x16]
  MOV word [SI+p38f8],AX
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,word [SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+0x30]
  SHL AX,CL
  SHL AX,1
  ADD AX,6
  ADD SI,AX
  MOV AX,word [BP+0x18]
  MOV word [SI+p38f8],AX
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV BX,word [SI+p38f2]
  SHL BX,CL
  MOV CL,3
  MOV DX,word [BP+0x30]
  SHL DX,CL
  SHL DX,1
  ADD DX,8
  ADD BX,DX
  MOV AX,word [SI+p38ee]
  MOV word [BX+p38f8],AX
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,word [SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,word [BP+0x30]
  SHL AX,CL
  SHL AX,1
  ADD AX,8
  ADD SI,AX
  PUSH word [SI+p38f8]
  PUSH word [BP+0x18]
  PUSH word [BP+0x16]
  PUSH word [BP+0x14]
  PUSH word [BP+0x12]
  CALL oab6
  MOV SP,BP
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  INC word [SI+p38f2]
  CMP word [SI+p38f2],8
  MOV word [BP],AX
  JL o1714
  MOV word [SI+p38f2],0
  MOV AX,4
  PUSH AX
  CALL o227
  MOV SP,BP
  MOV SI,AX
  CMP SI,5
  JNB o1714
  SHL SI,1
  MOV AX,word [cs:SI+o16fc]
  PUSH AX
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  POP AX
  MOV word [SI+p38ee],AX
o1714:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p38e6],0xa
  MOV word [BP],AX
  JLE o172b
  MOV word [SI+p38e6],0xa
o172b:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p38e6]
  CMP BX,word [SI+p38ea]
  MOV word [BP],AX
  JLE o1743
  DEC word [SI+p38e6]
o1743:
  MOV AX,word [BP+0x30]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p38e6]
  CMP BX,word [SI+p38ea]
  MOV word [BP],AX
  JGE o175b
  INC word [SI+p38e6]
o175b:
  XOR AX,AX
  CMP word [BP+0x30],0
  MOV word [BP+0x24],AX
  JNZ o1792
  MOV AX,word [p38ca]
  SUB AX,word [p3cf8]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  MOV BX,word [p38ce]
  SUB BX,word [p3cfa]
  PUSH BX
  MOV word [BP+0x28],AX
  CALL o2a9
  MOV SP,BP
  ADD word [BP+0x28],AX
  PUSH word [BP+0x28]
  MOV word [BP+0x2a],AX
  CALL o45b8
  MOV SP,BP
o1792:
  MOV AX,word [BP+0x22]
  AND AX,0x8000
  JNZ o179d
  JMP o139c
o179d:
  MOV AX,1
  PUSH AX
  CALL o5858
  MOV SP,BP
  JMP o139c
o17a9:
  ADD SP,0x2c
  POP BP
  RET

o16fc:
  DW 3,5,6,9,0xa

;----------------------------------------------------------------------------
; o17ae — Set random direction and speed for an enemy
; Input: enemy index on stack
; Picks random direction angle, calculates x/y velocity from
; sin/cos, sets random target speed.
;----------------------------------------------------------------------------
o17ae:
  PUSH BP
  SUB SP,0xe
  MOV BP,SP
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV AX,0x59
  PUSH AX
  MOV word [BP],SI
  CALL o227
  MOV SP,BP
  SHL AX,1
  SHL AX,1
  MOV SI,word [BP]
  MOV word [SI+p38da],AX
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV AX,3
  PUSH AX
  MOV word [BP],SI
  CALL o227
  MOV SP,BP
  ADD AX,3
  MOV SI,word [BP]
  MOV word [SI+p38ea],AX
  CMP word [p38f6],2
  JNZ o18o2
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  ADD word [SI+p38ea],5
o18o2:
  CALL o5891
  CMP AX,5
  JLE o1811
  MOV word [BP+0xc],5
  JMP o1817
o1811:
  CALL o5891
  MOV word [BP+0xc],AX
o1817:
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  PUSH word [SI+p38da]
  MOV word [BP+2],SI
  CALL o2c1
  MOV SP,BP
  MOV BX,word [BP+0xc]
  ADD BX,0xc
  PUSH BX
  MOV word [BP+6],AX
  CALL o227
  MOV SP,BP
  MOV BX,0x19
  SUB BX,AX
  MOV AX,word [BP+6]
  CWD
  IDIV BX
  MOV SI,word [BP+2]
  MOV word [SI+p38d2],AX
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  PUSH word [SI+p38da]
  MOV word [BP+2],SI
  CALL o2e7
  MOV SP,BP
  MOV BX,word [BP+0xc]
  ADD BX,0xa
  PUSH BX
  MOV word [BP+6],AX
  CALL o227
  MOV SP,BP
  MOV BX,0x19
  SUB BX,AX
  MOV AX,word [BP+6]
  CWD
  IDIV BX
  MOV SI,word [BP+2]
  MOV word [SI+p38d6],AX
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV AX,0xf
  PUSH AX
  MOV word [BP],SI
  CALL o227
  MOV SP,BP
  ADD AX,5
  MOV SI,word [BP]
  MOV word [SI+p38e2],AX
  MOV AX,1
  PUSH AX
  CALL o227
  MOV SP,BP
  TEST AX,AX
  JZ o18ba
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p38e2]
  NEG AX
  MOV word [SI+p38e2],AX
o18ba:
  ADD SP,0xe
  POP BP
  RET

;----------------------------------------------------------------------------
; o18bf — Check if second enemy should be removed
; If enemy 1's position overlaps a claimed area (color not present
; at its diamond position), reduce enemy count to 1.
;----------------------------------------------------------------------------
o18bf:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p38f6],2
  JNZ o18e7
  XOR AX,AX
  PUSH AX
  PUSH word [p38do]
  PUSH word [p38cc]
  CALL o933
  MOV SP,BP
  AND AX,1
  JNZ o18e7
  MOV word [p38f6],1
o18e7:
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o18ec — Draw all enemies (iterate through animation frames)
; For each enemy, draws its 5-point trail using ob18 (read-scan)
; to check for collisions, then oab6 to draw the lines.
;----------------------------------------------------------------------------
o18ec:
  PUSH BP
  SUB SP,0x1a
  MOV BP,SP
  MOV word [BP+0x16],0
o18f7:
  MOV AX,word [BP+0x16]
  CMP AX,word [p38f6]
  JL o19o3
  JMP o1aoc
o19o3:
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p38f2]
  MOV word [BP+0x14],0
  MOV word [BP+0x18],AX
o1913:
  CMP word [BP+0x14],8
  JL o191c
  JMP o1ao6
o191c:
  MOV CL,5
  MOV AX,word [BP+0x18]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV BX,word [BP+0x16]
  SHL BX,CL
  SHL BX,1
  MOV word [BP],SI
  ADD SI,BX
  MOV DI,AX
  MOV word [BP+4],BX
  INC BX
  INC BX
  MOV CX,DI
  ADD CX,BX
  MOV BX,word [BP+4]
  ADD BX,4
  MOV DX,DI
  ADD DX,BX
  MOV AX,word [BP+4]
  ADD AX,6
  MOV BX,DI
  ADD BX,AX
  XOR AX,AX
  PUSH AX
  PUSH word [BX+p38f8]
  MOV DI,DX
  PUSH word [DI+p38f8]
  MOV DI,CX
  PUSH word [DI+p38f8]
  PUSH word [SI+p38f8]
  CALL ob18
  MOV SP,BP
  MOV word [BP+0x12],AX
  AND AX,0xf996
  JZ o197e
  MOV AX,word [BP+0x16]
  MOV word [BP+0x16],AX
  JMP o19ef
o197e:
  MOV CL,5
  MOV AX,word [BP+0x18]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV BX,word [BP+0x16]
  SHL BX,CL
  SHL BX,1
  MOV word [BP],SI
  ADD SI,BX
  MOV DI,AX
  MOV word [BP+4],BX
  INC BX
  INC BX
  MOV CX,DI
  ADD CX,BX
  MOV BX,word [BP+4]
  ADD BX,4
  MOV DX,DI
  ADD DX,BX
  MOV BX,word [BP+4]
  ADD BX,6
  MOV word [BP+0xe],BX
  MOV BX,DI
  MOV AX,word [BP+0xe]
  ADD BX,AX
  MOV AX,word [BP+4]
  ADD AX,8
  MOV word [BP+0x10],AX
  MOV AX,DI
  MOV word [BP+0xc],BX
  MOV BX,word [BP+0x10]
  ADD AX,BX
  MOV DI,AX
  PUSH word [DI+p38f8]
  MOV DI,word [BP+0xc]
  PUSH word [DI+p38f8]
  MOV DI,DX
  PUSH word [DI+p38f8]
  MOV DI,CX
  PUSH word [DI+p38f8]
  PUSH word [SI+p38f8]
  CALL oab6
  MOV SP,BP
o19ef:
  MOV AX,word [BP+0x18]
  INC AX
  CMP AX,8
  MOV word [BP+0x18],AX
  JL o1aoo
  MOV word [BP+0x18],0
o1aoo:
  INC word [BP+0x14]
  JMP o1913
o1ao6:
  INC word [BP+0x16]
  JMP o18f7
o1aoc:
  ADD SP,0x1a
  POP BP
  RET

;----------------------------------------------------------------------------
; o1a11 — Erase all enemies (XOR mode)
; Redraws all enemy trail segments using oae7 (XOR draw) to erase
; them from the screen.
;----------------------------------------------------------------------------
o1a11:
  PUSH BP
  SUB SP,0x1a
  MOV BP,SP
  XOR AX,AX
  MOV word [BP+0x16],AX
  MOV word [pcb],AX
o1a1f:
  MOV AX,word [BP+0x16]
  CMP AX,word [p38f6]
  JL o1a2b
  JMP o1ad2
o1a2b:
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p38f2]
  MOV word [BP+0x14],0
  MOV word [BP+0x18],AX
o1a3b:
  CMP word [BP+0x14],8
  JL o1a44
  JMP o1acc
o1a44:
  MOV CL,5
  MOV AX,word [BP+0x18]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV BX,word [BP+0x16]
  SHL BX,CL
  SHL BX,1
  MOV word [BP],SI
  ADD SI,BX
  MOV DI,AX
  MOV word [BP+4],BX
  INC BX
  INC BX
  MOV CX,DI
  ADD CX,BX
  MOV BX,word [BP+4]
  ADD BX,4
  MOV DX,DI
  ADD DX,BX
  MOV BX,word [BP+4]
  ADD BX,6
  MOV word [BP+0xe],BX
  MOV BX,DI
  MOV AX,word [BP+0xe]
  ADD BX,AX
  MOV AX,word [BP+4]
  ADD AX,8
  MOV word [BP+0x10],AX
  MOV AX,DI
  MOV word [BP+0xc],BX
  MOV BX,word [BP+0x10]
  ADD AX,BX
  MOV DI,AX
  PUSH word [DI+p38f8]
  MOV DI,word [BP+0xc]
  PUSH word [DI+p38f8]
  MOV DI,DX
  PUSH word [DI+p38f8]
  MOV DI,CX
  PUSH word [DI+p38f8]
  PUSH word [SI+p38f8]
  CALL oae7
  MOV SP,BP
  MOV AX,word [BP+0x18]
  INC AX
  CMP AX,8
  MOV word [BP+0x18],AX
  JL o1ac6
  MOV word [BP+0x18],0
o1ac6:
  INC word [BP+0x14]
  JMP o1a3b
o1acc:
  INC word [BP+0x16]
  JMP o1a1f
o1ad2:
  MOV word [pcb],1
  ADD SP,0x1a
  POP BP
  RET

o1add:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p38f6]
  POP BP
  RET

;----------------------------------------------------------------------------
; o1ae5 — Initialize player tail count
; Sets p3cf6 (number of tail segments) based on level:
; 1 if level < 2, else 2.
;----------------------------------------------------------------------------
o1ae5:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CALL o5891
  CMP AX,2
  JGE o1afb
  MOV word [p3cf6],1
  JMP o1bo1
o1afb:
  MOV word [p3cf6],2
o1bo1:
  CALL o1dcb
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o1bo9 — Player tail movement manager
; Moves the player's tail segments each frame. Tail follows the
; path the player has recorded. Checks for collisions with borders
; and enemies. Also handles the main game delay loop (o41c) for
; frame pacing.
;----------------------------------------------------------------------------
o1bo9:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  CALL o5891
  CMP AX,2
  JLE o1b24
  CALL o1add
  DEC AX
  JNZ o1b24
  MOV word [BP+4],2
  JMP o1b29
o1b24:
  MOV word [BP+4],1
o1b29:
  MOV word [BP+2],0
o1b2e:
  MOV AX,word [BP+2]
  CMP AX,word [BP+4]
  JGE o1ba6
  CALL o586e
  TEST AX,AX
  JZ o1b44
  XOR AX,AX
  ADD SP,8
  POP BP
  RET
o1b44:
  XOR AX,AX
  MOV word [BP+6],AX
  MOV word [p3cf4],AX
o1b4c:
  MOV AX,word [BP+6]
  CMP AX,word [p3cf6]
  JGE o1b8e
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3ce8],0
  JZ o1b73
  PUSH word [BP+6]
  CALL o1e72
  MOV SP,BP
  MOV AX,2
  PUSH AX
  CALL o41c        ;Delay don't know
  MOV SP,BP
  JMP o1b7b
o1b73:
  PUSH word [BP+6]
  CALL o1bab
  MOV SP,BP
o1b7b:
  CALL o586e
  TEST AX,AX
  JZ o1b89
  XOR AX,AX
  ADD SP,8
  POP BP
  RET
o1b89:
  INC word [BP+6]
  JMP o1b4c
o1b8e:
  CMP word [p3cf6],1
;  JNZ o1b9e       ;Speed up on level 2. Removed.
  MOV AX,2
  PUSH AX
  CALL o41c        ;Main game delay loop
  MOV SP,BP
o1b9e:
  CALL o1f6f
  INC word [BP+2]
  JMP o1b2e
o1ba6:
  ADD SP,8
  POP BP
  RET

;----------------------------------------------------------------------------
; o1bab — Single tail segment movement
; Input: tail index on stack
; Moves one tail segment along the recorded path, reads pixel at
; new position to detect collisions with borders/enemies.
;----------------------------------------------------------------------------
o1bab:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p39f8]
  MOV CX,word [SI+p39fc]
  CMP word [SI+p3aoo],1
  MOV word [p3cf2],CX
  MOV word [p3cfo],BX
  JNZ o1be9
  PUSH word [BP+0xa]
  CALL o216o
  MOV SP,BP
  PUSH word [BP+0xa]
  CALL o216o
  MOV SP,BP
  PUSH word [BP+0xa]
  CALL o216o
  MOV SP,BP
  JMP o1co1
o1be9:
  PUSH word [BP+0xa]
  CALL o2187
  MOV SP,BP
  PUSH word [BP+0xa]
  CALL o2187
  MOV SP,BP
  PUSH word [BP+0xa]
  CALL o2187
  MOV SP,BP
o1co1:
  MOV word [BP+4],9
o1co6:
  CMP word [BP+4],0
  JG o1cof
  JMP o1c8c
o1cof:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p39f8]
  MOV CX,word [SI+p39fc]
  PUSH word [SI+p3ao4]
  MOV word [p3cf2],CX
  MOV word [p3cfo],BX
  CALL o2of4
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3cf2]
  PUSH word [p3cfo]
  CALL o933
  MOV SP,BP
  AND AX,0x1001
  JZ o1c53
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV word [SI+p3cec],0
  JMP o1c8c
o1c53:
  CMP word [BP+4],1
  JNZ o1c66
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  INC word [SI+p3cec]
  JMP o1c8c
o1c66:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3aoo],1
  JNZ o1c7e
  PUSH word [BP+0xa]
  CALL o2187
  MOV SP,BP
  JMP o1c86
o1c7e:
  PUSH word [BP+0xa]
  CALL o216o
  MOV SP,BP
o1c86:
  DEC word [BP+4]
  JMP o1co6
o1c8c:
  MOV word [BP+4],8
o1c91:
  CMP word [BP+4],0
  JLE o1do7
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p39f8]
  MOV CX,word [SI+p39fc]
  PUSH word [SI+p3ao4]
  MOV word [p3cf2],CX
  MOV word [p3cfo],BX
  CALL o2of4
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3cf2]
  PUSH word [p3cfo]
  CALL o933
  MOV SP,BP
  AND AX,0x980
  JNZ o1do7
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3aoo],1
  JNZ o1ce4
  PUSH word [BP+0xa]
  CALL o2187
  MOV SP,BP
  JMP o1cec
o1ce4:
  PUSH word [BP+0xa]
  CALL o216o
  MOV SP,BP
o1cec:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p39f8]
  MOV AX,word [SI+p39fc]
  MOV word [p3cf2],AX
  MOV word [p3cfo],BX
  DEC word [BP+4]
  JMP o1c91
o1do7:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [p3cfo]
  MOV word [SI+p39f8],BX
  MOV AX,word [p3cf2]
  MOV word [SI+p39fc],AX
  CALL o5891
  PUSH AX
  CALL o227
  MOV SP,BP
  CMP AX,3
  JLE o1d4a
  CALL o5891
  MOV BX,0xc
  SUB BX,AX
  PUSH BX
  CALL o227
  MOV SP,BP
  DEC AX
  JNZ o1d4a
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3ao8],0x3a
  JL o1d58
o1d4a:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3ao8],8
  JGE o1d65
o1d58:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  INC word [SI+p3ao8]
  JMP o1d71
o1d65:
  PUSH word [BP+0xa]
  CALL o2o75
  MOV SP,BP
  OR word [p3cf4],AX
o1d71:
  PUSH word [BP+0xa]
  CALL o1fa8
  MOV SP,BP
  MOV BX,word [p3cf4]
  OR BX,AX
  MOV word [p3cf4],BX
  AND BX,0xfe7f
  JNZ o1dbd
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV BX,AX
  MOV AX,word [BX+p39f8]
  SUB AX,word [p3cf8]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,3
  JGE o1dc6
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p39fc]
  SUB AX,word [p3cfa]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,3
  JGE o1dc6
o1dbd:
  MOV AX,2
  PUSH AX
  CALL o5858
  MOV SP,BP
o1dc6:
  ADD SP,6
  POP BP
  RET

o1dcb:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV word [BP+2],0
o1dd6:
  MOV AX,word [BP+2]
  CMP AX,word [p3cf6]
  JGE o1dea
  PUSH AX
  CALL o1def
  MOV SP,BP
  INC word [BP+2]
  JMP o1dd6
o1dea:
  ADD SP,4
  POP BP
  RET

o1def:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [BP+8]
  SHL AX,1
  MOV SI,AX
  MOV word [SI+p3ce8],1
  XOR BX,BX
  MOV word [SI+p3cec],BX
  MOV BX,word [p38ca]
  MOV word [SI+p39f8],BX
  MOV AX,word [p38ce]
  MOV word [SI+p39fc],AX
  CMP word [BP+8],0
  JNZ o1e46
o1e1d:
  XOR AX,AX
  PUSH AX
  PUSH word [p39fc]
  PUSH word [p39f8]
  CALL o933
  MOV SP,BP
  AND AX,0x80
  JNZ o1e38
  DEC word [p39f8]
  JMP o1e1d
o1e38:
  MOV word [p3ao4],2
  MOV word [p3aoo],1
  JMP o1e6d
o1e46:
  XOR AX,AX
  PUSH AX
  PUSH word [p39fe]
  PUSH word [p39fa]
  CALL o933
  MOV SP,BP
  AND AX,0x80
  JNZ o1e61
  INC word [p39fa]
  JMP o1e46
o1e61:
  MOV word [p3ao6],6
  MOV word [p3ao2],2
o1e6d:
  ADD SP,4
  POP BP
  RET

o1e72:
  PUSH BP
  SUB SP,0xa
  MOV BP,SP
  MOV AX,word [BP+0xe]
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p39f8]
  SUB AX,word [p3cf8]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,0x14
  JG o1eac
  MOV AX,word [BP+0xe]
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p39fc]
  SUB AX,word [p3cfa]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,0x14
  JLE o1f2o
o1eac:
  MOV AX,word [BP+0xe]
  SHL AX,1
  MOV SI,AX
  MOV BX,1
  MOV word [SI+p3ao8],BX
  XOR BX,BX
  MOV word [SI+p3cdc],BX
  MOV word [SI+p3ceo],BX
  MOV BX,1
  MOV word [SI+p3ce4],BX
  MOV word [BP],AX
  MOV AX,word [BP+0xe]
  MOV BX,0x3c
  IMUL BX
  MOV BX,word [SI+p3cdc]
  ADD BX,AX
  MOV word [BP+4],AX
  MOV AX,BX
  MOV CX,6
  IMUL CX
  MOV BX,AX
  MOV AX,word [SI+p39f8]
  MOV word [BX+p3aoc],AX
  MOV AX,word [BP+4]
  MOV BX,word [SI+p3cdc]
  ADD BX,AX
  MOV AX,BX
  IMUL CX
  MOV BX,AX
  MOV AX,word [SI+p39fc]
  MOV word [BX+p3aoe],AX
  MOV AX,word [SI+p3cdc]
  ADD AX,word [BP+4]
  IMUL CX
  MOV BX,AX
  XOR AX,AX
  MOV word [BX+p3a1o],AX
  INC word [SI+p3cdc]
  MOV word [SI+p3ce8],AX
o1f2o:
  ADD SP,0xa
  POP BP
  RET

o1f25:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV word [BP+2],0
o1f3o:
  MOV AX,word [BP+2]
  CMP AX,word [p3cf6]
  JGE o1f44
  PUSH AX
  CALL o1f49
  MOV SP,BP
  INC word [BP+2]
  JMP o1f3o
o1f44:
  ADD SP,4
  POP BP
  RET

o1f49:
  PUSH BP
  SUB SP,6
  MOV BP,SP
o1f4f:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  MOV AX,word [SI+p3cdc]
  CMP AX,word [SI+p3ceo]
  JZ o1f6a
  PUSH word [BP+0xa]
  CALL o2o75
  MOV SP,BP
  JMP o1f4f
o1f6a:
  ADD SP,6
  POP BP
  RET

o1f6f:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV word [BP+2],0
o1f7a:
  MOV AX,word [BP+2]
  CMP AX,word [p3cf6]
  JGE o1fa3
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3cec],0x64
  JLE o1f9e
  PUSH word [BP+2]
  CALL o1f49
  MOV SP,BP
  PUSH word [BP+2]
  CALL o1def
  MOV SP,BP
o1f9e:
  INC word [BP+2]
  JMP o1f7a
o1fa3:
  ADD SP,4
  POP BP
  RET

o1fa8:
  PUSH BP
  SUB SP,0xe
  MOV BP,SP
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  CMP word [SI+p3ce4],0
  JZ o1fc3
  MOV word [BP+0xc],0xf
  JMP o1fc8
o1fc3:
  MOV word [BP+0xc],0
o1fc8:
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV word [BP],AX
  MOV AX,word [BP+0x12]
  MOV BX,0x3c
  IMUL BX
  MOV BX,word [SI+p3cdc]
  ADD BX,AX
  MOV word [BP+4],AX
  MOV AX,BX
  MOV CX,6
  IMUL CX
  MOV BX,AX
  MOV AX,word [SI+p39f8]
  MOV word [BX+p3aoc],AX
  MOV AX,word [BP+4]
  MOV BX,word [SI+p3cdc]
  ADD BX,AX
  MOV AX,BX
  IMUL CX
  MOV BX,AX
  MOV AX,word [SI+p39fc]
  MOV word [BX+p3aoe],AX
  MOV AX,word [SI+p3cdc]
  ADD AX,word [BP+4]
  IMUL CX
  MOV BX,AX
  MOV AX,word [BP+0xc]
  MOV word [BX+p3a1o],AX
  PUSH AX
  PUSH word [SI+p39fc]
  PUSH word [SI+p39f8]
  CALL o933
  MOV SP,BP
  MOV BX,word [BP+0x12]
  SHL BX,1
  INC word [BX+p3cdc]
  CMP word [BX+p3cdc],0x3c
  MOV word [BP+0xa],AX
  MOV word [BP],BX
  JL o2o47
  MOV word [BX+p3cdc],0
o2o47:
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV word [BP],AX
  CMP word [SI+p3ce4],0
  JZ o2o6o
  MOV word [SI+p3ce4],0
  JMP o2o6d
o2o6o:
  MOV AX,word [BP+0x12]
  SHL AX,1
  MOV SI,AX
  MOV word [SI+p3ce4],1
o2o6d:
  MOV AX,word [BP+0xa]
  ADD SP,0xe
  POP BP
  RET

; === PARSE.ASM ===

; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

; PUBLIC _parsecmd


_parsecmd:
  PUSH BP
  MOV BP,SP
  SUB SP,0x86
  PUSH SI
  PUSH DI
  LES BX,[BP+4]
  MOV word [BP-2],ES
  MOV word [BP-4],BX
o2363:
  JMP o2368
o2365:
  INC word [BP-4]
o2368:
  LES BX,[BP-4]
  CMP byte [es:BX],0x20
  JZ o2365
  XOR SI,SI
  JMP o2383
o2375:
  LES BX,[BP-4]
  MOV AL,byte [es:BX]
  MOV [BP+SI-0x86],AL
  INC word [BP-4]
  INC SI
o2383:
  LES BX,[BP-4]
  CMP byte [es:BX],0x20
  JZ o2392
  CMP byte [es:BX],0xd
  JNZ o2375
o2392:
  MOV byte [BP+SI-134],0
  CMP byte [BP-0x86],0x2f
  JZ o23a8
  CMP byte [BP-0x86],0x2d
  JZ o23a8
  JMP o2453
o23a8:
  CMP byte [BP-0x85],0x53
  JZ o23b6
  CMP byte [BP-0x85],0x73
  JNZ o23c5
o23b6:
  CMP byte [BP-0x84],0x3a
  JNZ o23c2
  MOV SI,3
  JMP o23c5
o23c2:
  MOV SI,2
o23c5:
  CMP byte [BP-0x85],0x53
  JZ o23d3
  CMP byte [BP-0x85],0x73
  JNZ pc_o23f9
o23d3:
  XOR DI,DI
  JMP o23ed
o23d7:
  MOV AX,DI
  MOV DX,0xa
  MUL DX
  PUSH AX
  MOV AL,[BP+SI-0x86]
  CBW
  POP DX
  ADD DX,AX
  ADD DX,-0x30
  MOV DI,DX
  INC SI
o23ed:
  CMP byte [BP+SI-0x86],0
  JNZ o23d7
  PUSH DI
  CALL _setspeedmul
  POP CX
pc_o23f9:
  CMP byte [BP-0x85],0x3f
  JZ o24oe
  CMP byte [BP-0x85],0x68
  JZ o24oe
  CMP byte [BP-0x85],0x48
  JNZ o2414
o24oe:
  CALL _printhelp
  CALL _exit
o2414:
o244o:
  CMP byte [BP-0x85],0x51
  JZ o244e
  CMP byte [BP-0x85],0x71
  JNZ o2451
o244e:
  CALL _quiet
o2451:
  CMP byte [BP-0x85],0x4E      ;'N'
  JZ .set_noimages
  CMP byte [BP-0x85],0x6E      ;'n'
  JNZ .no_noimages
.set_noimages:
  MOV byte [no_images],1
.no_noimages:
  JMP o248f
o2453:
  CMP SI,1
  JGE o245a
  JMP o248f
o245a:
  XOR DI,DI
  MOV word [BP-6],DI
  JMP o247e
o2461:
  MOV AX,DI
  MOV DX,0xa
  MUL DX
  LEA BX,word [BP-0x86]
  ADD BX,word [BP-6]
  PUSH AX
  MOV AL,byte [BX]
  CBW
  POP DX
  ADD DX,AX
  ADD DX,-0x30
  MOV DI,DX
  INC word [BP-6]
o247e:
  LEA BX,word [BP-0x86]
  ADD BX,word [BP-6]
  CMP byte [BX],0
  JNZ o2461
  PUSH DI
  CALL _setspeedmul
  POP CX
o248f:
  LES BX,[BP-4]
  CMP byte [es:BX],0xd
  JZ o249b
  JMP o2363
o249b:
  POP DI
  POP SI
  MOV SP,BP
  POP BP
  RET

; === STYX2.ASM ===

; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

; PUBLIC o2o75,o2of4,o216o,o2187,o21ad,o21do,o2325,o235f,o24be
; PUBLIC o2868,o287b,o289b,o28bc,o28dd,o28fe,o297a,o2beb,o2df5,o2e61,o2e7b,o2e98
; PUBLIC o2efe,o2ff4,o2fff,o3o23,o3o47,o3o68,o3o89,o3ofa,o3167,o3172,o319b,o31c8
; PUBLIC o3229,o3296,o33oo,o3339,o3372,o33af,o33df,o33fb,o34o6,o3411,o3424,o3437
; PUBLIC o34c3,o3575,o35ee,o364c,o37oo,o37a2,o37aa,o37cf,o38d8,o38ef,o3963
; PUBLIC o3aof,o3a65,o3bd3,o3cc3,o3ce6,o3d8b,o3dc8,o3e6d,o3f24,o3fb8,o4o9a,o415b
; PUBLIC o41f3,o42d1,o4356,o435e


o2o75:
  PUSH BP
  SUB SP,0x10
  MOV BP,SP
  MOV AX,word [BP+0x14]
  SHL AX,1
  MOV SI,AX
  MOV word [BP],AX
  MOV AX,word [BP+0x14]
  MOV BX,0x3c
  IMUL BX
  MOV BX,word [SI+p3ceo]
  ADD BX,AX
  MOV word [BP+4],AX
  MOV AX,BX
  MOV CX,6
  IMUL CX
  MOV BX,AX
  MOV AX,word [BP+4]
  MOV CX,word [SI+p3ceo]
  ADD CX,AX
  MOV AX,CX
  MOV DX,6
  IMUL DX
  MOV DI,AX
  MOV AX,word [SI+p3ceo]
  ADD AX,word [BP+4]
  MOV CX,6
  IMUL CX
  MOV SI,AX
  PUSH word [SI+p3a1o]
  PUSH word [DI+p3aoe]
  PUSH word [BX+p3aoc]
  CALL o933
  MOV SP,BP
  MOV BX,word [BP+0x14]
  SHL BX,1
  INC word [BX+p3ceo]
  CMP word [BX+p3ceo],0x3c
  MOV word [BP+0xe],AX
  MOV word [BP],BX
  JL o2oec
  MOV word [BX+p3ceo],0
o2oec:
  MOV AX,word [BP+0xe]
  ADD SP,0x10
  POP BP
  RET

o2of4:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  JMP o214e
o2ofc:
  INC word [p3cfo]
  JMP o215e
o21o2:
  INC word [p3cfo]
  DEC word [p3cf2]
  JMP o215e
o21oc:
  DEC word [p3cf2]
  JMP o215e
o2112:
  DEC word [p3cfo]
  DEC word [p3cf2]
  JMP o215e
o211c:
  DEC word [p3cfo]
  JMP o215e
o2122:
  DEC word [p3cfo]
  INC word [p3cf2]
  JMP o215e
o212c:
  INC word [p3cf2]
  JMP o215e
o2132:
  INC word [p3cfo]
  INC word [p3cf2]
  JMP o215e

o213e:
  DW o2ofc,o21o2,o21oc,o2112,o211c
  DW o2122,o212c,o2132

o214e:
  MOV SI,AX
  CMP SI,8
  JNB o215e
  SHL SI,1
  JMP word [cs:SI+o213e]
o215e:
  POP BP
  RET

o216o:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [BP+8]
  SHL AX,1
  MOV SI,AX
  DEC word [SI+p3ao4]
  MOV BX,word [SI+p3ao4]
  TEST BX,BX
  MOV word [BP],AX
  JNS o2182
  MOV word [SI+p3ao4],7
o2182:
  ADD SP,4
  POP BP
  RET

o2187:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [BP+8]
  SHL AX,1
  MOV SI,AX
  INC word [SI+p3ao4]
  CMP word [SI+p3ao4],7
  MOV word [BP],AX
  JLE o21a8
  MOV word [SI+p3ao4],0
o21a8:
  ADD SP,4
  POP BP
  RET

o21ad:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV word [p3d1o],0x50
  MOV word [p3d12],0x61
  MOV AX,2
  MOV word [p3d16],AX
  MOV word [p3d14],AX
  CALL o2325
  ADD SP,2
  POP BP
  RET

o21do:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o586e
  TEST AX,AX
  JZ o21e4
  XOR AX,AX
  ADD SP,6
  POP BP
  RET
o21e4:
  CALL o35ee
  CMP word [p3do4],1
  JZ o21f1
  JMP o2311
o21f1:
  CMP word [p3do2],0
  JZ o21fb
  JMP o2311
o21fb:
  CALL o37oo
  CMP AX,0x63
  MOV word [BP+4],AX
  JL o22o9
  JMP o2311
o22o9:
  MOV AX,word [p3doo]
  MOV word [p3doe],AX
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  MOV AX,word [p3doe]
  CMP AX,word [BP+4]
  JNZ o2226
  CALL o287b
o2226:
  CALL o37a2
  TEST AX,AX
  JNZ o223o
  JMP o2311
o223o:
  CMP word [p3d16],2
  JNZ o2275
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [p3doo]
  MOV word [p3doa],AX
  MOV word [p3doe],CX
  MOV word [p3doc],BX
  CALL o2e7b
  PUSH word [p3doe]
  CALL o2df5
  MOV SP,BP
  CALL o2e61
  PUSH word [p3doe]
  CALL o2df5
  MOV SP,BP
  MOV AX,word [p3doa]
  MOV BX,word [p3doc]
  MOV word [p3d1c],AX
  MOV word [p3d1e],BX
  JMP o22b1
o2275:
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [p3doo]
  MOV word [p3doa],AX
  MOV word [p3doe],CX
  MOV word [p3doc],BX
  CALL o2e61
  PUSH word [p3doe]
  CALL o2df5
  MOV SP,BP
  CALL o2e7b
  PUSH word [p3doe]
  CALL o2df5
  MOV SP,BP
  MOV AX,word [p3doa]
  MOV BX,word [p3doc]
  MOV word [p3d1c],AX
  MOV word [p3d1e],BX
o22b1:
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [BP+4]
  PUSH CX
  MOV word [p3doa],AX
  MOV word [p3doe],CX
  MOV word [p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV word [BP+2],AX
  AND AX,0x1001
  JZ o2311
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [p3doo]
  XOR DX,DX
  MOV word [p3d1o],AX
  MOV AX,word [p3doe]
  MOV word [p3do8],AX
  MOV word [p3doo],AX
  MOV word [p3d14],CX
  MOV word [p3d1a],DX
  MOV word [p3do6],DX
  MOV word [p3do4],DX
  MOV word [p3d12],BX
o2311:
  CMP word [p3do4],1
  JNZ o231d
  CALL o235f
  JMP o232o
o231d:
  CALL o24be
o232o:
  ADD SP,6
  POP BP
  RET

o2325:
  PUSH BP
  MOV BP,SP
  CALL o35ee
  MOV AX,1
  XOR BX,BX
  MOV CX,word [p3d1o]
  MOV DX,word [p3d12]
  MOV word [p3do4],AX
  MOV word [p3do2],AX
  MOV AX,word [p3d14]
  MOV byte [pbb],0
  MOV word [p3doo],AX
  MOV word [p3cf8],CX
  MOV word [p3cfa],DX
  MOV word [p3d22],BX
  MOV word [p3d18],BX
  MOV word [p3do6],BX
  POP BP
  RET

o235f:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o45d7
  MOV word [p3d18],0
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [p3doo]
  CMP word [p3d16],2
  MOV word [p3cfc],AX
  MOV word [p3doa],AX
  MOV word [p3doe],CX
  MOV word [p3cfe],BX
  MOV word [p3doc],BX
  JNZ o239d
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  JMP o23a6
o239d:
  CALL o2e61
  CALL o2e61
  CALL o2e61
o23a6:
  MOV word [BP+2],8
o23ab:
  CMP word [BP+2],0
  JLE o23f4
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  PUSH word [p3doe]
  MOV word [p3doa],AX
  MOV word [p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV word [BP+4],AX
  AND AX,0x1001
  JNZ o23f4
  CMP word [p3d16],2
  JNZ o23ec
  CALL o2e61
  JMP o23ef
o23ec:
  CALL o2e7b
o23ef:
  DEC word [BP+2]
  JMP o23ab
o23f4:
  MOV word [BP+2],8
o23f9:
  CMP word [BP+2],0
  JLE o245o
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  PUSH word [p3doe]
  MOV word [p3doa],AX
  MOV word [p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV word [BP+4],AX
  AND AX,0x880
  JNZ o245o
  CMP word [p3d16],2
  JNZ o243a
  CALL o2e61
  JMP o243d
o243a:
  CALL o2e7b
o243d:
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV word [p3doa],AX
  MOV word [p3doc],BX
  DEC word [BP+2]
  JMP o23f9
o245o:
  CMP word [p3do2],0
  JZ o245c
  CALL o2beb
  JMP o2475
o245c:
  MOV AX,word [p3doa]
  MOV BX,word [p3doc]
  MOV CX,word [p3doe]
  MOV word [p3cf8],AX
  MOV word [p3doo],CX
  MOV word [p3cfa],BX
  CALL o28dd
o2475:
  CALL o28bc
  MOV word [BP+4],AX
  AND AX,0x668
  JZ o2483
  CALL o28fe
o2483:
  MOV AX,word [BP+4]
  AND AX,0x100
  JZ o2496
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
  JMP o24ac
o2496:
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [p3doo]
  MOV word [p3d1o],AX
  MOV word [p3d14],CX
  MOV word [p3d12],BX
o24ac:
  CMP word [p3do2],0
  JZ o24b9
  MOV word [p3do2],0
o24b9:
  ADD SP,6
  POP BP
  RET

o24be:
  PUSH BP
  SUB SP,0xe
  MOV BP,SP
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV CX,word [p3doo]
  MOV word [p3cfc],AX
  MOV word [p3doa],AX
  MOV word [p3doe],CX
  MOV word [p3cfe],BX
  MOV word [p3doc],BX
  CALL o37a2
  TEST AX,AX
  JZ o24fo
  CALL o37oo
  MOV word [BP+0xa],AX
  JMP o24f5
o24fo:
  MOV word [BP+0xa],0x63
o24f5:
  MOV AX,word [BP+0xa]
  CMP AX,0x63
  JGE o251a
  MOV word [p3doe],AX
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  MOV AX,word [p3doe]
  CMP AX,word [p3do8]
  JNZ o251a
  MOV word [BP+0xa],0x63
o251a:
  MOV AX,word [BP+0xa]
  CMP AX,0x63
  JGE o2561
  MOV word [p3doe],AX
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  MOV AX,word [p3doe]
  CMP AX,word [p3do8]
  JNZ o254o
  CALL o2e61
  MOV AX,word [p3doe]
  MOV word [BP+0xa],AX
o254o:
  MOV AX,word [BP+0xa]
  MOV word [p3doe],AX
  CALL o2e61
  CALL o2e61
  CALL o2e61
  MOV AX,word [p3doe]
  CMP AX,word [p3do8]
  JNZ o2561
  CALL o2e7b
  MOV AX,word [p3doe]
  MOV word [BP+0xa],AX
o2561:
  MOV AX,word [p3doo]
  CMP word [p3do6],0
  MOV word [p3doe],AX
  JNZ o257a
  CMP word [BP+0xa],0x63
  JGE o257a
  MOV AX,word [BP+0xa]
  MOV word [p3doe],AX
o257a:
  CMP word [BP+0xa],0x63
  JNZ o258c
  CMP word [p3do6],0
  JNZ o258c
  CALL o2868
  JMP o25d2
o258c:
  PUSH word [p3doe]
  CALL o2df5
  MOV SP,BP
  MOV AX,word [p3doa]
  MOV BX,word [p3doc]
  XOR CX,CX
  PUSH CX
  PUSH BX
  PUSH AX
  MOV word [BP+6],AX
  MOV word [BP+8],BX
  CALL o933
  MOV SP,BP
  AND AX,0x880
  JZ o25bd
  MOV word [p3do4],1
  MOV word [p3do6],0
o25bd:
  MOV AX,word [BP+6]
  MOV BX,word [BP+8]
  MOV CX,word [p3doe]
  MOV word [p3cf8],AX
  MOV word [p3doo],CX
  MOV word [p3cfa],BX
o25d2:
  MOV AX,word [p3doo]
  MOV word [p3doe],AX
  MOV word [BP+0xa],AX
  CALL o2e61
  MOV word [BP+0xc],0
o25e3:
  CMP word [BP+0xc],3
  JGE o264e
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  PUSH word [p3doe]
  MOV word [p3doa],AX
  MOV word [p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  PUSH word [p3doe]
  MOV word [BP+4],AX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV BX,word [BP+4]
  OR BX,AX
  MOV word [BP+4],BX
  AND BX,0x880
  JZ o2646
  MOV AX,word [p3doe]
  MOV word [p3do6],1
  MOV word [BP+0xa],AX
o2646:
  CALL o2e7b
  INC word [BP+0xc]
  JMP o25e3
o264e:
  MOV AX,word [p3doo]
  MOV BX,word [p3cf8]
  MOV CX,word [p3cfa]
  PUSH AX
  MOV word [p3doe],AX
  MOV word [p3doc],CX
  MOV word [p3doa],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  PUSH word [p3doe]
  MOV word [BP+4],AX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV BX,word [BP+4]
  OR BX,AX
  MOV word [BP+4],BX
  AND BX,0x880
  JZ o26bo
  MOV AX,word [p3doe]
  MOV word [p3do6],1
  MOV word [BP+0xa],AX
o26bo:
  MOV AX,word [p3doo]
  MOV word [p3doe],AX
  CALL o2e61
  MOV word [BP+0xc],0
o26be:
  CMP word [BP+0xc],3
  JGE o27o7
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  PUSH word [p3doe]
  MOV word [p3doa],AX
  MOV word [p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV word [BP+4],AX
  AND AX,0x880
  JZ o26ff
  MOV AX,word [p3doe]
  MOV word [p3do6],1
  MOV word [BP+0xa],AX
o26ff:
  CALL o2e7b
  INC word [BP+0xc]
  JMP o26be
o27o7:
  MOV AX,word [p3doo]
  MOV BX,word [p3cf8]
  MOV CX,word [p3cfa]
  PUSH AX
  MOV word [p3doe],AX
  MOV word [p3doc],CX
  MOV word [p3doa],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [p3doc]
  PUSH word [p3doa]
  CALL o933
  MOV SP,BP
  MOV word [BP+4],AX
  AND AX,0x880
  JZ o2747
  MOV AX,word [p3doe]
  MOV word [p3do6],1
  MOV word [BP+0xa],AX
o2747:
  MOV AX,word [BP+0xa]
  MOV word [p3doo],AX
  CALL o289b
  AND AX,0x8000
  JZ o276d
  CMP word [p3do6],0
  JNZ o276d
  MOV AX,word [p3cfc]
  MOV BX,word [p3cfe]
  MOV word [p3cf8],AX
  MOV word [p3cfa],BX
  CALL o2868
o276d:
  CALL o28dd
  CMP word [p3do4],0
  JNZ o27e1
  MOV AX,word [p3doo]
  XOR BX,BX
  PUSH BX
  PUSH word [p3cfa]
  PUSH word [p3cf8]
  MOV word [p3do8],AX
  CALL o933
  MOV SP,BP
  AND AX,1
  JNZ o2795
  JMP o283f
o2795:
  MOV AX,0xf
  PUSH AX
  PUSH word [p3cfa]
  PUSH word [p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,word [p3d1a]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [p3cf8]
  MOV word [SI+p3d24],BX
  MOV AX,word [p3cfa]
  MOV word [SI+p4cc4],AX
  MOV AX,word [p3d1a]
  INC AX
  CMP AX,2000
  MOV word [p3d1a],AX
  JL o27d1
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
o27d1:
  MOV AX,word [p3d18]
  TEST AX,AX
  JZ o27dc
  DEC word [p3d18]
o27dc:
  CALL o45d7
  JMP o283f
o27e1:
  CMP word [p3d1a],1
  JLE o2824
  MOV AX,word [p3cfc]
  MOV BX,word [p3cfe]
  MOV byte [pbb],0
  MOV word [p3d18],0
  MOV word [p3cf8],AX
  MOV word [p3cfa],BX
  CALL o2efe
  XOR AX,AX
  PUSH AX
  PUSH word [p3d1e]
  PUSH word [p3d1c]
  CALL o933
  MOV SP,BP
  AND AX,0x96
  JNZ o281c
  CALL o287b
o281c:
  MOV word [p3d22],0
  JMP o283f
o2824:
  CALL o2e98
  CMP word [p3d22],0
  JZ o2839
  CALL o287b
  MOV word [p3d22],0
  JMP o283f
o2839:
  MOV word [p3d22],1
o283f:
  CMP word [p3d18],0x64
  JLE o284f
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
o284f:
  CALL o28bc
  MOV word [BP+4],AX
  AND AX,0x768
  JZ o2863
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
o2863:
  ADD SP,0xe
  POP BP
  RET

o2868:
  PUSH BP
  MOV BP,SP
  ADD word [p3d18],5
  PUSH word [p3d18]
  CALL o462o
  MOV SP,BP
  POP BP
  RET

o287b:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p3d16],2
  JNZ o289o
  MOV word [p3d16],1
  JMP o2896
o289o:
  MOV word [p3d16],2
o2896:
  ADD SP,2
  POP BP
  RET

o289b:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,word [p3cf8]
  DEC AX
  DEC AX
  MOV BX,word [p3cfa]
  DEC BX
  DEC BX
  MOV CX,p5c7f
  PUSH CX
  PUSH BX
  PUSH AX
  CALL oc63
  MOV SP,BP
  ADD SP,6
  POP BP
  RET

o28bc:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,word [p3cf8]
  DEC AX
  DEC AX
  MOV BX,word [p3cfa]
  DEC BX
  DEC BX
  MOV CX,p5c64
  PUSH CX
  PUSH BX
  PUSH AX
  CALL oc63
  MOV SP,BP
  ADD SP,6
  POP BP
  RET

o28dd:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p3cfc]
  DEC AX
  DEC AX
  MOV BX,word [p3cfe]
  DEC BX
  DEC BX
  MOV CX,p5c64
  PUSH CX
  PUSH BX
  PUSH AX
  CALL oc63
  MOV SP,BP
  ADD SP,4
  POP BP
  RET

o28fe:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  CALL o3o47
  MOV AX,2
  MOV BX,word [p3cfa]
  DEC BX
  DEC BX
  MOV word [BP+6],AX
  MOV word [BP+4],BX
o2916:
  MOV AX,word [p3cfa]
  ADD AX,3
  MOV BX,word [BP+4]
  CMP BX,AX
  JGE o2972
  MOV AX,word [p3cf8]
  DEC AX
  DEC AX
  MOV word [BP+2],AX
o292b:
  MOV AX,word [p3cf8]
  ADD AX,3
  MOV BX,word [BP+2]
  CMP BX,AX
  JGE o296d
  XOR AX,AX
  PUSH AX
  PUSH word [BP+4]
  PUSH BX
  CALL o933
  MOV SP,BP
  AND AX,0x668
  JZ o2965
  MOV SI,word [BP+6]
  MOV AL,byte [SI+p5c64]
  XOR AH,AH
  CMP AX,0xc
  JNZ o2965
  XOR AX,AX
  PUSH AX
  PUSH word [BP+4]
  PUSH word [BP+2]
  CALL o9ob
  MOV SP,BP
o2965:
  INC word [BP+6]
  INC word [BP+2]
  JMP o292b
o296d:
  INC word [BP+4]
  JMP o2916
o2972:
  CALL o3o68
  ADD SP,8
  POP BP
  RET

o297a:
  PUSH BP
  SUB SP,0x34
  MOV BP,SP
  CALL o48bd
  CMP word [p3do2],0
  JZ o298d
  JMP o2be6
o298d:
  CALL o28bc
  MOV AX,2
  MOV word [BP+0xe],AX
  MOV BX,2
  CWD
  IDIV BX
  MOV word [BP+0xc],AX
  MOV AX,BX
  MOV word [BP+0x12],AX
  CWD
  IDIV BX
  MOV BX,word [p3cf8]
  MOV CX,word [p3cfa]
  XOR DX,DX
  MOV word [BP+0x10],AX
  MOV word [BP+0x32],CX
  MOV word [BP+0x2e],CX
  MOV word [BP+0x2a],CX
  MOV word [BP+0x26],CX
  MOV word [BP+0x22],CX
  MOV word [BP+0x1e],CX
  MOV word [BP+0x1a],CX
  MOV word [BP+0x16],CX
  MOV word [BP+8],DX
  MOV word [BP+0xa],DX
  MOV word [BP+0x30],BX
  MOV word [BP+0x2c],BX
  MOV word [BP+0x28],BX
  MOV word [BP+0x24],BX
  MOV word [BP+0x20],BX
  MOV word [BP+0x1c],BX
  MOV word [BP+0x18],BX
  MOV word [BP+0x14],BX
o29ea:
  CMP word [BP+0xa],0x2d
  JL o29f3
  JMP o2beo
o29f3:
  CMP word [BP+8],0x2d
  JL o29fc
  JMP o2ae8
o29fc:
  MOV AX,word [BP+0x14]
  INC AX
  INC AX
  MOV BX,word [BP+0x16]
  INC BX
  INC BX
  ADD word [BP+0x18],2
  SUB word [BP+0x1a],2
  SUB word [BP+0x1c],2
  SUB word [BP+0x1e],2
  SUB word [BP+0x20],2
  ADD word [BP+0x22],2
  MOV word [BP+0x14],AX
  MOV AX,word [BP+0xe]
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,word [BP+0x14]
  MOV word [BP+0xc],AX
  ADD AX,CX
  MOV DX,word [BP+0xc]
  MOV word [BP+0x16],BX
  SUB BX,DX
  SUB CX,DX
  MOV word [BP],AX
  MOV AX,word [BP+0x16]
  ADD AX,DX
  MOV DX,0xc
  PUSH DX
  PUSH AX
  PUSH CX
  PUSH BX
  PUSH word [BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0xc]
  MOV BX,word [BP+0x18]
  SUB BX,AX
  MOV CX,word [BP+0x1a]
  SUB CX,AX
  MOV DX,word [BP+0x18]
  ADD DX,AX
  MOV word [BP],BX
  MOV BX,word [BP+0x1a]
  ADD BX,AX
  MOV AX,0xc
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH word [BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0x1c]
  MOV BX,word [BP+0xc]
  ADD BX,AX
  MOV CX,word [BP+0xc]
  MOV DX,word [BP+0x1e]
  SUB DX,CX
  SUB AX,CX
  MOV word [BP+4],AX
  MOV AX,word [BP+0x1e]
  ADD AX,CX
  MOV CX,0xc
  PUSH CX
  PUSH AX
  PUSH word [BP+4]
  PUSH DX
  PUSH BX
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0xc]
  MOV BX,word [BP+0x20]
  SUB BX,AX
  MOV CX,word [BP+0x22]
  SUB CX,AX
  MOV DX,word [BP+0x20]
  ADD DX,AX
  MOV word [BP],BX
  MOV BX,word [BP+0x22]
  ADD BX,AX
  MOV AX,0xc
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH word [BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0xe]
  CMP AX,0x1e
  JGE o2ae5
  INC word [BP+0xe]
o2ae5:
  INC word [BP+8]
o2ae8:
  CMP word [BP+8],0x10
  JG o2af1
  JMP o29ea
o2af1:
  MOV AX,word [BP+0x24]
  INC AX
  INC AX
  MOV BX,word [BP+0x26]
  INC BX
  INC BX
  ADD word [BP+0x28],2
  SUB word [BP+0x2a],2
  SUB word [BP+0x2c],2
  SUB word [BP+0x2e],2
  SUB word [BP+0x30],2
  ADD word [BP+0x32],2
  MOV word [BP+0x24],AX
  MOV AX,word [BP+0x12]
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,word [BP+0x24]
  MOV word [BP+0x10],AX
  ADD AX,CX
  MOV DX,word [BP+0x10]
  MOV word [BP+0x26],BX
  SUB BX,DX
  SUB CX,DX
  MOV word [BP],AX
  MOV AX,word [BP+0x26]
  ADD AX,DX
  MOV DX,0xc
  PUSH DX
  PUSH AX
  PUSH CX
  PUSH BX
  PUSH word [BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0x10]
  MOV BX,word [BP+0x28]
  SUB BX,AX
  MOV CX,word [BP+0x2a]
  SUB CX,AX
  MOV DX,word [BP+0x28]
  ADD DX,AX
  MOV word [BP],BX
  MOV BX,word [BP+0x2a]
  ADD BX,AX
  MOV AX,0xc
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH word [BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0x2c]
  MOV BX,word [BP+0x10]
  ADD BX,AX
  MOV CX,word [BP+0x10]
  MOV DX,word [BP+0x2e]
  SUB DX,CX
  SUB AX,CX
  MOV word [BP+4],AX
  MOV AX,word [BP+0x2e]
  ADD AX,CX
  MOV CX,0xc
  PUSH CX
  PUSH AX
  PUSH word [BP+4]
  PUSH DX
  PUSH BX
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0x10]
  MOV BX,word [BP+0x30]
  SUB BX,AX
  MOV CX,word [BP+0x32]
  SUB CX,AX
  MOV DX,word [BP+0x30]
  ADD DX,AX
  MOV word [BP],BX
  MOV BX,word [BP+0x32]
  ADD BX,AX
  MOV AX,0xc
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH word [BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,word [BP+0x12]
  CMP AX,0x1e
  JGE o2bda
  INC word [BP+0x12]
o2bda:
  INC word [BP+0xa]
  JMP o29ea
o2beo:
  CALL o2325
  CALL o2e98
o2be6:
  ADD SP,0x34
  POP BP
  RET

o2beb:
  PUSH BP
  SUB SP,0x2a
  MOV BP,SP
  CALL o49oa
  CMP word [p3do2],0
  JNZ o2bfe
  JMP o2dfo
o2bfe:
  MOV AX,word [p3cf8]
  MOV BX,word [p3cfa]
  MOV word [BP+2],0
  MOV word [BP+0x26],AX
  MOV word [BP+0x22],AX
  MOV word [BP+0x1e],AX
  MOV word [BP+0x1a],AX
  MOV word [BP+0x16],AX
  MOV word [BP+0x12],AX
  MOV word [BP+0xe],AX
  MOV word [BP+0xa],AX
  MOV word [BP+0x28],BX
  MOV word [BP+0x24],BX
  MOV word [BP+0x20],BX
  MOV word [BP+0x1c],BX
  MOV word [BP+0x18],BX
  MOV word [BP+0x14],BX
  MOV word [BP+0x10],BX
  MOV word [BP+0xc],BX
o2c3a:
  CMP word [BP+2],0x28
  JGE o2c85
  ADD word [BP+0xa],2
  ADD word [BP+0xc],2
  ADD word [BP+0xe],2
  SUB word [BP+0x10],2
  SUB word [BP+0x12],2
  SUB word [BP+0x14],2
  SUB word [BP+0x16],2
  ADD word [BP+0x18],2
  ADD word [BP+0x1a],2
  ADD word [BP+0x1c],2
  ADD word [BP+0x1e],2
  SUB word [BP+0x20],2
  SUB word [BP+0x22],2
  SUB word [BP+0x24],2
  SUB word [BP+0x26],2
  ADD word [BP+0x28],2
  INC word [BP+2]
  JMP o2c3a
o2c85:
  MOV AX,0x28
  MOV word [BP+2],AX
  MOV word [BP+4],AX
o2c8e:
  CMP word [BP+4],0
  JNZ o2c97
  JMP o2dfo
o2c97:
  CMP word [BP+2],0
  JNZ o2cao
  JMP o2d42
o2cao:
  SUB word [BP+0xa],2
  SUB word [BP+0xc],2
  SUB word [BP+0xe],2
  ADD word [BP+0x10],2
  ADD word [BP+0x12],2
  ADD word [BP+0x14],2
  ADD word [BP+0x16],2
  SUB word [BP+0x18],2
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0xc]
  PUSH word [BP+0xa]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [p3cfa]
  PUSH word [BP+0xa]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x10]
  PUSH word [BP+0xe]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x10]
  PUSH word [p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x14]
  PUSH word [BP+0x12]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [p3cfa]
  PUSH word [BP+0x12]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x18]
  PUSH word [p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x18]
  PUSH word [BP+0x16]
  CALL o933
  MOV SP,BP
  CALL o492a
  DEC word [BP+2]
o2d42:
  CMP word [BP+2],0x14
  JL o2d4b
  JMP o2c8e
o2d4b:
  SUB word [BP+0x1a],2
  SUB word [BP+0x1c],2
  SUB word [BP+0x1e],2
  ADD word [BP+0x20],2
  ADD word [BP+0x22],2
  ADD word [BP+0x24],2
  ADD word [BP+0x26],2
  SUB word [BP+0x28],2
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x1c]
  PUSH word [BP+0x1a]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [p3cfa]
  PUSH word [BP+0x1a]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x20]
  PUSH word [BP+0x1e]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x20]
  PUSH word [p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x24]
  PUSH word [BP+0x22]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [p3cfa]
  PUSH word [BP+0x22]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x28]
  PUSH word [p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0xc
  PUSH AX
  PUSH word [BP+0x28]
  PUSH word [BP+0x26]
  CALL o933
  MOV SP,BP
  CALL o492a
  DEC word [BP+4]
  JMP o2c8e
o2dfo:
  ADD SP,0x2a
  POP BP
  RET

o2df5:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  JMP o2e4f
o2dfd:
  INC word [p3doa]
  JMP o2e5f
o2eo3:
  INC word [p3doa]
  DEC word [p3doc]
  JMP o2e5f
o2eod:
  DEC word [p3doc]
  JMP o2e5f
o2e13:
  DEC word [p3doa]
  DEC word [p3doc]
  JMP o2e5f
o2e1d:
  DEC word [p3doa]
  JMP o2e5f
o2e23:
  DEC word [p3doa]
  INC word [p3doc]
  JMP o2e5f
o2e2d:
  INC word [p3doc]
  JMP o2e5f
o2e33:
  INC word [p3doa]
  INC word [p3doc]
  JMP o2e5f

o2e3f:
  DW o2dfd,o2eo3,o2eod,o2e13,o2e1d
  DW o2e23,o2e2d,o2e33

o2e4f:
  MOV SI,AX
  CMP SI,8
  JNB o2e5f
  SHL SI,1
  JMP word [cs:SI+o2e3f]
o2e5f:
  POP BP
  RET

o2e61:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p3doe]
  DEC AX
  MOV word [p3doe],AX
  JGE o2e76
  MOV word [p3doe],7
o2e76:
  ADD SP,2
  POP BP
  RET

o2e7b:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p3doe]
  INC AX
  CMP AX,7
  MOV word [p3doe],AX
  JLE o2e93
  MOV word [p3doe],0
o2e93:
  ADD SP,2
  POP BP
  RET

o2e98:
  PUSH BP
  SUB SP,0xe
  MOV BP,SP
  MOV word [BP+0xa],0
o2ea3:
  MOV AX,word [p3d1a]
  MOV BX,word [BP+0xa]
  CMP BX,AX
  JGE o2ef9
  TEST AX,AX
  JLE o2ef9
  SHL BX,1
  XOR AX,AX
  PUSH AX
  PUSH word [BX+p4cc4]
  PUSH word [BX+p3d24]
  CALL o9ob
  MOV SP,BP
  MOV word [BP+0xc],AX
  AND AX,0x8080
  JNZ o2ef4
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV SI,AX
  PUSH word [BP+0xc]
  MOV word [BP+4],SI
  MOV word [BP+2],SI
  CALL o34c3
  MOV SP,BP
  PUSH AX
  MOV SI,word [BP+4]
  PUSH word [SI+p4cc4]
  MOV SI,word [BP+2]
  PUSH word [SI+p3d24]
  CALL o9ob
  MOV SP,BP
o2ef4:
  INC word [BP+0xa]
  JMP o2ea3
o2ef9:
  ADD SP,0xe
  POP BP
  RET

o2efe:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  CALL o4631
  MOV word [BP+8],0
o2foc:
  MOV AX,word [BP+8]
  CMP AX,word [p3d1a]
  JGE o2f2f
  SHL AX,1
  MOV SI,AX
  MOV AX,7
  PUSH AX
  PUSH word [SI+p4cc4]
  PUSH word [SI+p3d24]
  CALL o9ob
  MOV SP,BP
  INC word [BP+8]
  JMP o2foc
o2f2f:
  MOV word [pd1],0
  CALL o18ec
  CALL o1a11
  PUSH word [p3d2o]
  CALL o64o
  MOV SP,BP
  MOV word [pcb],0
  PUSH word [p3d2o]
  PUSH word [p38ce]
  PUSH word [p38ca]
  CALL o9ob
  MOV SP,BP
  CALL o46ca
  CALL o46ca
  CALL o46ca
  CALL o46ca
  CALL o46ca
  CALL o46ca
  CALL o46ca
  MOV AX,7
  PUSH AX
  XOR AX,AX
  PUSH AX
  PUSH word [p38ce]
  PUSH word [p38ca]
  CALL o3o89
  MOV SP,BP
  CALL o47o7
  CALL o47o7
  CALL o47o7
  CALL o47o7
  CALL o18bf
  CALL o18ec
  MOV word [pcb],1
  CALL o5c3
  MOV AX,word [pd1]
  ADD AX,word [p3d1a]
  MOV word [pd1],AX
  CALL o5d66
  MOV SI,p5c9a
  PUSH SI
  CALL o5ca2
  MOV SI,p5ca2
  PUSH SI
  CALL o5993
  LEA SI,word [BP]
  MOV word [SI+6],AX
  MOV word [SI+4],BX
  MOV word [SI+2],CX
  MOV word [SI],DX
  MOV SI,p5caa
  MOV AX,word [SI+6]
  MOV BX,word [SI+4]
  MOV CX,word [SI+2]
  MOV DX,word [SI]
  LEA SI,word [BP]
  PUSH SI
  CALL o5f1b
  CALL o5dce
  PUSH AX
  MOV word [BP+8],AX
  CALL o3963
  MOV SP,BP
  MOV word [p3d1a],0
  ADD SP,0xc
  POP BP
  RET

o2ff4:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [p3d2o],AX
  POP BP
  RET

o2fff:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  MOV BX,7
  IMUL BX
  ADD AX,0x1e
  MOV BX,p5c7f
  PUSH BX
  MOV BX,2
  PUSH BX
  PUSH AX
  CALL oc43
  MOV SP,BP
  ADD SP,2
  POP BP
  RET

o3o23:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  MOV BX,7
  IMUL BX
  ADD AX,0x1e
  MOV BX,p5c64
  PUSH BX
  MOV BX,2
  PUSH BX
  PUSH AX
  CALL oc43
  MOV SP,BP
  ADD SP,2
  POP BP
  RET

o3o47:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p3cf8]
  DEC AX
  DEC AX
  MOV BX,word [p3cfa]
  DEC BX
  DEC BX
  MOV CX,p5c64
  PUSH CX
  PUSH BX
  PUSH AX
  CALL oc63
  MOV SP,BP
  ADD SP,4
  POP BP
  RET

o3o68:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p3cf8]
  DEC AX
  DEC AX
  MOV BX,word [p3cfa]
  DEC BX
  DEC BX
  MOV CX,p5c64
  PUSH CX
  PUSH BX
  PUSH AX
  CALL oc63
  MOV SP,BP
  ADD SP,4
  POP BP
  RET

o3o89:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  XOR AX,AX
  MOV BX,word [BP+6]
  MOV CX,word [BP+8]
  PUSH word [BP+0xc]
  MOV word [p5cd6],AX
  MOV word [p5cd4],AX
  MOV word [p5cb4],CX
  MOV word [p5cb2],BX
  CALL o3437
  MOV SP,BP
  MOV BX,word [BP+0xa]
  PUSH BX
  MOV word [p5cca],AX
  MOV word [p5cc2],BX
  CALL o3437
  MOV SP,BP
  XOR BX,BX
  PUSH BX
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  MOV word [p5cc6],AX
  CALL o933
  MOV SP,BP
  PUSH AX
  MOV word [p5cc8],AX
  CALL o34c3
  MOV SP,BP
  MOV word [p5ccc],0
  MOV BX,word [p5cc8]
  CMP BX,word [p5cc6]
  MOV word [p5cc4],AX
  JZ o3of2
  AND BX,0x8080
  JZ o3ofa
o3of2:
  MOV AX,1
  ADD SP,2
  POP BP
  RET

o3ofa:
  MOV AX,word [p5cb4]
  MOV word [p5cbc],AX
  CALL o3372
o31o3:
  CALL o33df
  TEST AX,AX
  JZ o315f
  CALL o33af
  XOR AX,AX
  PUSH AX
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o933
  MOV SP,BP
  CMP AX,word [p5cc6]
  JZ o31o3
  CALL o3167
  CALL o31c8
  CALL o33oo
  TEST AX,AX
  JZ o3135
  CALL o3229
  JMP o3147
o3135:
  CALL o3339
  TEST AX,AX
  JZ o3141
  CALL o3296
  JMP o3147
o3141:
  CALL o3229
  CALL o3296
o3147:
  MOV AX,word [p5cb4]
  MOV BX,word [p5cb6]
  MOV CX,word [p5cb8]
  MOV word [p5cbc],AX
  MOV word [p5cco],CX
  MOV word [p5cbe],BX
  JMP o31o3
o315f:
  MOV AX,word [p5ccc]
  ADD SP,2
  POP BP
  RET

o3167:
  PUSH BP
  MOV BP,SP
  CALL o3172
  CALL o319b
  POP BP
  RET

o3172:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o33fb
  PUSH word [p5cc2]
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o793
  MOV SP,BP
  MOV word [p5cb2],AX
  DEC AX
  MOV word [p5cb8],AX
  CALL o34o6
  ADD SP,6
  POP BP
  RET

o319b:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o33fb
  DEC word [p5cb2]
  PUSH word [p5cc2]
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o82b
  MOV SP,BP
  MOV word [p5cb2],AX
  INC AX
  MOV word [p5cb6],AX
  CALL o34o6
  ADD SP,6
  POP BP
  RET

o31c8:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CALL o3411
  MOV AX,word [p5cb6]
  INC word [p5cb4]
  CMP AX,word [p5cb8]
  MOV word [p5cb2],AX
  JNZ o31fa
  XOR AX,AX
  PUSH AX
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o933
  MOV SP,BP
  CMP AX,word [p5cc8]
  JNZ o31fa
  CALL o3372
o31fa:
  SUB word [p5cb4],2
  MOV AX,word [p5cb2]
  CMP AX,word [p5cb8]
  JNZ o3221
  XOR AX,AX
  PUSH AX
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o933
  MOV SP,BP
  CMP AX,word [p5cc8]
  JNZ o3221
  CALL o3372
o3221:
  CALL o3424
  ADD SP,2
  POP BP
  RET

o3229:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p5cb4]
  INC AX
  CMP AX,0x63
  JLE o324o
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o324o:
  CALL o3411
  MOV AX,word [p5cb6]
  INC word [p5cb4]
  MOV word [p5cb2],AX
o324d:
  MOV AX,word [p5cb2]
  CMP AX,word [p5cb8]
  JGE o328e
  PUSH word [p5cb8]
  PUSH word [p5cc4]
  PUSH word [p5cb4]
  PUSH AX
  CALL o71d
  MOV SP,BP
  CMP AX,word [p5cb8]
  MOV word [p5cb2],AX
  JG o328e
  CALL o3372
  PUSH word [p5cb8]
  PUSH word [p5cc4]
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o6a7
  MOV SP,BP
  MOV word [p5cb2],AX
  JMP o324d
o328e:
  CALL o3424
  ADD SP,2
  POP BP
  RET

o3296:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p5cb4]
  DEC AX
  JGE o32aa
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o32aa:
  CALL o3411
  MOV AX,word [p5cb6]
  DEC word [p5cb4]
  MOV word [p5cb2],AX
o32b7:
  MOV AX,word [p5cb2]
  CMP AX,word [p5cb8]
  JGE o32f8
  PUSH word [p5cb8]
  PUSH word [p5cc4]
  PUSH word [p5cb4]
  PUSH AX
  CALL o71d
  MOV SP,BP
  CMP AX,word [p5cb8]
  MOV word [p5cb2],AX
  JG o32f8
  CALL o3372
  PUSH word [p5cb8]
  PUSH word [p5cc4]
  PUSH word [p5cb4]
  PUSH word [p5cb2]
  CALL o6a7
  MOV SP,BP
  MOV word [p5cb2],AX
  JMP o32b7
o32f8:
  CALL o3424
  ADD SP,2
  POP BP
  RET

o33oo:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p5cbc]
  INC AX
  MOV BX,word [p5cb4]
  CMP BX,AX
  JNZ o3332
  MOV AX,word [p5cbe]
  DEC AX
  MOV BX,word [p5cb6]
  CMP BX,AX
  JLE o3332
  MOV AX,word [p5cco]
  INC AX
  MOV BX,word [p5cb8]
  CMP BX,AX
  JGE o3332
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o3332:
  XOR AX,AX
  ADD SP,2
  POP BP
  RET

o3339:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p5cbc]
  DEC AX
  MOV BX,word [p5cb4]
  CMP BX,AX
  JNZ o336b
  MOV AX,word [p5cbe]
  DEC AX
  MOV BX,word [p5cb6]
  CMP BX,AX
  JLE o336b
  MOV AX,word [p5cco]
  INC AX
  MOV BX,word [p5cb8]
  CMP BX,AX
  JGE o336b
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o336b:
  XOR AX,AX
  ADD SP,2
  POP BP
  RET

o3372:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p5cd4]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [p5cb2]
  MOV word [SI+p5cd8],BX
  MOV AX,word [p5cb4]
  MOV word [SI+p64a8],AX
  MOV AX,word [p5cd4]
  INC AX
  CMP AX,word [p5cd6]
  MOV word [p5cd4],AX
  JLE o339e
  MOV word [p5cd6],AX
o339e:
  MOV AX,word [p5cd4]
  CMP AX,0x3e8
  JL o33aa
  DEC word [p5cd4]
o33aa:
  ADD SP,4
  POP BP
  RET

o33af:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p5cd4]
  DEC AX
  MOV word [p5cd4],AX
  JGE o33c4
  MOV word [p5cd4],0
o33c4:
  MOV AX,word [p5cd4]
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p5cd8]
  MOV AX,word [SI+p64a8]
  MOV word [p5cb4],AX
  MOV word [p5cb2],BX
  ADD SP,4
  POP BP
  RET

o33df:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p5cd4],0
  JLE o33f4
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o33f4:
  XOR AX,AX
  ADD SP,2
  POP BP
  RET

o33fb:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p5cb2]
  MOV word [p5cce],AX
  POP BP
  RET

o34o6:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p5cce]
  MOV word [p5cb2],AX
  POP BP
  RET

o3411:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p5cb2]
  MOV BX,word [p5cb4]
  MOV word [p5cdo],AX
  MOV word [p5cd2],BX
  POP BP
  RET

o3424:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p5cdo]
  MOV BX,word [p5cd2]
  MOV word [p5cb2],AX
  MOV word [p5cb4],BX
  POP BP
  RET

o3437:
  PUSH BP
  MOV BP,SP
  PUSH CX
  MOV CX,word [BP+4]
  MOV AX,CX
  CMP CX,0x10
  JNB o34c1
  MOV AX,1
  SHL AX,CL
o34c1:
  POP CX
  POP BP
  RET

o34c3:
  PUSH BP
  MOV BP,SP
  PUSH BX
  PUSH CX
  MOV AX,word [BP+4]
  MOV CX,1
  XOR BX,BX
l1:
  CMP AX,CX
  JZ l2
  SHL CX,1
  INC BX
  CMP BX,0x10
  JGE l3
  JMP l1
l2:
  MOV AX,BX
l3:
  POP CX
  POP BX
  POP BP
  RET

o3575:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AL,0x63
  XOR BX,BX
  MOV word [p6c82],1
  MOV byte [pd4],AL
  MOV byte [pd3],AL
  MOV word [BP+4],BX
  MOV word [p6c84],BX
o3592:
  CMP word [BP+4],0xa
  JGE o35e9
  MOV DX,0x201
  XOR AL,AL
  OUT DX,AL
  IN AL,DX
  AND AX,3
  JNZ o35b8
  MOV word [p6c82],0
o35b8:
  MOV word [BP+2],0
o35bd:
  IN AL,DX
  AND AX,3
  JZ o35d7
  CMP word [BP+2],0xff
  JGE o35d7
  INC word [BP+2]
  JMP o35bd
o35d7:
  CMP word [BP+2],0xfa
  JLE o35e4
  MOV word [p6c82],0
o35e4:
  INC word [BP+4]
  JMP o3592
o35e9:
  ADD SP,6
  POP BP
  RET

;----------------------------------------------------------------------------
; o35ee — Joystick and keyboard input polling
; Reads pd3 (keyboard direction) and pd4 (last direction), stores
; into p6c78. Also checks pba (keyboard action key) and p6c82
; (joystick enabled flag). If joystick is enabled, calls o4f2
; to read the joystick port (201h) and updates p6c84 (action flag).
;----------------------------------------------------------------------------
o35ee:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AL,byte [pd4]
  XOR AH,AH
  MOV BL,byte [pd3]
  XOR BH,BH
  CMP BX,0x63
  MOV word [p6c78],AX
  MOV word [BP],BX
  JGE o36oe
  MOV word [p6c78],BX
o36oe:
  MOV byte [pd4],0x63
  CMP byte [pba],0
  JZ o3622
  MOV word [p6c84],1
  JMP o3628
o3622:
  MOV word [p6c84],0
o3628:
  CMP word [p6c82],0
  JZ o3647
  CALL o4f2
  CMP word [pd9],0
  JZ o3641
  MOV word [p6c84],1
  JMP o3647
o3641:
  MOV word [p6c84],0
o3647:
  ADD SP,4
  POP BP
  RET

;----------------------------------------------------------------------------
; o364c — Wait for keypress or joystick button release
; WARNING: This is a BLOCKING wait loop. It polls pc3 (keyboard scancode)
; and the joystick port (201h) in a tight loop until a key-down event is
; detected, then waits for all inputs to be released before returning.
; If you jump to code that calls o364c after already consuming a keypress
; (e.g. from show_startup_screen), the user must press a key AGAIN.
; This is why o55do_go exists — it skips o3575/o364c.
;----------------------------------------------------------------------------
o364c:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV word [BP+4],1
o3657:
  CMP word [BP+4],0
  JZ o3693
  CMP word [p6c82],0
  JZ o3673
  CALL o4f2
  CMP word [pd9],0
  JZ o3673
  MOV word [BP+4],0
o3673:
  MOV AL,byte [pc3]
  XOR AH,AH
  TEST AX,AX
  MOV word [BP],AX
  JZ o3657
  AND AX,0x80
  JNZ o3657
  XOR AX,AX
  MOV byte [pc3],0
  MOV word [p6c82],AX
  MOV word [BP+4],AX
  JMP o3657
o3693:
  CMP word [p6c82],0
  JZ o36fb
  CALL o4f2
  MOV AX,word [pd5]
  SUB AX,0x1e
  MOV word [p6c7a],AX
  JGE o36ae
  MOV word [p6c7a],0
o36ae:
  ADD word [p6c7a],5
  MOV AX,word [pd7]
  SUB AX,0x1e
  MOV word [p6c7c],AX
  JGE o36c4
  MOV word [p6c7c],0
o36c4:
  ADD word [p6c7c],5
  MOV AX,word [pd5]
  ADD AX,0x1e
  CMP AX,0xff
  MOV word [p6c7e],AX
  JLE o36dd
  MOV word [p6c7e],0xff
o36dd:
  SUB word [p6c7e],5
  MOV AX,word [pd7]
  ADD AX,0x1e
  CMP AX,0xff
  MOV word [p6c8o],AX
  JLE o36f6
  MOV word [p6c8o],0xff
o36f6:
  SUB word [p6c8o],5
o36fb:
  ADD SP,6
  POP BP
  RET

;----------------------------------------------------------------------------
; o37oo — Direction state query
; Returns the current movement direction by combining keyboard (pd3)
; and joystick (pd5/pd7) inputs. For joystick mode (p6c82≠ 0),
; compares joystick axis values against calibrated center values
; (p6c7a/7c/7e/8o) to determine 8-way direction (0-7).
; Returns direction in p6c78.
;----------------------------------------------------------------------------
o37oo:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p6c78]
  MOV word [BP+2],AX
  CMP word [p6c82],0
  JNZ o3716
  JMP o379a
o3716:
  MOV word [BP+2],0x63
  MOV AX,word [pd5]
  CMP AX,word [p6c7a]
  JGE o3745
  MOV word [BP+2],4
  MOV AX,word [pd7]
  CMP AX,word [p6c7c]
  JGE o3737
  MOV word [BP+2],3
o3737:
  MOV AX,word [pd7]
  CMP AX,word [p6c8o]
  JLE o3745
  MOV word [BP+2],5
o3745:
  MOV AX,word [pd5]
  CMP AX,word [p6c7e]
  JLE o376f
  MOV word [BP+2],0
  MOV AX,word [pd7]
  CMP AX,word [p6c7c]
  JGE o3761
  MOV word [BP+2],1
o3761:
  MOV AX,word [pd7]
  CMP AX,word [p6c8o]
  JLE o376f
  MOV word [BP+2],7
o376f:
  MOV AX,word [pd5]
  CMP AX,word [p6c7a]
  JL o379a
  CMP AX,word [p6c7e]
  JG o379a
  MOV AX,word [pd7]
  CMP AX,word [p6c7c]
  JGE o378c
  MOV word [BP+2],2
o378c:
  MOV AX,word [pd7]
  CMP AX,word [p6c8o]
  JLE o379a
  MOV word [BP+2],6
o379a:
  MOV AX,word [BP+2]
  ADD SP,4
  POP BP
  RET

;----------------------------------------------------------------------------
; o37a2 — Movement enabled query
; Returns p6c84 in AX: 1 = player is actively moving, 0 = idle.
;----------------------------------------------------------------------------
o37a2:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p6c84]
  POP BP
  RET

;----------------------------------------------------------------------------
; o37aa — Game state initialization
; Resets score tracking variables (p6c92-p6c98), calls o2ff4 to prepare
; the playing field, and updates the score display via o3cc3.
;----------------------------------------------------------------------------
o37aa:
  PUSH BP
  MOV BP,SP
  XOR AX,AX
  MOV word [p6c96],2
  MOV word [p6c98],0xf
  MOV BX,1
  PUSH BX
  MOV word [p6c92],AX
  MOV word [p6c94],AX
  CALL o2ff4
  MOV SP,BP
  CALL o3cc3
  POP BP
  RET

;----------------------------------------------------------------------------
; o37cf — High score file I/O
; Reads STYX.SCO via o1o9a (512 bytes). Parses 10 high score entries,
; each containing 3-char initials and 6-char score string. Stores
; initials in p6cfa table and scores in p6cce via o42d1 (atoi).
; If file doesn't exist or is invalid ('s' signature check at p215o),
; initializes all entries to zero.
;----------------------------------------------------------------------------
o37cf:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  MOV word [p6c9o],0
  MOV word [p6c8e],0
  CALL o1o9a
  MOV AX,1
  MOV word [BP+8],AX
  MOV word [BP+6],AX
o37fo:
  CMP word [BP+8],0xb
  JGE o385f
  MOV word [BP+0xa],0
o37fb:
  MOV AX,word [BP+0xa]
  CMP AX,3
  JGE o381f
  MOV BX,word [BP+8]
  SHL BX,1
  SHL BX,1
  ADD BX,AX
  MOV SI,word [BP+6]
  MOV AL,byte [SI+p215o]
  MOV byte [BX+p6cfa],AL
  INC word [BP+6]
  INC word [BP+0xa]
  JMP o37fb
o381f:
  ADD word [BP+6],2
  MOV word [BP+0xa],0
o3828:
  MOV AX,word [BP+0xa]
  CMP AX,6
  JGE o3846
  MOV SI,word [BP+6]
  MOV AL,byte [SI+p215o]
  MOV DI,word [BP+0xa]
  MOV byte [DI+p6c9c],AL
  INC word [BP+6]
  INC word [BP+0xa]
  JMP o3828
o3846:
  MOV AX,word [BP+8]
  SHL AX,1
  SHL AX,1
  ADD AX,p6cce
  PUSH AX
  MOV AX,p6c9c
  PUSH AX
  CALL o42d1
  MOV SP,BP
  INC word [BP+8]
  JMP o37fo
o385f:
  MOV AL,byte [p215o]
  XOR AH,AH
  CMP AX,0x73
  JZ o389a
  MOV word [BP+4],0
o386e:
  MOV AX,word [BP+4]
  CMP AX,0xb
  JGE o389a
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV word [SI+p6cdo],0
  MOV word [SI+p6cce],0
  ADD AX,p6cfa
  MOV BX,p6dfa
  PUSH BX
  PUSH AX
  CALL o5bab
  MOV SP,BP
  INC word [BP+4]
  JMP o386e
o389a:
  ADD SP,0xc
  POP BP
  RET

o38d8:
  PUSH BP
  MOV BP,SP
  XOR AX,AX
  XOR BX,BX
  MOV word [p6c8c],AX
  MOV word [p6c88],AX
  MOV word [p6c8a],BX
  MOV word [p6c86],BX
  POP BP
  RET

;----------------------------------------------------------------------------
; o38ef — Difficulty progression
; Decrements p6c98 (level countdown timer). When it reaches zero,
; advances to the next difficulty tier based on p6c96:
;   tier 2 → 3: slower enemies, 4 field sections
;   tier 3 → 5: medium enemies, 2 field sections  
;   tier 5 → 2: fastest enemies, 1 section
; Each tier sets a new countdown (p6c98) and calls o2ff4 to update
; the playing field, then o3aof to change the diamond indicator.
;----------------------------------------------------------------------------
o38ef:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [p6c98]
  DEC AX
  MOV word [p6c98],AX
  JNZ o395e
  MOV AX,word [p6c96]
  JMP o394a
o39o3:
  MOV word [p6c98],0xc
  MOV word [p6c96],3
  MOV AX,4
  PUSH AX
  CALL o2ff4
  MOV SP,BP
  JMP o395b
o391a:
  MOV word [p6c98],8
  MOV word [p6c96],5
  MOV AX,2
  PUSH AX
  CALL o2ff4
  MOV SP,BP
  JMP o395b
o3931:
  MOV word [p6c98],0x12
  MOV word [p6c96],2
  MOV AX,1
  PUSH AX
  CALL o2ff4
  MOV SP,BP
  JMP o395b
o394a:
  CMP AX,5
  JZ o3931
  CMP AX,3
  JZ o391a
  CMP AX,2
  JZ o39o3
  JMP o395b
o395b:
  CALL o3aof
o395e:
  ADD SP,2
  POP BP
  RET

o3963:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [BP+8]
  MOV word [p6c94],AX
  MOV AX,word [p6c96]
  JMP o39c6
o3974:
  MOV AX,word [p6c94]
  SUB AX,word [p6c92]
  XOR BX,BX
  TEST AX,AX
  JNS o3982
  DEC BX
o3982:
  ADD word [p6c86],AX
  ADC word [p6c88],BX
  JMP o39d5
o398c:
  MOV AX,word [p6c94]
  SUB AX,word [p6c92]
  MOV BX,5
  IMUL BX
  XOR BX,BX
  TEST AX,AX
  JNS o399f
  DEC BX
o399f:
  ADD word [p6c86],AX
  ADC word [p6c88],BX
  JMP o39d5
o39a9:
  MOV AX,word [p6c94]
  SUB AX,word [p6c92]
  MOV BX,0xa
  IMUL BX
  XOR BX,BX
  TEST AX,AX
  JNS o39bc
  DEC BX
o39bc:
  ADD word [p6c86],AX
  ADC word [p6c88],BX
  JMP o39d5
o39c6:
  CMP AX,5
  JZ o39a9
  CMP AX,3
  JZ o398c
  CMP AX,2
  JZ o3974
o39d5:
  MOV AX,word [p6c88]
  MOV BX,word [p6c86]
  MOV CX,0xf
  MOV DX,0x423f
  CALL o6of2
  JLE o39f3
  MOV word [p6c88],0
  MOV word [p6c86],0
o39f3:
  MOV AX,word [p6c94]
  CMP AX,0x320
  MOV word [p6c92],AX
  JL o3ao7
  MOV AX,1
  PUSH AX
  CALL o5863
  MOV SP,BP
o3ao7:
  CALL o3cc3
  ADD SP,4
  POP BP
  RET

;----------------------------------------------------------------------------
; o3aof — Diamond/difficulty indicator display
; Draws the correct diamond sprite variant based on current difficulty
; tier (p6c96). Tier 2 = p6d26 sprite, Tier 3 = p6d67, Tier 5 = p6da8.
; Diamond drawn at fixed position (x=0x8a, y=1) via oc83 (sprite draw).
;----------------------------------------------------------------------------
o3aof:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p6c96]
  JMP o3a52
o3a17:
  MOV AX,p6d26
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,0x8a
  PUSH AX
  CALL oc83
  MOV SP,BP
  JMP o3a63
o3a2a:
  MOV AX,p6d67
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,0x8a
  PUSH AX
  CALL oc83
  MOV SP,BP
  JMP o3a63
o3a3d:
  MOV AX,p6da8
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,0x8a
  PUSH AX
  CALL oc83
  MOV SP,BP
  JMP o3a63
o3a52:
  CMP AX,5
  JZ o3a3d
  CMP AX,3
  JZ o3a2a
  CMP AX,2
  JZ o3a17
  JMP o3a63
o3a63:
  POP BP
  RET

;----------------------------------------------------------------------------
; o3a65 — New high score check and entry
; Compares current score (p6c86/88) against existing high scores
; (p6cf6/f8). If score qualifies, flashes "NEW HIGH SCORE" text
; (p6dfe) with color cycling, prompts for initials via o57d5,
; then resets palette and calls o3fb8 (initial entry screen) and
; o415b (insert score into table).
;----------------------------------------------------------------------------
o3a65:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  CALL o3cc3
  MOV AX,word [p6c88]
  MOV BX,word [p6c86]
  MOV CX,word [p6cf8]
  MOV DX,word [p6cf6]
  CALL o6of2
  JLE o3aef
  MOV AX,0xb
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,0x14
  PUSH AX
  MOV AX,0xa
  PUSH AX
  MOV AX,p6dfe
  PUSH AX
  CALL o4feb
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  MOV AX,0x13
  PUSH AX
  MOV AX,0x95
  PUSH AX
  MOV AX,0x13
  PUSH AX
  MOV AX,0xa
  PUSH AX
  CALL oab6
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  MOV AX,0x1b
  PUSH AX
  MOV AX,0x95
  PUSH AX
  MOV AX,0x1b
  PUSH AX
  MOV AX,0xa
  PUSH AX
  CALL oab6
  MOV SP,BP
  CALL o57d5
  MOV AX,0x14
  PUSH AX
  MOV AX,0xa
  PUSH AX
  MOV AX,p6dfe
  PUSH AX
  CALL o4feb
  MOV SP,BP
  CALL pc1_set_cga_palette  ;Reset to CGA palette for score screen
  CALL o5c3
  CALL o3fb8
  CALL o415b
  CALL o3f24
  JMP o3bce
o3aef:
  MOV word [BP+2],0x2b
o3af4:
  CMP word [BP+2],0x36
  JGE o3b15
  XOR AX,AX
  PUSH AX
  PUSH word [BP+2]
  MOV AX,0x7f
  PUSH AX
  PUSH word [BP+2]
  MOV AX,0x1e
  PUSH AX
  CALL oab6
  MOV SP,BP
  INC word [BP+2]
  JMP o3af4
o3b15:
  MOV AX,7
  PUSH AX
  MOV AX,0x2a
  PUSH AX
  MOV AX,0x7f
  PUSH AX
  MOV AX,0x2a
  PUSH AX
  MOV AX,0x1e
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x36
  PUSH AX
  MOV AX,0x7f
  PUSH AX
  MOV AX,0x2a
  PUSH AX
  MOV AX,0x7f
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x36
  PUSH AX
  MOV AX,0x1e
  PUSH AX
  MOV AX,0x36
  PUSH AX
  MOV AX,0x7f
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x2a
  PUSH AX
  MOV AX,0x1e
  PUSH AX
  MOV AX,0x36
  PUSH AX
  MOV AX,0x1e
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV word [BP+2],1
o3b87:
  CMP word [BP+2],0x1e
  JGE o3bab
  PUSH word [BP+2]
  CALL o5o29
  MOV SP,BP
  MOV AX,0x2d
  PUSH AX
  MOV AX,0x22
  PUSH AX
  MOV AX,p6eod
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,8
  PUSH AX
  CALL o41c    ;Delay don't know
  POP AX
  INC word [BP+2]
  JMP o3b87
o3bab:
  MOV AX,0xb
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,0x2d
  PUSH AX
  MOV AX,0x22
  PUSH AX
  MOV AX,p6eod
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,200
  PUSH AX
  CALL o41c    ;Delay don't know
  MOV SP,BP
o3bce:
  ADD SP,8
  POP BP
  RET

;----------------------------------------------------------------------------
; o3bd3 — Bonus score calculation
; Awards bonus points for territory claims based on percentage.
; Formula: bonus = (score/10 - 80) × 1000, minimum 0.
; Adds bonus to total score (p6c86/88). If player initialled,
; shows bonus breakdown text with multiple formatted strings.
;----------------------------------------------------------------------------
o3bd3:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  MOV AX,word [p6c94]
  MOV BX,0xa
  CWD
  IDIV BX
  SUB AX,0x50
  CMP AX,1
  MOV word [BP+8],AX
  JGE o3bf2
  MOV word [BP+8],0
o3bf2:
  MOV AX,1000
  IMUL word [BP+8]
  XOR BX,BX
  TEST AX,AX
  JNS o3bff
  DEC BX
o3bff:
  ADD word [p6c86],AX
  ADC word [p6c88],BX
  MOV word [BP],AX
  MOV word [BP+8],AX
  MOV word [BP+2],BX
  TEST AX,AX
  JNZ o3c17
  JMP o3cbe
o3c17:
  MOV CX,p6e17
  PUSH CX
  MOV CX,p6c9c
  PUSH CX
  MOV word [BP+4],AX
  MOV word [BP+6],BX
  CALL o5bab
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH word [BP+6]
  PUSH word [BP+4]
  MOV AX,p6c9c
  PUSH AX
  CALL o41f3
  MOV SP,BP
  MOV AX,p6c9c
  PUSH AX
  CALL o5ad5
  MOV SP,BP
  MOV BX,0xb
  PUSH BX
  MOV word [BP+8],AX
  CALL o5odd
  MOV SP,BP
  MOV AX,0x26
  PUSH AX
  MOV AX,0x2d
  PUSH AX
  MOV AX,p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0x2d
  PUSH AX
  PUSH AX
  MOV AX,p6e2o
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0x34
  PUSH AX
  MOV AX,0x2d
  PUSH AX
  MOV AX,p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0x3b
  PUSH AX
  MOV AX,0x2d
  PUSH AX
  MOV AX,p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,word [BP+8]
  MOV BX,5
  IMUL BX
  MOV BX,0x50
  SUB BX,AX
  MOV AX,0x3b
  PUSH AX
  PUSH BX
  MOV AX,p6c9c
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0x42
  PUSH AX
  MOV AX,0x2d
  PUSH AX
  MOV AX,p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
o3cbe:
  ADD SP,0xc
  POP BP
  RET

;----------------------------------------------------------------------------
; o3cc3 — Score display
; Renders the current score on screen using o4b72 (digit rendering).
; Breaks the score value into individual digits and draws each one
; at the appropriate position in the score area (top of screen).
;----------------------------------------------------------------------------
o3cc3:
  PUSH BP
  MOV BP,SP
  MOV AX,2
  PUSH AX
  MOV AX,1
  PUSH AX
  PUSH word [p6c88]
  PUSH word [p6c86]
  CALL o3ce6
  MOV SP,BP
  CALL o3d8b
  CALL o3aof
  CALL o3dc8
  POP BP
  RET

o3ce6:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  MOV word [BP+6],0
  MOV word [BP+0xa],1
  MOV word [BP+8],0x86a0
o3cfb:
  MOV AX,word [BP+0xa]
  MOV BX,word [BP+8]
  XOR CX,CX
  MOV DX,1
  CALL o6of2
  JLE o3d7o
  MOV AX,word [BP+0x12]
  MOV BX,word [BP+0x10]
  MOV CX,word [BP+0xa]
  MOV DX,word [BP+8]
  CALL o5afb
  MOV AX,word [BP+0x12]
  MOV word [BP+4],BX
  MOV BX,word [BP+0x10]
  MOV CX,word [BP+0xa]
  MOV DX,word [BP+8]
  CALL o5afb
  MOV word [BP+0x12],CX
  MOV word [BP+0x10],DX
  CMP word [BP+4],0
  JNZ o3d45
  CMP word [BP+8],0x86a0
  JNZ o3d43
  CMP word [BP+0xa],1
o3d43:
  JZ o3d57
o3d45:
  MOV AX,word [BP+0x14]
  ADD AX,word [BP+6]
  PUSH word [BP+0x16]
  PUSH AX
  PUSH word [BP+4]
  CALL o4b72
  MOV SP,BP
o3d57:
  MOV AX,word [BP+0xa]
  MOV BX,word [BP+8]
  XOR CX,CX
  MOV DX,0xa
  CALL o5afb
  INC word [BP+6]
  MOV word [BP+0xa],AX
  MOV word [BP+8],BX
  JMP o3cfb
o3d7o:
  MOV AX,word [BP+0x10]
  MOV BX,word [BP+0x14]
  ADD BX,5
  PUSH word [BP+0x16]
  PUSH BX
  PUSH AX
  MOV word [BP+4],AX
  CALL o4b72
  MOV SP,BP
  ADD SP,0xc
  POP BP
  RET

;----------------------------------------------------------------------------
; o3d8b — Lives display
; Draws remaining player lives as small icons. Calls o58a4 to get
; lives count, then iterates 1-4 drawing filled (o3o23) or empty
; (o2fff) life indicators based on remaining count.
;----------------------------------------------------------------------------
o3d8b:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o58a4
  DEC AX
  MOV word [BP+2],1
  MOV word [BP+4],AX
o3d9d:
  CMP word [BP+2],5
  JGE o3dc3
  CMP word [BP+4],0
  JLE o3db3
  PUSH word [BP+2]
  CALL o3o23
  MOV SP,BP
  JMP o3dbb
o3db3:
  PUSH word [BP+2]
  CALL o2fff
  MOV SP,BP
o3dbb:
  DEC word [BP+4]
  INC word [BP+2]
  JMP o3d9d
o3dc3:
  ADD SP,6
  POP BP
  RET

;----------------------------------------------------------------------------
; o3dc8 — Level counter display
; Renders the current level number on screen. Decomposes the level
; value into hundreds/tens/ones digits, draws each via o4b72.
; Also draws the diamond sprite (p6de9) at x=0x7b as a separator.
;----------------------------------------------------------------------------
o3dc8:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  MOV word [BP+2],0x1a
  MOV AX,word [p6c94]
  MOV word [BP+6],0
  MOV word [BP+8],0x64
  MOV word [BP+0xa],AX
o3de3:
  MOV AX,word [BP+8]
  CMP AX,1
  JLE o3e2f
  MOV AX,word [BP+0xa]
  CWD
  IDIV word [BP+8]
  MOV word [BP+4],AX
  MOV AX,word [BP+0xa]
  CWD
  IDIV word [BP+8]
  MOV word [BP+0xa],DX
  CMP word [BP+4],0
  JNZ o3eob
  CMP word [BP+8],0xa
  JNZ o3e1e
o3eob:
  MOV AX,word [BP+2]
  ADD AX,word [BP+6]
  MOV BX,2
  PUSH BX
  PUSH AX
  PUSH word [BP+4]
  CALL o4b72
  MOV SP,BP
o3e1e:
  MOV AX,word [BP+8]
  MOV BX,0xa
  CWD
  IDIV BX
  INC word [BP+6]
  MOV word [BP+8],AX
  JMP o3de3
o3e2f:
  MOV AX,word [BP+0xa]
  MOV BX,word [BP+2]
  ADD BX,3
  MOV CX,2
  PUSH CX
  PUSH BX
  PUSH AX
  MOV word [BP+4],AX
  CALL o4b72
  MOV SP,BP
  MOV AX,0xf
  PUSH AX
  MOV AX,6
  PUSH AX
  MOV AX,0x72
  PUSH AX
  CALL o9ob
  MOV SP,BP
  MOV AX,p6de9
  PUSH AX
  MOV AX,2
  PUSH AX
  MOV AX,0x7b
  PUSH AX
  CALL oc83
  MOV SP,BP
  ADD SP,0xc
  POP BP
  RET

;----------------------------------------------------------------------------
; o3e6d — High score screen display
; Shows the "HIGH SCORES" table. Draws a decorative border, displays
; the heading (p6e28), then iterates through all 10 entries (1-10),
; formatting each with rank, initials (from p6cfa), and score.
; Used both during attract mode and after game over.
;----------------------------------------------------------------------------
o3e6d:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,0x1a
  PUSH AX
  MOV AX,1
  PUSH AX
  CALL o1o61
  MOV SP,BP
  MOV AX,3                      ;Heading color: 3 (CGA brown/yellow)
  PUSH AX
  MOV AX,p6e28                  ;"HIGH SCORES" string
  PUSH AX
  CALL o5535                    ;Print heading
  MOV SP,BP
  MOV word [BP+4],1             ;First entry color: 1 (CGA green)
  MOV word [BP+2],1             ;Entry counter (1-10)
o3e97:
  CMP word [BP+2],0xb
  JL o3eao
  JMP o3f1f
o3eao:
  MOV AX,p6e17
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5bab
  MOV SP,BP
  MOV AX,word [BP+2]
  SHL AX,1
  SHL AX,1
  ADD AX,p6cfa
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,p6e34
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,word [BP+2]
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV AX,1
  PUSH AX
  PUSH word [SI+p6cdo]
  PUSH word [SI+p6cce]
  MOV AX,p6c9c
  PUSH AX
  CALL o41f3
  MOV SP,BP
  MOV AX,p6c9c
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,word [BP+2]
  INC AX
  INC AX
  MOV BX,0x1a
  PUSH BX
  PUSH AX
  CALL o1o61
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p6ca6
  PUSH AX
  CALL o5535
  MOV SP,BP
  MOV word [BP+4],1             ;Entries 2-10 color: 1 (CGA green)
  INC word [BP+2]
  JMP o3e97
o3f1f:
  ADD SP,6
  POP BP
  RET

o3f24:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,p6e37
  PUSH AX
  MOV AX,p215o
  PUSH AX
  CALL o5bab
  MOV SP,BP
  MOV word [BP+2],1
o3f3c:
  CMP word [BP+2],0xb
  JGE o3fad
  MOV AX,p6e17
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5bab
  MOV SP,BP
  MOV AX,word [BP+2]
  SHL AX,1
  SHL AX,1
  ADD AX,p6cfa
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,p6e34
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,word [BP+2]
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV AX,1
  PUSH AX
  PUSH word [SI+p6cdo]
  PUSH word [SI+p6cce]
  MOV AX,p6c9c
  PUSH AX
  CALL o41f3
  MOV SP,BP
  MOV AX,p6c9c
  PUSH AX
  MOV AX,p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,p6ca6
  PUSH AX
  MOV AX,p215o
  PUSH AX
  CALL o5ede
  MOV SP,BP
  INC word [BP+2]
  JMP o3f3c
o3fad:
  CALL o1oc3
  ADD SP,6
  POP BP
  RET

;----------------------------------------------------------------------------
; o3fb8 — High score name entry screen
; Displays the "ENTER YOUR INITIALS" prompt with "PRESS RETURN"
; instruction. Draws at y=0x1e..0x50 area. Shows cursor-blinking
; character input fields. Calls into text rendering (o4feb) and
; color setting (o5odd) for visual feedback.
;----------------------------------------------------------------------------
o3fb8:
  PUSH BP
  SUB SP,0xa
  MOV BP,SP
  MOV AX,7
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,0x32
  PUSH AX
  MOV AX,0x1e
  PUSH AX
  MOV AX,p6e39
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0x3c
  PUSH AX
  MOV AX,0x28
  PUSH AX
  MOV AX,p6e44
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0xf
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,0x50
  PUSH AX
  MOV AX,0x37
  PUSH AX
  MOV AX,p6e4d
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,p6dfa
  PUSH AX
  MOV AX,p6cfa
  PUSH AX
  CALL o5bab
  MOV SP,BP
  XOR AX,AX
  MOV word [BP+8],AX
  MOV word [p6c9a],AX
o4o18:
  CMP word [BP+8],3
  JGE o4o9o
  MOV word [BP+6],0
o4o23:
  CMP word [BP+6],0
  JNZ o4o63
  CMP word [p6c9a],0
  JNZ o4o63
  MOV AX,word [BP+8]
  MOV BX,0x14
  IMUL BX
  ADD AX,0x37
  MOV BX,0x50
  PUSH BX
  PUSH AX
  CALL o4o9a
  MOV SP,BP
  MOV word [BP+6],AX
  CMP word [BP+8],0
  JZ o4o56
  CMP AX,0xe
  JNZ o4o56
  DEC word [BP+8]
o4o56:
  PUSH word [BP+6]
  CALL o53cd
  MOV SP,BP
  MOV word [BP+6],AX
  JMP o4o23
o4o63:
  CMP word [BP+6],0
  JZ o4o8b
  MOV AX,word [BP+8]
  MOV BX,0x14
  IMUL BX
  ADD AX,0x37
  MOV BX,0x50
  PUSH BX
  PUSH AX
  PUSH word [BP+6]
  CALL o4c8a
  MOV SP,BP
  MOV AX,word [BP+6]
  MOV SI,word [BP+8]
  MOV byte [SI+p6cfa],AL
o4o8b:
  INC word [BP+8]
  JMP o4o18
o4o9o:
  MOV byte [pc3],0
  ADD SP,0xa
  POP BP
  RET

o4o9a:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV byte [pc3],0
  MOV word [BP+4],0
o4oaa:
  CMP word [BP+4],0x32
  JL o4ob3
  JMP o414e
o4ob3:
  PUSH word [BP+0xc]
  PUSH word [BP+0xa]
  MOV AX,0x5f
  PUSH AX
  CALL o4c8a
  MOV SP,BP
  MOV word [BP+2],0
o4oc7:
  CMP word [BP+2],0x1e
  JGE o4of6
  MOV AL,byte [pc3]
  XOR AH,AH
  AND AX,0x80
  JNZ o4oe8
  CMP byte [pc3],0
  JZ o4oe8
  MOV AL,byte [pc3]
  XOR AH,AH
  ADD SP,6
  POP BP
  RET
o4oe8:
  MOV AX,5
  PUSH AX
  CALL o41c       ;Delay don't know
  MOV SP,BP
  INC word [BP+2]
  JMP o4oc7
o4of6:
  PUSH word [BP+0xc]
  PUSH word [BP+0xa]
  MOV AX,0x20
  PUSH AX
  CALL o4c8a
  MOV SP,BP
  MOV word [BP+2],0
o41oa:
  CMP word [BP+2],0x32
  JGE o4148
  MOV AL,byte [pc3]
  XOR AH,AH
  AND AX,0x80
  JNZ o413a
  CMP byte [pc3],0
  JZ o413a
  PUSH word [BP+0xc]
  PUSH word [BP+0xa]
  MOV AX,0x5f
  PUSH AX
  CALL o4c8a
  MOV SP,BP
  MOV AL,byte [pc3]
  XOR AH,AH
  ADD SP,6
  POP BP
  RET
o413a:
  MOV AX,5
  PUSH AX
  CALL o41c
  MOV SP,BP     ;Delay don't know
  INC word [BP+2]
  JMP o41oa
o4148:
  INC word [BP+4]
  JMP o4oaa
o414e:
  MOV word [p6c9a],1
  XOR AX,AX
  ADD SP,6
  POP BP
  RET

;----------------------------------------------------------------------------
; o415b — Insert score into high score table
; Compares current score against all 10 table entries (p6cca/ccc),
; shifts lower entries down, inserts new score and initials at
; the correct rank position. Writes updated table via o1oc3.
;----------------------------------------------------------------------------
o415b:
  PUSH BP
  SUB SP,0xa
  MOV BP,SP
  MOV word [BP+8],0xa
o4166:
  MOV AX,word [BP+8]
  CMP AX,1
  JLE o418d
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV AX,word [p6c88]
  MOV BX,word [p6c86]
  MOV CX,word [SI+p6ccc]
  MOV DX,word [SI+p6cca]
  CALL o6of2
  JL o418d
  DEC word [BP+8]
  JMP o4166
o418d:
  MOV word [BP+6],0xa
o4192:
  MOV AX,word [BP+6]
  CMP AX,word [BP+8]
  JLE o41c8
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV BX,word [SI+p6ccc]
  MOV CX,word [SI+p6cca]
  MOV word [SI+p6cdo],BX
  MOV word [SI+p6cce],CX
  MOV word [BP],AX
  ADD AX,p6cfa
  MOV BX,SI
  ADD BX,p6cf6
  PUSH BX
  PUSH AX
  CALL o5bab
  MOV SP,BP
  DEC word [BP+6]
  JMP o4192
o41c8:
  MOV AX,word [BP+8]
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV BX,word [p6c88]
  MOV CX,word [p6c86]
  MOV word [SI+p6cdo],BX
  MOV word [SI+p6cce],CX
  ADD AX,p6cfa
  MOV BX,p6cfa
  PUSH BX
  PUSH AX
  CALL o5bab
  MOV SP,BP
  ADD SP,0xa
  POP BP
  RET

o41f3:
  PUSH BP
  SUB SP,0x1c
  MOV BP,SP
  XOR AX,AX
  MOV word [BP+0xc],1
  MOV word [BP+0xa],0x86a0
  MOV BX,p6e17
  PUSH BX
  PUSH word [BP+0x20]
  MOV word [BP+8],AX
  MOV word [BP+6],AX
  CALL o5bab
  MOV SP,BP
o4217:
  MOV AX,word [BP+0xc]
  MOV BX,word [BP+0xa]
  XOR CX,CX
  MOV DX,1
  CALL o6of2
  JG o422a
  JMP o42ac
o422a:
  MOV AX,word [BP+0x24]
  MOV BX,word [BP+0x22]
  MOV CX,word [BP+0xc]
  MOV DX,word [BP+0xa]
  CALL o5afb
  MOV AX,word [BP+0x24]
  MOV word [BP+4],BX
  MOV BX,word [BP+0x22]
  MOV CX,word [BP+0xc]
  MOV DX,word [BP+0xa]
  CALL o5afb
  MOV AX,0xa
  PUSH AX
  PUSH word [BP+4]
  LEA AX,word [BP+0x12]
  PUSH AX
  MOV word [BP+0x24],CX
  MOV word [BP+0x22],DX
  CALL o5bca
  MOV SP,BP
  CMP word [BP+4],0
  JNZ o426d
  CMP word [BP+8],0
  JZ o428o
o426d:
  LEA AX,word [BP+0x12]
  PUSH AX
  PUSH word [BP+0x20]
  CALL o5ede
  MOV SP,BP
  MOV word [BP+8],1
  JMP o4292
o428o:
  CMP word [BP+0x26],0
  JZ o4292
  MOV AX,p6e53
  PUSH AX
  PUSH word [BP+0x20]
  CALL o5ede
  MOV SP,BP
o4292:
  MOV AX,word [BP+0xc]
  MOV BX,word [BP+0xa]
  XOR CX,CX
  MOV DX,0xa
  CALL o5afb
  INC word [BP+6]
  MOV word [BP+0xc],AX
  MOV word [BP+0xa],BX
  JMP o4217
o42ac:
  MOV AX,word [BP+0x22]
  MOV BX,0xa
  PUSH BX
  PUSH AX
  LEA BX,word [BP+0x12]
  PUSH BX
  MOV word [BP+4],AX
  CALL o5bca
  MOV SP,BP
  LEA AX,word [BP+0x12]
  PUSH AX
  PUSH word [BP+0x20]
  CALL o5ede
  MOV SP,BP
  ADD SP,0x1c
  POP BP
  RET

o42d1:
  PUSH BP
  SUB SP,0xe
  MOV BP,SP
  MOV word [BP+6],0
  MOV word [BP+0xc],1
  MOV word [BP+0xa],0x86a0
  MOV SI,word [BP+0x14]
  MOV word [SI+2],0
  MOV word [SI],0
o42f2:
  MOV AX,word [BP+0xc]
  MOV BX,word [BP+0xa]
  XOR CX,CX
  XOR DX,DX
  CALL o6of2
  JLE o4351
  MOV BX,word [BP+0x12]
  ADD BX,word [BP+6]
  MOV AL,byte [BX]
  XOR AH,AH
  PUSH AX
  CALL o536d
  MOV SP,BP
  XOR BX,BX
  TEST AX,AX
  JNS o4318
  DEC BX
o4318:
  MOV word [BP],AX
  MOV word [BP+4],AX
  MOV AX,word [BP+0xc]
  MOV word [BP+2],BX
  MOV BX,word [BP+0xa]
  MOV CX,word [BP+2]
  MOV DX,word [BP]
  CALL o5a54
  MOV SI,word [BP+0x14]
  ADD word [SI],BX
  ADC word [SI+2],AX
  MOV AX,word [BP+0xc]
  MOV BX,word [BP+0xa]
  XOR CX,CX
  MOV DX,0xa
  CALL o5afb
  INC word [BP+6]
  MOV word [BP+0xc],AX
  MOV word [BP+0xa],BX
  JMP o42f2
o4351:
  ADD SP,0xe
  POP BP
  RET

o4356:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p6c96]
  POP BP
  RET

;----------------------------------------------------------------------------
; o435e — Sound event dispatcher
; Called each frame from the main level loop. Manages sound enable/
; disable state (pco flag → p6e5a). When sound mode changes (p38c2
; vs p6e56), calls o44f4 (configure PIT), o45e2 (set waveform),
; and o4964 (play current sound). Silences speaker via o4b46/o49f7
; when sound is disabled.
;----------------------------------------------------------------------------
o435e:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP byte [pco],0
  JZ o4378
  CMP word [p6e5a],0
  JNZ o4378
  MOV word [p6e5a],1
o4378:
  CMP byte [pco],0
  JNZ o4398
  CMP word [p6e5a],0
  JZ o4398
  MOV word [p6e5a],0
  MOV AX,0x28
  PUSH AX
  CALL o4b46
  MOV SP,BP
  CALL o49f7
o4398:
  MOV AL,byte [p38c2]
  XOR AH,AH
  CMP AX,word [p6e56]
  JZ o43c2
  CMP word [p6e5a],0
  JZ o43c2
  CALL o586e
  TEST AX,AX
  JNZ o43c2
  MOV AL,byte [p38c2]
  XOR AH,AH
  MOV word [p6e56],AX
  CALL o44f4
  CALL o45e2
  CALL o4964
o43c2:
  ADD SP,2
  POP BP
  RET

; === STYX3.ASM ===

; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

; PUBLIC o43c7,o4427,o44ce,o44f4,o45b8,o45d7,o45e2,o462o
; PUBLIC o4631,o46ca,o47o7,o4744,o476o,o4892,o48bd,o48d7,o49oa,o492a,o4964,o49f7
; PUBLIC o4a3c,o4a8c,o4b13,o4b46,o4b72,o4c8a,o4feb,o5o29,o5odd,o521a,o536d,o53cd
; PUBLIC o551e,o5535,o556a,o57d5,o5858,o5863,o586e,o5891,o58a4,o58ac,o5939,o5993
; PUBLIC o5a54,o5ac5,o5ad5,o5afb,o5bab,o5bca,o5ca2,o5d66,o5dce,o5ede
; PUBLIC o5f1b,o6o56,o6of2,o61of,o611o,o689c,o68ce,o6a3f,o6b15,o6b26,o6b5a,o6b7b
; PUBLIC o6b91,o6baf,o6bd3
; PUBLIC codeend


o43c7:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AL,byte [p38c2]
  XOR AH,AH
  MOV word [p6e56],AX
  CALL o44ce
  CALL o45d7
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o4427 — Sound system initialization
; Programs PIT Timer Channel 2: B6h→43h (square wave mode), frequency
; 0x0020→42h. Enables PC speaker gate: port 61h OR 3.
; Programs PIT Timer Channel 0: 36h→43h (rate generator), sets timer
; period to 0x8000 (half the normal 65536 rate = ~36.4 Hz).
; Initializes all sound state variables (p6e5a-p6e86, p38bc).
; Calls o49f7 (silence speaker), o43c7 (reset sequences), o4a8c.
;----------------------------------------------------------------------------
o4427:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AL,0xb6
  OUT 0x43,AL
  MOV AL,0x20
  OUT 0x42,AL
  XOR AL,AL
  OUT 0x42,AL
  IN AL,0x61
  MOV word [BP+2],AX
  AND AX,0xfc
  OR AL,3
  OUT 0x61,AL
  MOV word [BP+2],AX
  MOV AL,0x36
  OUT 0x43,AL
  XOR AL,AL
  OUT 0x40,AL
  MOV AL,0x80
  OUT 0x40,AL
  MOV word [cs:int8speed],0x8000
  MOV AX,1
  XOR BX,BX
  MOV word [p6e84],12000
  MOV word [p6e82],0x28
  MOV word [p6e5e],AX
  MOV word [p6e86],AX
  MOV word [p6e6o],AX
  MOV word [p6e5a],AX
  MOV word [p38bc],BX
  MOV word [p6e5c],BX
  CALL o49f7
  CALL o43c7
  CALL o4a8c
  ADD SP,4
  POP BP
  RET

;----------------------------------------------------------------------------
; o44ce — Sound parameter defaults
; Sets default envelope: p6e86=15 (volume), p6e66=1 (attack),
; p6e68=5 (decay), p6e6a=0 (sustain flag). Base frequency = 2000.
;----------------------------------------------------------------------------
o44ce:
  PUSH BP
  MOV BP,SP
  MOV AX,2000
  MOV word [p6e86],0xf
  MOV word [p6e66],1
  MOV word [p6e68],5
  MOV word [p6e6a],0
  MOV word [p6e62],AX
  MOV word [p6e64],AX
  POP BP
  RET

;----------------------------------------------------------------------------
; o44f4 — Sound frequency updater
; Adjusts current frequency (p6e62) toward target (p6e64) in steps
; of 5. When frequencies match, decrements envelope and eventually
; silences. Programs PIT Channel 2 with new frequency.
;----------------------------------------------------------------------------
o44f4:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  CMP word [p6e6a],0
  JNZ o45o4
  JMP o45b3
o45o4:
  MOV word [p6e6o],1
  MOV AX,word [p6e62]
  MOV BX,word [p6e64]
  CMP BX,AX
  JGE o451a
  SUB word [p6e62],5
o451a:
  MOV AX,word [p6e62]
  MOV BX,word [p6e64]
  CMP BX,AX
  JLE o452a
  ADD word [p6e62],5
o452a:
  MOV word [p6e82],0xa
  MOV AX,word [p6e62]
  SHL AX,1
  MOV BX,5
  PUSH BX
  MOV word [p6e84],AX
  CALL o227
  MOV SP,BP
  DEC AX
  JNZ o456o
  MOV AX,3
  PUSH AX
  CALL o227
  MOV SP,BP
  DEC AX
  MOV BX,0xe
  PUSH BX
  MOV word [p6e66],AX
  CALL o227
  MOV SP,BP
  SUB AX,5
  MOV word [p6e68],AX
o456o:
  MOV AX,word [p6e86]
  ADD AX,word [p6e66]
  CMP AX,0x14
  MOV word [p6e86],AX
  JG o4574
  CMP AX,0xa
  JGE o457b
o4574:
  MOV AX,word [p6e68]
  ADD word [p6e86],AX
o457b:
  CMP word [p6e86],0x32
  JLE o4592
  NEG word [p6e68]
  MOV word [p6e66],-1
  MOV word [p6e86],0x32
o4592:
  CMP word [p6e86],1
  JGE o45b3
  MOV AX,5
  PUSH AX
  CALL o227
  MOV SP,BP
  INC AX
  INC AX
  MOV word [p6e66],1
  MOV word [p6e86],0
  MOV word [p6e68],AX
o45b3:
  ADD SP,4
  POP BP
  RET

o45b8:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV word [p6e6a],1
  MOV AX,word [BP+6]
  MOV BX,5
  IMUL BX
  ADD AX,1500
  MOV word [p6e64],AX
  ADD SP,2
  POP BP
  RET

o45d7:
  PUSH BP
  MOV BP,SP
  MOV word [p6e6e],0
  POP BP
  RET

o45e2:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p6e6e],0
  JZ o461b
  MOV word [p6e6o],1
  MOV AX,5
  IMUL word [p6e6c]
  MOV BX,2000
  SUB BX,AX
  MOV AX,0x14
  IMUL word [p6e6c]
  MOV CX,30000
  SUB CX,AX
  MOV AX,word [p6e6c]
  MOV word [p6e86],AX
  MOV word [p6e82],CX
  MOV word [p6e84],BX
o461b:
  ADD SP,2
  POP BP
  RET

o462o:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [p6e6e],1
  MOV word [p6e6c],AX
  POP BP
  RET

o4631:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  MOV word [BP+8],4000
  MOV word [BP+0xa],0x7e4  ;???
  XOR AX,AX
  MOV word [p6e6o],2
  MOV word [p6e6e],AX
  MOV word [p6e6a],AX
  CALL o4356
  JMP o46b3
o4654:
  MOV AX,word [BP+8]
  MOV BX,word [BP+0xa]
  MOV word [p6e82],AX
  MOV word [p6e84],BX
  JMP o46c2
o4663:
  MOV AX,word [BP+8]
  CALL o5d66
  MOV SI,p6e88
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e82],AX
  MOV AX,word [BP+0xa]
  CALL o5d66
  MOV SI,p6e88
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e84],AX
  JMP o46c2
o468b:
  MOV AX,word [BP+8]
  CALL o5d66
  MOV SI,p6e9o
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e82],AX
  MOV AX,word [BP+0xa]
  CALL o5d66
  MOV SI,p6e9o
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e84],AX
  JMP o46c2
o46b3:
  CMP AX,5
  JZ o468b
  CMP AX,3
  JZ o4663
  CMP AX,2
  JZ o4654
o46c2:
  CALL o4964
  ADD SP,0xc
  POP BP
  RET

o46ca:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  MOV AX,word [p6e82]
  CALL o5d66
  MOV SI,p6e98
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e82],AX
  MOV AX,word [p6e84]
  CALL o5d66
  MOV SI,p6e98
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e84],AX
  CALL o4964
  MOV AX,1
  PUSH AX
  CALL o41c         ;Delay don't know
  MOV SP,BP
  ADD SP,8
  POP BP
  RET

o47o7:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  MOV AX,word [p6e82]
  CALL o5d66
  MOV SI,p6eao
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e82],AX
  MOV AX,word [p6e84]
  CALL o5d66
  MOV SI,p6eao
  PUSH SI
  CALL o5993
  CALL o5dce
  MOV word [p6e84],AX
  CALL o4964
  MOV AX,1
  PUSH AX
  CALL o41c     ;Delay don't know
  MOV SP,BP
  ADD SP,8
  POP BP
  RET

o4744:
  PUSH BP
  MOV BP,SP
  XOR AX,AX
  MOV word [p6e6o],2
  MOV word [p6e6e],AX
  MOV word [p6e6a],AX
  CALL o49f7
  MOV word [p6e8o],0
  POP BP
  RET

o476o:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p6e8o]
  MOV SI,AX
  CMP SI,0x18
  JNB o4889
  SHL SI,1
  SHL SI,1
  MOV AX,word [cs:SI+o484b]
  MOV word [p6e82],AX
  MOV AX,word [cs:SI+o484b+2]
  MOV word [p6e84],AX
o4889:
  CALL o4964
  INC word [p6e8o]
  POP BP
  RET

o484b:
  DW 0x5f2,0x11d1,0x712,0x11d1,0x5f2,0x11d1,0x712,0x11d1,0x5f2,0x11d1,0x712,0x11d1
  DW 0x5f2,0x11d1,0x712,0x11d1,0x54c, 0xfdf,0x64c, 0xfdf,0x54c, 0xfdf,0x64c, 0xfdf
  DW 0x54c, 0xfdf,0x64c, 0xfdf,0x54c, 0xfdf,0x64c, 0xfdf,0x4b8, 0xe24,0x59c, 0xe24
  DW 0x4b8, 0xe24,0x59c, 0xe24,0x4b8, 0xe24,0x59c, 0xe24,0x4b8, 0xe24,0x59c, 0xe24

o4892:
  PUSH BP
  SUB SP,2
  MOV BP,SP
o4898:
  MOV AX,word [p6e82]
  CMP AX,0x8e8
  JGE o48b8
  MOV BX,0x64
  CWD
  IDIV BX
  ADD word [p6e82],AX
  CALL o4964
  MOV AX,3
  PUSH AX
  CALL o41c     ;Delay don't know
  MOV SP,BP
  JMP o4898
o48b8:
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o48bd — Death sound effect initialization
; Disables sustain (p6e6a=0), silences speaker (o49f7), sets up
; descending tone sweep starting at 300 Hz (p6e7o=0x12c).
;----------------------------------------------------------------------------
o48bd:
  PUSH BP
  MOV BP,SP
  MOV word [p6e6a],0
  CALL o49f7
  MOV word [p6e6e],0
  MOV word [p6e7o],0x12c  ;???
  POP BP
  RET

;----------------------------------------------------------------------------
; o48d7 — Death sound effect step
; Plays current death tone (p6e7o) via o4b13, waits (delay1),
; plays low click (0x28), then increases tone pitch: p6e7o += p6e7o/100.
; Called repeatedly to produce descending "dying" warble.
;----------------------------------------------------------------------------
o48d7:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  PUSH word [p6e7o]
  CALL o4b13
  MOV SP,BP
  CALL delay1            ;Death delay
  MOV AX,0x28
  PUSH AX
  CALL o4b13
  MOV SP,BP
  MOV AX,word [p6e7o]
  MOV BX,0x64
  CWD
  IDIV BX
  ADD word [p6e7o],AX
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o49oa — Birth/spawn sound effect initialization  
; Disables sustain (p6e6a=0), silences speaker (o49f7), sets up
; ascending tone: start=2000 (p6e72), end=1000 (p6e74).
;----------------------------------------------------------------------------
o49oa:
  PUSH BP
  MOV BP,SP
  MOV word [p6e6a],0
  CALL o49f7
  MOV word [p6e6e],0
  MOV word [p6e72],2000
  MOV word [p6e74],1000
  POP BP
  RET

;----------------------------------------------------------------------------
; o492a — Birth/spawn sound effect step
; Sets sound mode 2 (toggle/square wave), programs frequency from
; p6e72 into p6e82, duration from p6e74 into p6e84. Each call
; sweeps: freq decreases by freq/50, duration increases by dur/50.
; Calls o4964 to program PIT, then delay2 for timing.
;----------------------------------------------------------------------------
o492a:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV word [p6e6o],2
  MOV AX,word [p6e72]
  MOV word [p6e82],AX
  MOV BX,0x32
  CWD
  IDIV BX
  SUB word [p6e72],AX
  MOV AX,word [p6e74]
  MOV word [p6e84],AX
  CWD
  IDIV BX
  ADD word [p6e74],AX
  CALL o4964
  CALL delay2           ;Birth delay
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o4964 — Main sound programmer
; If sound enabled (p6e5a≠0): calls o4a3c (envelope update),
; programs PIT Channel 2 frequency from p6e82 via o4b46,
; clamps minimum duration (500 for mode 2, 1000 for mode 1),
; programs PIT Channel 0 timer period from p6e84 (controls
; INT 8 callback rate = how often sound steps occur).
; Also manages volume/envelope decay (p6e86).
;----------------------------------------------------------------------------
o4964:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  CMP word [p6e5a],0
  JNZ o4974
  JMP o49f2
o4974:
  CALL o4a3c
  PUSH word [p6e82]
  CALL o4b46
  MOV SP,BP
  CMP word [p6e84],500
  JGE o4995
  CMP word [p6e6o],2
  JNZ o4995
  MOV word [p6e84],500
o4995:
  CMP word [p6e84],1000
  JGE o49aa
  CMP word [p6e6o],1
  JNZ o49aa
  MOV word [p6e84],1000
o49aa:
  MOV AX,word [p6e84]
  MOV word [p38be],AX
  MOV word [cs:int8speed],AX
  OUT 0x40,AL
  MOV AL,AH
  OUT 0x40,AL
  MOV AX,word [p6e86]
  SUB AX,0xa
  CMP AX,1
  MOV word [BP+2],AX
  JGE o49e1
  MOV word [BP+2],1
o49e1:
  CMP word [BP+2],0x32
  JLE o49ec
  MOV word [BP+2],0x32
o49ec:
  PUSH BX
  PUSH CX
  PUSH DX
  XOR DX,DX
  MOV AX,word [BP+2]
  MOV CX,word [cs:volume+2]
  MOV BX,word [cs:volume]
  CALL lmul
  XOR CX,CX
  MOV BX,100
  CALL ldiv
  CMP DX,0
  JE volok
  XOR AX,AX
  JMP volok2
volok:
  CMP AX,0
  JNE volok2
  MOV AX,1
volok2:
  MOV word [p38c3],AX
  POP DX
  POP CX
  POP BX
o49f2:
  ADD SP,4
  POP BP
  RET

o49f7:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  CMP word [p6e5e],1
  JNZ o4a37
  XOR AX,AX
  MOV BX,0x28
  PUSH BX
  MOV word [p38bc],AX
  MOV word [p6e5e],AX
  CALL o4b46
  MOV SP,BP
  IN AL,0x61
  MOV word [BP+2],AX
  AND AX,0xfc
  OR AL,3
  OUT 0x61,AL
o4a37:
  ADD SP,4
  POP BP
  RET

o4a3c:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,word [p6e6o]
  CMP word [p6e5e],0
  MOV word [p38bc],AX
  JNZ o4a87
  CMP word [p6e5a],0
  JZ o4a87
  MOV word [p6e5e],1
  MOV AX,0x28
  PUSH AX
  CALL o4b46
  MOV SP,BP
  IN AL,0x61
  XOR AH,AH
  MOV word [BP+2],AX
  XOR AH,AH
  OR AL,3
  OUT 0x61,AL
o4a87:
  ADD SP,4
  POP BP
  RET

o4a8c:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p6e5c],0
  JNZ o4aa2
  CALL o117f
  MOV word [p6e5c],1
o4aa2:
  ADD SP,2
  POP BP
  RET

o4b13:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p6e5a],0
  JZ o4b41
  MOV AX,word [BP+6]
  OUT 0x42,AL
  MOV AL,AH
  OUT 0x42,AL
o4b41:
  ADD SP,2
  POP BP
  RET

o4b46:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  OUT 0x42,AL
  MOV AL,AH
  OUT 0x42,AL
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o4b72 — Digit character renderer (0-9)
; Draws a single digit at the given screen position.
;   [BP+6] = digit value (0-9)
;   [BP+8] = x position (shifted left 2 = ×4 pixel spacing)
;   [BP+0xa] = color
; Looks up bitmap pointer from o4c61 table (10 entries, each
; pointing to a 2×5 pixel digit bitmap: p6eb4..p6f2o).
; Draws via oc83 (sprite draw).
;----------------------------------------------------------------------------
o4b72:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  MOV SI,AX
  CMP SI,0xa
  JNB o4c85
  SHL SI,1
  MOV BX,word [cs:SI+o4c61]
  MOV AX,word [BP+8]
  SHL AX,1
  SHL AX,1
  PUSH BX
  PUSH word [BP+0xa]
  PUSH AX
  CALL oc83
  MOV SP,BP
o4c85:
  ADD SP,2
  POP BP
  RET

o4c61:
  DW p6eb4,p6eco,p6ecc,p6ed8,p6ee4
  DW p6efo,p6efc,p6fo8,p6f14,p6f2o

;----------------------------------------------------------------------------
; o4c8a — Full character renderer (ASCII 0x20-0x5F)
; Draws a single character at given position using oc83 (sprite draw).
;   [BP+4] = ASCII character code
;   [BP+6] = x position
;   [BP+8] = color
; Uses lookup table o4f54 (64 entries) mapping ASCII 0x20..0x5F
; to bitmap pointers. Each character bitmap is 5×7 pixels.
; Bitmaps for A-Z at p6f2c..p72c9, digits use separate digit bitmaps,
; special chars (space, period, slash, etc.) also included.
; Returns silently if character is out of range or pointer is NULL.
;----------------------------------------------------------------------------
o4c8a:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV SI,AX
  SUB SI,0x20
  JB o4fe9
  CMP SI,0x40
  JNB o4fe9
  SHL SI,1
  MOV AX,word [cs:SI+o4f54]
  CMP AX,0
  JE o4fe9
  PUSH AX
  PUSH word [BP+8]
  PUSH word [BP+6]
  CALL oc83
  MOV SP,BP
o4fe9:
  POP BP
  RET

o4f54:
  DW p72ee,0,0,0,0,0,0,0,0,0,0,0,0,0,p7313,p7416
  DW p735d,p7382,p73a7,p73cc,p73f1
  DW p7416,p743b,p746o,p7485,p74aa
  DW 0,0,0,0,0,0,0,p6f2c,p6f51,p6f76,p6f9b
  DW p6fco,p6fe5,p7ooa,p7o2f,p7o54
  DW p7o79,p7o9e,p7oc3,p7oe8,p71od
  DW p7132,p7157,p717c,p71a1,p71c6
  DW p71eb,p721o,p7235,p725a,p727f
  DW p72a4,p72c9,0,0,0,0,p7338

;----------------------------------------------------------------------------
; o4feb — Text string printer
; Renders a NUL-terminated string character by character.
;   [BP+0xa] = pointer to string
;   [BP+0xc] = x start position
;   [BP+0xe] = color
; Characters are spaced 10 pixels apart (BX += char_index × 10).
; Calls o4c8a for each character.
;----------------------------------------------------------------------------
o4feb:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV word [BP+4],0
o4ff6:
  MOV AX,word [BP+4]
  MOV SI,word [BP+0xa]
  ADD SI,AX
  MOV BL,byte [SI]
  XOR BH,BH
  TEST BX,BX
  MOV word [BP],BX
  JZ o5o24
  MOV BX,0xa
  IMUL BX
  MOV BX,word [BP+0xc]
  ADD BX,AX
  PUSH word [BP+0xe]
  PUSH BX
  PUSH word [BP]
  CALL o4c8a
  MOV SP,BP
  INC word [BP+4]
  JMP o4ff6
o5o24:
  ADD SP,6
  POP BP
  RET

;----------------------------------------------------------------------------
; o5o29 — Color palette cycling (attract mode animation)
; Cycles the text/sprite color palette index through colors 9-14
; using modular arithmetic: color = ((input+1) % 6) + 9.
; Applies the color to letter bitmaps (p7ooa = 'G' bitmap) via o521a.
; Creates the animated rainbow text effect on the title screen.
;----------------------------------------------------------------------------
o5o29:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  INC AX
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p7ooa
  PUSH BX
  CALL o521a
  MOV SP,BP
  MOV AX,word [BP+6]
  INC AX
  INC AX
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p6f2c
  PUSH BX
  CALL o521a
  MOV SP,BP
  MOV AX,word [BP+6]
  ADD AX,3
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p7oe8
  PUSH BX
  CALL o521a
  MOV SP,BP
  MOV AX,word [BP+6]
  ADD AX,4
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p7132
  PUSH BX
  CALL o521a
  MOV SP,BP
  MOV AX,word [BP+6]
  ADD AX,5
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p7235
  PUSH BX
  CALL o521a
  MOV SP,BP
  MOV AX,word [BP+6]
  INC AX
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p6fco
  PUSH BX
  CALL o521a
  MOV SP,BP
  MOV AX,word [BP+6]
  INC AX
  INC AX
  MOV BX,6
  CWD
  IDIV BX
  ADD DX,9
  PUSH DX
  MOV BX,p71a1
  PUSH BX
  CALL o521a
  MOV SP,BP
  ADD SP,2
  POP BP
  RET

;----------------------------------------------------------------------------
; o5odd — Set border/sprite/text color
; Sets the drawing color for border elements and character bitmaps.
;   [BP+4] = color index (0-15)
; Applies the color to letter bitmaps A-G (p6f2c..p7ooa) by calling
; o521a for each. This changes the draw color for subsequent text
; and border rendering operations.
;----------------------------------------------------------------------------
o5odd:
  PUSH BP
  MOV BP,SP
  PUSH word [BP+4]
  MOV AX,p6f2c
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p6f51
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p6f76
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p6f9b
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p6fco
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p6fe5
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7ooa
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7o2f
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7o54
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7o79
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7o9e
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7oc3
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7oe8
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p71od
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7132
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7157
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p717c
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p71a1
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p71c6
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p71eb
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p721o
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p7235
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p725a
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p727f
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p72a4
  PUSH AX
  CALL o521a
  MOV SP,BP
  PUSH word [BP+4]
  MOV AX,p72c9
  PUSH AX
  CALL o521a
  MOV SP,BP
  POP BP
  RET

o521a:
  PUSH BP
  SUB SP,0xc
  MOV BP,SP
  MOV AX,word [BP+0x12]
  MOV word [BP+8],AX
  SHL AX,4
  MOV word [BP+6],2
  MOV word [BP+0xa],AX
o5232:
  MOV AX,word [BP+6]
  CMP AX,0x25
  JGE o528o
  MOV SI,word [BP+0x10]
  ADD SI,AX
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,0xf
  MOV word [BP+2],AX
  MOV word [BP],SI
  JZ o525a
  AND AX,0xf0
  MOV byte [SI],AL
  XOR AH,AH
  OR AX,word [BP+8]
  MOV byte [SI],AL
o525a:
  MOV SI,word [BP+0x10]
  ADD SI,word [BP+6]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,0xf0
  MOV word [BP+2],AX
  MOV word [BP],SI
  JZ o527b
  AND AX,0xf
  MOV byte [SI],AL
  XOR AH,AH
  OR AX,word [BP+0xa]
  MOV byte [SI],AL
o527b:
  INC word [BP+6]
  JMP o5232
o528o:
  ADD SP,0xc
  POP BP
  RET

o536d:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  SUB AX,0x30
  JBE o53cb
  CMP AX,9
  JG o53cb
  POP BP
  RET
o53cb:
  XOR AX,AX
  POP BP
  RET

o53cd:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV SI,AX
  SUB SI,2
  JB o551b
  CMP SI,0x38
  JNB o551b
  XOR AH,AH
  MOV AL,byte [cs:SI+o5498]
  POP BP
  RET
o551b:
  XOR AX,AX
  POP BP
  RET

o5498:
  DB "1234567890",0,0,0,0
  DB "QWERTYUIOP",0,0,0,0
  DB "ASDFGHJKL",0,0,0,0,0
  DB "ZXCVBNM",0,".",0,0,0,0," "

o551e:
  PUSH BP
  MOV BP,SP
  MOV AX,0xa
  PUSH AX
  CALL o1o5o
  MOV SP,BP
  MOV AX,0xd
  PUSH AX
  CALL o1o5o
  MOV SP,BP
  POP BP
  RET

o5535:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  MOV word [BP+4],0
o554o:
  MOV SI,word [BP+0xc]
  ADD SI,word [BP+4]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  MOV word [BP],AX
  JZ o5562
  PUSH word [BP+0xe]
  PUSH AX
  MOV word [BP+6],AX
  CALL o1o5o
  MOV SP,BP
  INC word [BP+4]
  JMP o554o
o5562:
  CALL o551e
  ADD SP,8
  POP BP
  RET

;============================================================================
; o556a — MAIN GAME ENTRY POINT / STARTUP
; This is where execution begins after the DOS loader.
; Initialization sequence:
;   1. Set p74d8=0xAF (game ID/flag)
;   2. Call o4c3 (detect video adapter)
;   3. Call o44b with mode 0 (set CGA mode 4)
;   4. Install INT 9 keyboard handler (ocec)
;   5. Clear last-scancode (pc3)
;   6. Load high scores from STYX.SCO (o37cf)
;   7. Initialize sound system (o4427)
;   8. Load and analyze STYX.BMP (load_startup_bmp)
;   9. If BMP loaded: show startup screen with per-scanline
;      CGA palette flip + high scores, wait for keypress,
;      then jump directly to o55do_go (game init)
;  10. If no BMP: fall through to o55a8 (old RLE attract mode)
;============================================================================
o556a:
  PUSH BP
  SUB SP,0xa
  MOV BP,SP
  MOV word [p74d8],0xaf
  MOV word [BP+8],0
  CALL o4c3
  XOR AX,AX
  PUSH AX
  CALL o44b
  POP AX
  CALL ocec
  MOV byte [pc3],0
  CALL o37cf
  CALL o4427

  ; Show loading splash screen (text mode)
  MOV AX,0x0003                ;Set 80x25 text mode, clears screen
  INT 0x10
  MOV DX,ss_splash
  MOV AH,0x09                  ;DOS print string
  INT 0x21
  MOV byte [ss_border_ctr],0

  CALL load_startup_bmp
  CMP byte [ss_loaded],0
  JZ o55a8
  CALL show_startup_screen
  MOV byte [pc3],0
  JMP o55do_go
;----------------------------------------------------------------------------
; o55a8 — Attract mode / title screen (called after game over via o57af)
; If STYX.BMP was loaded (ss_loaded=1): shows BMP startup screen
;   with per-scanline palette flip + high scores, waits for keypress,
;   then jumps directly to o55do_go (skipping joystick init).
; If no BMP (ss_loaded=0): falls through to o55b6 which shows the
;   old RLE-decoded STYX logo (o1142) + high score table (o3e6d),
;   then falls through to o55do.
;----------------------------------------------------------------------------
o55a8:
  CMP byte [ss_loaded],0
  JZ .old_attract
  ; BMP mode: show BMP, then straight to game
  MOV byte [pc3],0
  CALL show_startup_screen
  MOV byte [pc3],0
  JMP o55do_go
.old_attract:
  MOV AL,byte [pc3]
  TEST AL,AL
  JZ o55b6
  XOR AH,AH
  AND AX,0x80
  JZ o55do
o55b6:
  ; Belt-and-suspenders: if BMP loaded, never show old RLE title
  CMP byte [ss_loaded],0
  JNZ o55do_go
  XOR AX,AX
  PUSH AX
  CALL o44b
  MOV SP,BP
  MOV DX,0x3d9
  XOR AL,AL
  OUT DX,AL    ;Border colour 0
  CALL o1142
  CALL o3e6d
;----------------------------------------------------------------------------
; o55do — Game initialization (full path from old attract mode)
;   Calls o3575 (joystick reset) and o364c (wait for button release)
;   then falls through to o55do_go.
;
; o55do_go — Game initialization (direct entry from BMP startup screen)
;   Skips joystick wait (keypress already consumed by BMP display loop).
;   1. Clears last-scancode, disables VRAM writes
;   2. Sets level=1, loads level-specific BMP (load_level_bmp)
;   3. Enters PC1 hidden 160×200×16 graphics mode (o543)
;   4. Clears screen with color 6 (o8c1)
;   5. Draws game border: double rectangle at (1,9)-(0x9E,0x62)
;      outer border color 7, inner border 2 pixels inside
;   6. Sets initial state: lives=3
;   7. Resets difficulty (o38d8), sound (o43c7)
;   8. Calls o57b5 (level setup), enables VRAM writes
;   9. Activates BMP palette if BMP was loaded
;  10. Refreshes screen (o5c3), falls through to o56dd level loop
;----------------------------------------------------------------------------
o55do:
  CALL o3575
  CALL o364c
o55do_go:
  MOV byte [pc3],0
  MOV word [pcb],0
  MOV word [p74d4],1       ;Set level=1 before loading its BMP
  MOV AX,6
  PUSH AX
  ; Load level-specific BMP background (before entering graphics mode)
  CALL load_level_bmp
  CALL o543
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  CALL o8c1
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,9
  PUSH AX
  MOV AX,0x9e
  PUSH AX
  MOV AX,9
  PUSH AX
  MOV AX,1
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x62
  PUSH AX
  MOV AX,0x9e
  PUSH AX
  MOV AX,9
  PUSH AX
  MOV AX,0x9e
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x62
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,0x62
  PUSH AX
  MOV AX,0x9e
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,9
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,0x62
  PUSH AX
  MOV AX,1
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0xa
  PUSH AX
  MOV AX,0x9d
  PUSH AX
  MOV AX,0xa
  PUSH AX
  MOV AX,2
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x61
  PUSH AX
  MOV AX,0x9d
  PUSH AX
  MOV AX,0xa
  PUSH AX
  MOV AX,0x9d
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0x61
  PUSH AX
  MOV AX,2
  PUSH AX
  MOV AX,0x61
  PUSH AX
  MOV AX,0x9d
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,0xa
  PUSH AX
  MOV AX,2
  PUSH AX
  MOV AX,0x61
  PUSH AX
  MOV AX,2
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV word [p74d2],3
  CALL o38d8
  CALL o43c7
  MOV byte [pc3],0
  CALL o57b5
  MOV word [pcb],1
  ; Activate BMP palette for gameplay (if BMP was loaded)
  CMP byte [bmp_loaded],0
  JZ .no_bmp_pal
  CALL set_bmp_game_palette
.no_bmp_pal:
  CALL o5c3
;============================================================================
; o56dd — MAIN LEVEL LOOP
; Core game loop that runs continuously during gameplay.
; Structure per iteration:
;   1. Check lives (p74d2) — if 0, jump to o57af (game over → attract)
;   2. Clear death flag (p74do=0)
;   3. Inner loop (o56ed): repeats while player alive (p74do=0)
;      and level not complete (p74d6=0):
;      - Call o21do (player movement) × 4 times
;      - Call o135f (enemy AI) × 3 times
;      - Call o435e (sound update) × 3 times
;      - Call o1bo9 (tail movement) × 4 times
;      - Call o38ef (difficulty progression)
;      - Call o58ac (F1 pause check)
;   4. On death (p74do≠0): wobble effect (o297a), flash (o1f25),
;      erase enemies (o1dcb), decrement lives, update score
;   5. On level complete (p74d6≠0): silence sound (o49f7),
;      flash (o1f25), fill remaining (o28bc), award bonus (o3bd3),
;      pause (o57d5), advance level, redraw field, loop back
;   6. On game over: check high score (o3a65), return to o55a8
;============================================================================
o56dd:
  CMP word [p74d2],0
  JNZ o56e7
  JMP o57af
o56e7:
  MOV word [p74do],0
o56ed:
  CMP word [p74do],0
  JNZ o5739
  CMP word [p74d6],0
  JNZ o5739
  CALL o21do
  CALL o135f
  CALL o435e
  CALL o1bo9
  CALL o21do
  CALL o135f
  CALL o435e
  CALL o1bo9
  CALL o21do
  CALL o1bo9
  CALL o21do
  CALL o135f
  CALL o435e
  CALL o21do
  CALL o1bo9
  CALL o38ef
  CALL o58ac
  JMP o56ed
;--- o5739: Player death handler ---
; Runs wobble effect (o297a), screen flash (o1f25), erases enemies
; (o1dcb), decrements lives counter (p74d2), updates score display.
o5739:
  CMP word [p74do],0
  JZ o575o
  CALL o297a
  CALL o1f25
  CALL o1dcb
  DEC word [p74d2]
  CALL o3cc3
;--- o575o: Level complete handler ---
; Silences sound (o49f7), flashes screen (o1f25), fills remaining
; territory (o28bc), calculates bonus (o3bd3), pauses (o57d5),
; advances level (p74d4, max 9), clears screen row-by-row,
; resets to CGA palette, sets up next level (o57b5), refreshes.
o575o:
  CMP word [p74d6],0
  JZ o56dd
  CALL o49f7
  CALL o1f25
  CALL o28bc
  CALL o3bd3
  CALL o57d5
  MOV AX,word [p74d4]
  INC AX
  CMP AX,9
  MOV word [p74d4],AX
  JLE o5778
  MOV word [p74d4],9
o5778:
  XOR AX,AX
  MOV word [BP+6],AX
  MOV word [pcb],AX
o578o:
  CMP word [BP+6],9
  JGE o57ao
  XOR AX,AX
  PUSH AX
  PUSH word [BP+6]
  MOV AX,0x9f
  PUSH AX
  PUSH word [BP+6]
  XOR AX,AX
  PUSH AX
  CALL oab6
  MOV SP,BP
  INC word [BP+6]
  JMP o578o
o57ao:
  CALL load_level_bmp          ;Load BMP for new level (if it exists)
  MOV word [pcb],1
  CMP byte [bmp_loaded],0
  JNZ .level_has_bmp
  CALL pc1_set_cga_palette     ;No BMP: use CGA palette
  JMP .level_palette_done
.level_has_bmp:
  CALL set_bmp_game_palette    ;BMP loaded: use BMP palette
.level_palette_done:
  CALL o57b5
  CALL o5c3
  JMP o56dd
o57af:
  CALL o3a65
  CALL pc1_set_cga_palette     ;Reset palette for title screen
  JMP o55a8
o57b5:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV word [p74d6],0
  CALL o1227
  CALL o1ae5
  CALL o21ad
  CALL o37aa
  CALL o3cc3
  ADD SP,2
  POP BP
  RET

o57d5:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o4744
  MOV word [pcb],0
  MOV word [BP+4],0xb
o57e9:
  CMP word [BP+4],0x1c
  JGE o58oa
  XOR AX,AX
  PUSH AX
  PUSH word [BP+4]
  MOV AX,0x9c
  PUSH AX
  PUSH word [BP+4]
  MOV AX,3
  PUSH AX
  CALL oab6
  MOV SP,BP
  INC word [BP+4]
  JMP o57e9
o58oa:
  MOV word [BP+2],0x1c
o58of:
  MOV AX,word [BP+2]
  CMP AX,0x61
  JGE o5847
  MOV word [BP+4],AX
o581a:
  MOV AX,word [BP+2]
  ADD AX,3
  MOV BX,word [BP+4]
  CMP BX,AX
  JGE o583e
  XOR AX,AX
  PUSH AX
  PUSH BX
  MOV AX,0x9c
  PUSH AX
  PUSH BX
  MOV AX,3
  PUSH AX
  CALL oab6
  MOV SP,BP
  INC word [BP+4]
  JMP o581a
o583e:
  CALL o476o
  MOV AX,8
  PUSH AX
  CALL o41c       ;Delay don't know
  POP AX
  ADD word [BP+2],3
  JMP o58of
o5847:
  CALL o4892
  CALL o4744
  MOV word [pcb],1
  ADD SP,6
  POP BP
  RET

o5858:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [p74do],AX
  POP BP
  RET

o5863:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV word [p74d6],AX
  POP BP
  RET

o586e:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP word [p74do],0
  JNZ o5882
  CMP word [p74d6],0
  JZ o588a
o5882:
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o588a:
  XOR AX,AX
  ADD SP,2
  POP BP
  RET

o5891:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p74d4]
  POP BP
  RET

o58a4:
  PUSH BP
  MOV BP,SP
  MOV AX,word [p74d2]
  POP BP
  RET

;----------------------------------------------------------------------------
; o58ac — F1 pause handler
; Checks if F1 key was pressed (pbd flag). If so:
;   - Saves sound state and silences speaker
;   - Enters wait loop until F1 pressed again
;   - Restores sound state on unpause
; During pause, polls keyboard via pc3 and F1 flag (pbd).
;----------------------------------------------------------------------------
o58ac:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AL,byte [pc3]
  XOR AH,AH
  CMP AX,0x3b
  MOV word [BP],AX
  JZ o58c4
  CMP AX,0xbb
  JNZ o5934
o58c4:
  MOV AX,0x28
  PUSH AX
  CALL o4b13
  MOV SP,BP
  CALL o49f7
  MOV AX,3
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,1
  PUSH AX
  XOR AX,AX
  PUSH AX
  MOV AX,p74da
  PUSH AX
  CALL o4feb
  MOV SP,BP
o58e9:
  MOV AL,byte [pc3]
  XOR AH,AH
  CMP AX,0x3b
  JNZ o58fe
  MOV AX,0x28
  PUSH AX
  CALL o4b13
  MOV SP,BP
  JMP o58e9
o58fe:
  MOV AL,byte [pc3]
  XOR AH,AH
  AND AX,0x80
  JZ o5913
  MOV AX,0x28
  PUSH AX
  CALL o4b13
  MOV SP,BP
  JMP o58fe
o5913:
  MOV AX,7
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,1
  PUSH AX
  XOR AX,AX
  PUSH AX
  MOV AX,p74eb
  PUSH AX
  CALL o4feb
  MOV SP,BP
  CALL o3cc3
  MOV byte [pc3],0
o5934:
  ADD SP,4
  POP BP
  RET

o596b:
  MOV word [BP],0x10
o597o:
  SHR SI,1
  RCR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  SHR DI,1
  JNB o598d
  ADD DX,word [BP+0x14]
  ADC CX,word [BP+0x12]
  ADC BX,word [BP+0x10]
  ADC AX,word [BP+0xe]
  ADC SI,0
o598d:
  DEC word [BP]
  JNZ o597o
  RET

;----------------------------------------------------------------------------
; o5993 — 32-bit multiply (floating-point)
; Multiplies two 32-bit floating-point values. Used by the printf
; formatter and bonus score calculations. Handles sign, mantissa
; multiplication, and exponent addition with normalization.
;----------------------------------------------------------------------------
o5993:
  PUSH BP
  PUSH DI
  SUB SP,0x16
  MOV BP,SP
  MOV DI,word [SI+6]
  XOR DI,AX
  MOV word [BP+2],DI
  AND AX,0x7fff
  JNZ o59b8
  MOV DI,AX
  OR DI,BX
  JNZ o59b8
  OR DI,CX
  JNZ o59b8
  OR DI,DX
  JNZ o59b8
  JMP o5a41
o59b8:
  MOV DI,word [SI+6]
  AND DI,0x7fff
  JNZ o59cf
  OR DI,word [SI+4]
  JNZ o59cf
  OR DI,word [SI+2]
  JNZ o59cf
  OR DI,word [SI]
  JZ o5a41
o59cf:
  CALL o689c
  MOV word [BP+4],SI
  MOV word [BP+6],AX
  MOV word [BP+8],BX
  MOV word [BP+0xa],CX
  MOV word [BP+0xc],DX
  MOV SI,word [BP+0x1c]
  MOV AX,word [SI+6]
  MOV BX,word [SI+4]
  MOV CX,word [SI+2]
  MOV DX,word [SI]
  CALL o689c
  ADD word [BP+4],SI
  MOV word [BP+0xe],AX
  MOV word [BP+0x10],BX
  MOV word [BP+0x12],CX
  MOV word [BP+0x14],DX
  XOR SI,SI
  XOR AX,AX
  XOR BX,BX
  XOR CX,CX
  XOR DX,DX
  MOV DI,word [BP+0xc]
  CALL o596b
  MOV DI,word [BP+0xa]
  CALL o596b
  MOV DI,word [BP+8]
  CALL o596b
  MOV DI,word [BP+6]
  CALL o596b
o5a23:
  TEST SI,SI
  JZ o5a36
  SHR SI,1
  RCR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  INC word [BP+4]
  JMP o5a23
o5a36:
  MOV SI,word [BP+4]
  MOV DI,word [BP+2]
  CALL o68ce
  JMP o5a49
o5a41:
  XOR AX,AX
  XOR BX,BX
  XOR CX,CX
  XOR DX,DX
o5a49:
  MOV SI,word [BP+0x1c]
  ADD SP,0x16
  POP DI
  POP BP
  RET 2

o5a54:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV word [BP],AX
  OR AX,BX
  JZ o5aco
  MOV word [BP+2],CX
  OR CX,DX
  JZ o5abc
  MOV AX,word [BP]
  MOV CX,word [BP+2]
  MOV SI,AX
  TEST SI,SI
  JNS o5a7b
  NOT AX
  NEG BX
  SBB AX,-1
o5a7b:
  XOR SI,CX
  MOV word [BP],SI
  TEST CX,CX
  JNS o5a8b
  NOT CX
  NEG DX
  SBB CX,-1
o5a8b:
  MOV SI,0x20
  MOV word [BP+2],SI
  XOR SI,SI
  XOR DI,DI
o5a95:
  SHR SI,1
  RCR DI,1
  RCR AX,1
  RCR BX,1
  JNB o5aa3
  ADD DI,DX
  ADC SI,CX
o5aa3:
  DEC word [BP+2]
  JNZ o5a95
  SHR AX,1
  RCR BX,1
  MOV SI,word [BP]
  TEST SI,SI
  JNS o5aco
  NOT AX
  NEG BX
  SBB AX,-1
  JMP o5aco
o5abc:
  XOR AX,AX
  XOR BX,BX
o5aco:
  ADD SP,4
  POP BP
  RET

o5ac5:
  PUSH BP
  MOV BP,SP
  PUSH word [BP+6]
  PUSH word [BP+4]
  CALL o172
  MOV SP,BP
  POP BP
  RET

o5ad5:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV word [BP+2],0
o5aeo:
  MOV SI,word [BP+8]
  ADD SI,word [BP+2]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  JZ o5af3
  INC word [BP+2]
  JMP o5aeo
o5af3:
  MOV AX,word [BP+2]
  ADD SP,4
  POP BP
  RET

o5afb:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV word [BP],CX
  OR CX,DX
  JNZ o5bof
  XOR AX,AX
  XOR BX,BX
  JMP o5ba6
o5bof:
  MOV word [BP+2],AX
  OR AX,BX
  JNZ o5b1d
  XOR CX,CX
  XOR DX,DX
  JMP o5ba6
o5b1d:
  MOV CX,word [BP]
  MOV AX,word [BP+2]
  MOV SI,AX
  TEST SI,SI
  JNS o5b3o
  NOT AX
  NEG BX
  SBB AX,-1
o5b3o:
  XOR SI,CX
  MOV word [BP],SI
  XOR SI,SI
  TEST CX,CX
  JNS o5b42
  NOT CX
  NEG DX
  SBB CX,-1
o5b42:
  JNZ o5b69
  TEST DX,DX
  JS o5b61
  MOV DI,0x20
o5b4b:
  SHL BX,1
  RCL AX,1
  RCL SI,1
  CMP SI,DX
  JB o5b58
  SUB SI,DX
  INC BX
o5b58:
  DEC DI
  JNZ o5b4b
  XOR CX,CX
  MOV DX,SI
  JMP o5b8a
o5b61:
  SHL BX,1
  RCL AX,1
  SHL DX,1
  RCL CX,1
o5b69:
  MOV DI,0x10
o5b6c:
  SHL BX,1
  RCL AX,1
  RCL SI,1
  CMP SI,CX
  JB o5b81
  JNZ o5b7c
  CMP AX,DX
  JB o5b81
o5b7c:
  SUB AX,DX
  SBB SI,CX
  INC BX
o5b81:
  DEC DI
  JNZ o5b6c
  MOV CX,SI
  MOV DX,AX
  XOR AX,AX
o5b8a:
  TEST word [BP],0x8000
  JZ o5b98
  NOT AX
  NEG BX
  SBB AX,-1
o5b98:
  TEST word [BP+2],0x8000
  JZ o5ba6
  NOT CX
  NEG DX
  SBB CX,-1
o5ba6:
  ADD SP,4
  POP BP
  RET

o5bab:
  PUSH BP
  SUB SP,4
  MOV BP,SP
o5bb1:
  MOV SI,word [BP+8]
  INC word [BP+8]
  MOV DI,word [BP+0xa]
  INC word [BP+0xa]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  TEST AL,AL
  JNZ o5bb1
  ADD SP,4
  POP BP
  RET

o5bca:
  PUSH BP
  SUB SP,0x14
  MOV BP,SP
  MOV SI,word [BP+0x18]
  MOV byte [SI],0
  CMP word [BP+0x1c],2
  JGE o5be3
  XOR AX,AX
  ADD SP,0x14
  POP BP
  RET
o5be3:
  MOV word [BP+4],0xb
o5be8:
  MOV AX,word [BP+4]
  DEC AX
  MOV SI,AX
  MOV word [BP+4],AX
  MOV AX,word [BP+0x1a]
  MOV BX,0xa
  XOR DX,DX
  DIV BX
  ADD DX,0x30
  MOV byte [BP+SI+8],DL
  MOV AX,word [BP+0x1a]
  XOR DX,DX
  DIV BX
  MOV word [BP+0x1a],AX
  CMP word [BP+0x1a],0
  JNZ o5be8
  MOV AX,0xb
  MOV BX,word [BP+4]
  SUB AX,BX
  MOV CX,word [BP+0x1c]
  CMP AX,CX
  MOV word [BP],AX
  JL o5c29
  INC AX
  SUB AX,CX
  ADD word [BP+4],AX
o5c29:
  MOV word [BP+6],0
o5c2e:
  MOV AX,word [BP+4]
  CMP AX,0xb
  JGE o5c4b
  MOV SI,word [BP+0x18]
  ADD SI,word [BP+6]
  INC word [BP+4]
  MOV DI,AX
  MOV AL,byte [BP+DI+8]
  MOV byte [SI],AL
  INC word [BP+6]
  JMP o5c2e
o5c4b:
  MOV AX,word [BP+6]
  MOV SI,word [BP+0x18]
  ADD SI,AX
  MOV byte [SI],0
  ADD SP,0x14
  POP BP
  RET
o5c5b:
  MOV word [BP],0x10
  XOR DI,DI
o5c62:
  SHL DI,1
  TEST SI,SI
  JNZ o5c82
  CMP AX,word [BP+0xe]
  JB o5c92
  JNZ o5c82
  CMP BX,word [BP+0x10]
  JB o5c92
  JNZ o5c82
  CMP CX,word [BP+0x12]
  JB o5c92
  JNZ o5c82
  CMP DX,word [BP+0x14]
  JBE o5c92
o5c82:
  SUB DX,word [BP+0x14]
  SBB CX,word [BP+0x12]
  SBB BX,word [BP+0x10]
  SBB AX,word [BP+0xe]
  SBB SI,0
  INC DI
o5c92:
  SHL DX,1
  RCL CX,1
  RCL BX,1
  RCL AX,1
  RCL SI,1
  DEC word [BP]
  JNZ o5c62
  RET

;----------------------------------------------------------------------------
; o5ca2 — 32-bit divide (floating-point)
; Divides two 32-bit floating-point values. Handles sign, mantissa
; division via repeated subtraction, exponent subtraction with
; normalization. Returns quotient in standard FP format.
;----------------------------------------------------------------------------
o5ca2:
  PUSH BP
  PUSH DI
  SUB SP,0x16
  MOV BP,SP
  MOV DI,word [SI+6]
  XOR DI,AX
  MOV word [BP+2],DI
  AND AX,0x7fff
  JNZ o5cc7
  MOV DI,AX
  OR DI,BX
  JNZ o5cc7
  OR DI,CX
  JNZ o5cc7
  OR DI,DX
  JNZ o5cc7
  JMP o5d53
o5cc7:
  MOV DI,word [SI+6]
  AND DI,0x7fff
  JNZ o5ce8
  OR DI,word [SI+4]
  JNZ o5ce8
  OR DI,word [SI+2]
  JNZ o5ce8
  OR DI,word [SI]
  JNZ o5ce8
  MOV AX,3
  PUSH AX
  CALL o61of
  POP AX
  JMP o5d53
o5ce8:
  CALL o689c
  MOV word [BP+4],SI
  MOV word [BP+6],AX
  MOV word [BP+8],BX
  MOV word [BP+0xa],CX
  MOV word [BP+0xc],DX
  MOV SI,word [BP+0x1c]
  MOV AX,word [SI+6]
  MOV BX,word [SI+4]
  MOV CX,word [SI+2]
  MOV DX,word [SI]
  CALL o689c
  SUB word [BP+4],SI
  MOV word [BP+0xe],AX
  MOV word [BP+0x10],BX
  MOV word [BP+0x12],CX
  MOV word [BP+0x14],DX
  XOR SI,SI
  MOV AX,word [BP+6]
  MOV BX,word [BP+8]
  MOV CX,word [BP+0xa]
  MOV DX,word [BP+0xc]
  CALL o5c5b
  MOV word [BP+6],DI
  CALL o5c5b
  MOV word [BP+8],DI
  CALL o5c5b
  MOV word [BP+0xa],DI
  CALL o5c5b
  MOV DX,DI
  MOV CX,word [BP+0xa]
  MOV BX,word [BP+8]
  MOV AX,word [BP+6]
  MOV SI,word [BP+4]
  MOV DI,word [BP+2]
  CALL o68ce
  JMP o5d5b
o5d53:
  XOR AX,AX
  XOR BX,BX
  XOR CX,CX
  XOR DX,DX
o5d5b:
  MOV SI,word [BP+0x1c]
  ADD SP,0x16
  POP DI
  POP BP
  RET 2

o5d66:
  PUSH SI
  PUSH DI
  XOR BX,BX
  XOR CX,CX
  XOR DX,DX
  MOV DI,AX
  TEST AX,AX
  JNS o5d76
  NEG AX
o5d76:
  MOV SI,0xf
  CALL o68ce
  POP DI
  POP SI
  RET

o5dce:
  PUSH SI
  PUSH DI
  MOV DI,AX
  AND DI,0x7fff
  JNZ o5ddd
o5dd8:
  XOR AX,AX
  POP DI
  POP SI
  RET
o5ddd:
  PUSH AX
  CALL o689c
  POP DI
  INC SI
  JLE o5dd8
  CMP SI,0x10
  JL o5def
  MOV AX,0x7fff
  JMP o5df6
o5def:
  MOV CX,0x10
  SUB CX,SI
  SHR AX,CL
o5df6:
  TEST DI,DI
  JNS o5dfc
  NEG AX
o5dfc:
  POP DI
  POP SI
  RET

o5ede:
  PUSH BP
  SUB SP,4
  MOV BP,SP
o5ee4:
  MOV SI,word [BP+8]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  JZ o5ef4
  INC word [BP+8]
  JMP o5ee4
o5ef4:
  MOV SI,word [BP+8]
  INC word [BP+8]
  MOV DI,word [BP+0xa]
  INC word [BP+0xa]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  TEST AL,AL
  JNZ o5ef4
  ADD SP,4
  POP BP
  RET

;----------------------------------------------------------------------------
; o5f1b — 32-bit add (floating-point)
; Adds two 32-bit floating-point values. Aligns exponents,
; adds mantissas, normalizes result. Handles sign and overflow.
;----------------------------------------------------------------------------
o5f1b:
  PUSH BP
  PUSH DI
  SUB SP,0xe
  MOV BP,SP
  MOV word [BP],0x8000
  MOV word [BP+2],AX
  AND AX,0x7fff
  JNZ o5f4e
  MOV DI,AX
  OR DI,BX
  JNZ o5f4e
  OR DI,CX
  JNZ o5f4e
  OR DI,DX
  JNZ o5f4e
  MOV AX,word [SI+6]
  XOR AX,word [BP]
  MOV BX,word [SI+4]
  MOV CX,word [SI+2]
  MOV DX,word [SI]
  JMP o6o4b
o5f4e:
  MOV DI,word [SI+6]
  AND DI,0x7fff
  JNZ o5f6b
  OR DI,word [SI+4]
  JNZ o5f6b
  OR DI,word [SI+2]
  JNZ o5f6b
  OR DI,word [SI]
  JNZ o5f6b
  MOV AX,word [BP+2]
  JMP o6o4b
o5f6b:
  CALL o689c
  MOV word [BP+4],SI
  MOV word [BP+6],AX
  MOV word [BP+8],BX
  MOV word [BP+0xa],CX
  MOV word [BP+0xc],DX
  MOV SI,word [BP+0x14]
  MOV AX,word [SI+6]
  MOV BX,word [SI+4]
  MOV CX,word [SI+2]
  MOV DX,word [SI]
  CALL o689c
  MOV DI,SI
  SUB SI,word [BP+4]
  JGE o5fbf
  CMP SI,-0x40
  JG o5fb2
  MOV SI,word [BP+4]
  MOV DI,word [BP+2]
  MOV AX,word [BP+6]
  MOV BX,word [BP+8]
  MOV CX,word [BP+0xa]
  MOV DX,word [BP+0xc]
  CALL o68ce
  JMP o6o4b
o5fb2:
  SHR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  INC SI
  JNZ o5fb2
  JMP o5fd9
o5fbf:
  MOV word [BP+4],DI
  CMP SI,0x40
  JL o5fd9
  MOV DI,word [BP+0x14]
  MOV DI,word [DI+6]
  XOR DI,word [BP]
  MOV SI,word [BP+4]
  CALL o68ce
  JMP o6o4b
o5fd9:
  XCHG AX,word [BP+6]
  XCHG BX,word [BP+8]
  XCHG CX,word [BP+0xa]
  XCHG DX,word [BP+0xc]
  TEST SI,SI
  JZ o5ff4
o5fe9:
  SHR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  DEC SI
  JNZ o5fe9
o5ff4:
  MOV SI,word [BP+0x14]
  MOV SI,word [SI+6]
  XOR SI,word [BP+2]
  XOR SI,word [BP]
  JS o6o1d
  ADD DX,word [BP+0xc]
  ADC CX,word [BP+0xa]
  ADC BX,word [BP+8]
  ADC AX,word [BP+6]
  JNB o6o42
  RCR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  INC word [BP+4]
  JMP o6o42
o6o1d:
  SUB DX,word [BP+0xc]
  SBB CX,word [BP+0xa]
  SBB BX,word [BP+8]
  SBB AX,word [BP+6]
  JNB o6o42
  XOR word [BP+2],0x8000
  NOT AX
  NOT BX
  NOT CX
  NEG DX
  CMC
  ADC CX,0
  ADC BX,0
  ADC AX,0
o6o42:
  MOV DI,word [BP+2]
  MOV SI,word [BP+4]
  CALL o68ce
o6o4b:
  MOV SI,word [BP+0x14]
  ADD SP,0xe
  POP DI
  POP BP
  RET 2

;----------------------------------------------------------------------------
; o6o56 — Printf-like string formatter
; C-library-style printf implementation supporting format specifiers:
;   %d (signed decimal), %u (unsigned decimal), %x (hex),
;   %o (octal), %s (string), %c (char), %f/%e/%g (float).
; Dispatch table at o6493. Output goes to buffer pointed by [BP+8].
; Used for formatting score strings and debug output.
;----------------------------------------------------------------------------
o6o56:
  PUSH BP
  SUB SP,0x10c
  MOV BP,SP
  LEA AX,word [BP+0x112]
  MOV word [BP+0xa],AX
o6o64:
  MOV SI,word [BP+0x110]
  MOV AL,byte [SI]
  XOR AH,AH
  TEST AX,AX
  JZ o6oec
  MOV BX,SI
  MOV word [BP],BX
  INC BX
  MOV AL,byte [SI]
  XOR AH,AH
  CMP AX,0x25
  MOV word [BP+4],AX
  MOV word [BP+0x110],BX
  JNZ o6oe1
  MOV AL,byte [BX]
  XOR AH,AH
  CMP AX,0x25
  JNZ o6oa2
  INC word [BP+0x110]
  MOV AL,byte [BX]
  XOR AH,AH
  PUSH AX
  MOV word [BP+4],AX
  CALL o6a3f
  MOV SP,BP
  JMP o6o64
o6oa2:
  LEA AX,word [BP+6]
  PUSH AX
  LEA AX,word [BP+0xa]
  PUSH AX
  LEA AX,word [BP+0xc]
  PUSH AX
  PUSH word [BP+0x110]
  CALL o611o
  MOV SP,BP
  TEST AX,AX
  MOV word [BP+8],AX
  JZ o6o64
  MOV word [BP+2],0
  MOV word [BP+0x110],AX
o6oc7:
  MOV AX,word [BP+2]
  CMP AX,word [BP+6]
  JGE o6o64
  MOV SI,AX
  MOV AL,byte [BP+SI+0xc]
  XOR AH,AH
  PUSH AX
  CALL o6a3f
  MOV SP,BP
  INC word [BP+2]
  JMP o6oc7
o6oe1:
  PUSH word [BP+4]
  CALL o6a3f
  MOV SP,BP
  JMP o6o64
o6oec:
  ADD SP,0x10c
  POP BP
  RET

;----------------------------------------------------------------------------
; o6of2 — 32-bit unsigned compare
; Compares DX:BX against CX:AX (unsigned). Sets flags for
; JLE/JGE/JZ conditional jumps. Used extensively for score
; comparisons and boundary checks.
;   Returns: flags set as if CMP was performed on 32-bit values
;   DX:BX = first value, CX:AX = second value (swapped from
;   what you might expect — checks if first >= second).
;----------------------------------------------------------------------------
o6of2:
  PUSH AX
  XOR AX,CX
  POP AX
  PUSH AX
  JS o61o8
  SUB AX,CX
  JNZ o61ob
  XOR AX,AX
  CMP BX,DX
  JZ o61ob
  JA o61o8
  DEC AX
  JMP o61ob
o61o8:
  OR AX,0x7fff
o61ob:
  TEST AX,AX
  POP AX
  RET

o61of:
  RET

o611o:
  PUSH BP
  SUB SP,0x36
  MOV BP,SP
  XOR AX,AX
  MOV word [BP+0x12],-1
  MOV word [BP+0x14],0x20
  MOV SI,word [BP+0x3a]
  MOV BL,byte [SI]
  XOR BH,BH
  CMP BX,0x2d
  MOV word [BP+0xc],AX
  MOV word [BP+0x16],AX
  MOV word [BP+0xe],AX
  MOV word [BP+0x10],AX
  JNZ o6143
  MOV AX,1
  INC word [BP+0x3a]
  MOV word [BP+0xc],AX
o6143:
  MOV SI,word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  MOV word [BP],AX
  INC AX
  MOV SI,AX
  MOV AL,byte [SI+p751c]
  XOR AH,AH
  AND AX,4
  JZ o61a5
  CMP word [BP],0x30
  JNZ o6166
  MOV word [BP+0x14],0x30
o6166:
  MOV SI,word [BP+0x3a]
  INC word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  AND AX,0xf
  MOV word [BP+0x16],AX
o6176:
  MOV SI,word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  INC AX
  MOV DI,AX
  MOV AL,byte [DI+p751c]
  XOR AH,AH
  AND AX,4
  JZ o61a5
  MOV AX,word [BP+0x16]
  MOV BX,0xa
  IMUL BX
  INC word [BP+0x3a]
  MOV BL,byte [SI]
  XOR BH,BH
  AND BX,0xf
  ADD AX,BX
  MOV word [BP+0x16],AX
  JMP o6176
o61a5:
  MOV SI,word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  CMP AX,0x2e
  JNZ o61e8
  INC word [BP+0x3a]
  MOV word [BP+0x12],0
o61b9:
  MOV SI,word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  INC AX
  MOV DI,AX
  MOV AL,byte [DI+p751c]
  XOR AH,AH
  AND AX,4
  JZ o61e8
  MOV AX,word [BP+0x12]
  MOV BX,0xa
  IMUL BX
  INC word [BP+0x3a]
  MOV BL,byte [SI]
  XOR BH,BH
  AND BX,0xf
  ADD AX,BX
  MOV word [BP+0x12],AX
  JMP o61b9
o61e8:
  MOV SI,word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  CMP AX,0x6c
  JNZ o61fd
  MOV AX,1
  INC word [BP+0x3a]
  MOV word [BP+0xe],AX
o61fd:
  MOV word [BP+0x1c],0
  MOV SI,word [BP+0x3a]
  MOV AL,byte [SI]
  XOR AH,AH
  JMP o64b7
o62oc:
  CMP word [BP+0xe],0
  JZ o6229
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],4
  MOV SI,AX
  MOV BX,word [SI+2]
  MOV CX,word [SI]
  MOV word [BP+0x1e],CX
  MOV word [BP+0x20],BX
  JMP o6242
o6229:
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],2
  MOV SI,AX
  MOV BX,word [SI]
  XOR CX,CX
  TEST BX,BX
  JNS o623c
  DEC CX
o623c:
  MOV word [BP+0x20],CX
  MOV word [BP+0x1e],BX
o6242:
  MOV AX,word [BP+0x20]
  TEST AX,AX
  JNS o628b
  NOT word [BP+0x20]
  NEG word [BP+0x1e]
  SBB word [BP+0x20],-1
  MOV word [BP+0x10],1
  JMP o628b
o625a:
  CMP word [BP+0xe],0
  JZ o6277
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],4
  MOV SI,AX
  MOV BX,word [SI+2]
  MOV CX,word [SI]
  MOV word [BP+0x1e],CX
  MOV word [BP+0x20],BX
  JMP o628b
o6277:
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],2
  MOV SI,AX
  MOV BX,word [SI]
  XOR AX,AX
  MOV word [BP+0x20],AX
  MOV word [BP+0x1e],BX
o628b:
  MOV word [BP+6],0xb
o629o:
  MOV AX,word [BP+6]
  DEC AX
  MOV SI,AX
  MOV word [BP+6],AX
  MOV AX,word [BP+0x20]
  MOV BX,word [BP+0x1e]
  XOR CX,CX
  MOV DX,0xa
  MOV word [BP],SI
  CALL o5afb
  ADD DX,0x30
  ADC CX,0
  MOV SI,word [BP]
  MOV byte [BP+SI+0x22],DL
  MOV AX,word [BP+0x20]
  MOV BX,word [BP+0x1e]
  XOR CX,CX
  MOV DX,0xa
  CALL o5afb
  MOV word [BP+0x20],AX
  MOV word [BP+0x1e],BX
  MOV AX,word [BP+0x20]
  OR AX,word [BP+0x1e]
  JNZ o629o
  CMP word [BP+0x10],1
  JNZ o62e5
  MOV AX,word [BP+6]
  DEC AX
  MOV SI,AX
  MOV byte [BP+SI+0x22],0x2d
  MOV word [BP+6],AX
o62e5:
  LEA AX,word [BP+0x22]
  MOV BX,word [BP+6]
  ADD BX,AX
  MOV AX,0xb
  SUB AX,word [BP+6]
  MOV word [BP+0xa],AX
  MOV word [BP+0x1c],BX
  JMP o64cd
o62fc:
  CMP word [BP+0xe],0
  JZ o6319
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],4
  MOV SI,AX
  MOV BX,word [SI+2]
  MOV CX,word [SI]
  MOV word [BP+0x1e],CX
  MOV word [BP+0x20],BX
  JMP o632d
o6319:
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],2
  MOV SI,AX
  MOV BX,word [SI]
  XOR AX,AX
  MOV word [BP+0x20],AX
  MOV word [BP+0x1e],BX
o632d:
  MOV word [BP+6],8
o6332:
  MOV AX,word [BP+6]
  DEC AX
  MOV SI,AX
  MOV BX,word [BP+0x20]
  MOV CX,word [BP+0x1e]
  XOR BX,BX
  AND CX,0xf
  MOV BX,CX
  MOV CL,byte [BX+p761e]
  MOV byte [BP+SI+0x22],CL
  MOV CX,4
  MOV BX,word [BP+0x20]
  MOV DX,word [BP+0x1e]
  JCXZ o635e
o6358:
  SAR BX,1
  RCR DX,1
  LOOP o6358
o635e:
  MOV word [BP+0x20],BX
  AND BX,0xfff
  MOV word [BP+6],AX
  MOV word [BP+0x1e],DX
  MOV word [BP+0x20],BX
  MOV AX,word [BP+0x20]
  OR AX,word [BP+0x1e]
  JNZ o6332
  LEA AX,word [BP+0x22]
  MOV BX,word [BP+6]
  ADD BX,AX
  MOV AX,8
  SUB AX,word [BP+6]
  MOV word [BP+0xa],AX
  MOV word [BP+0x1c],BX
  JMP o64cd
o638d:
  CMP word [BP+0xe],0
  JZ o63aa
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],4
  MOV SI,AX
  MOV BX,word [SI+2]
  MOV CX,word [SI]
  MOV word [BP+0x1e],CX
  MOV word [BP+0x20],BX
  JMP o63be
o63aa:
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],2
  MOV SI,AX
  MOV BX,word [SI]
  XOR AX,AX
  MOV word [BP+0x20],AX
  MOV word [BP+0x1e],BX
o63be:
  MOV word [BP+6],0xb
o63c3:
  MOV AX,word [BP+6]
  DEC AX
  MOV SI,AX
  MOV BX,word [BP+0x20]
  MOV CX,word [BP+0x1e]
  XOR BX,BX
  AND CX,7
  ADD CX,0x30
  ADC BX,0
  MOV byte [BP+SI+0x22],CL
  MOV CX,3
  MOV BX,word [BP+0x20]
  MOV DX,word [BP+0x1e]
  JCXZ o63ef
o63e9:
  SAR BX,1
  RCR DX,1
  LOOP o63e9
o63ef:
  MOV word [BP+0x20],BX
  AND BX,0x1fff
  MOV word [BP+6],AX
  MOV word [BP+0x1e],DX
  MOV word [BP+0x20],BX
  MOV AX,word [BP+0x20]
  OR AX,word [BP+0x1e]
  JNZ o63c3
  LEA AX,word [BP+0x22]
  MOV BX,word [BP+6]
  ADD BX,AX
  MOV AX,0xb
  SUB AX,word [BP+6]
  MOV word [BP+0xa],AX
  MOV word [BP+0x1c],BX
  JMP o64cd
o641e:
  CMP word [BP+0x12],-1
  JNZ o6429
  MOV word [BP+0x12],0xc8
o6429:
  MOV word [BP+0xa],0
o642e:
  MOV AX,word [BP+0xa]
  CMP AX,word [BP+0x12]
  JGE o644c
  MOV DI,word [BP+0x3e]
  MOV SI,word [DI]
  MOV DI,word [SI]
  ADD DI,AX
  MOV AL,byte [DI]
  XOR AH,AH
  TEST AX,AX
  JZ o644c
  INC word [BP+0xa]
  JMP o642e
o644c:
  MOV SI,word [BP+0x3e]
  MOV AX,word [SI]
  ADD word [SI],2
  MOV SI,AX
  MOV BX,word [SI]
  MOV word [BP+0x1c],BX
  JMP o64cd
o645d:
  LEA AX,word [BP+0x22]
  MOV word [BP+0xa],1
  MOV SI,word [BP+0x3e]
  MOV BX,word [SI]
  ADD word [SI],2
  MOV CX,word [BX]
  MOV word [BP+0x1c],AX
  MOV byte [BP+0x22],CL
  JMP o64cd
o6477:
  MOV word [BP+0x1a],2
  JMP o64cd
o647e:
  MOV word [BP+0x1a],0
  JMP o64cd
o6485:
  MOV word [BP+0x1a],1
  JMP o64cd
o648c:
  XOR AX,AX
  ADD SP,0x36
  POP BP
  RET

o6493:
  DW 0x66,o6485
  DW 0x65,o647e
  DW 0x67,o6477
  DW 0x63,o645d
  DW 0x73,o641e
  DW 0x6f,o638d
  DW 0x78,o62fc
  DW 0x75,o625a
  DW 0x64,o62oc

o64b7:
  MOV SI,0x20
o64ba:
  CMP AX,word [cs:SI+o6493]
  JNZ o64c6
  JMP word [cs:SI+o6493+2]
o64c6:
  SUB SI,4
  JNS o64ba
  JMP o648c
o64cd:
  CMP word [BP+0x1c],0
  JNZ o64d6
  JMP o6588
o64d6:
  MOV AX,word [BP+0x16]
  TEST AX,AX
  JZ o64e2
  CMP AX,word [BP+0xa]
  JGE o64e8
o64e2:
  MOV AX,word [BP+0xa]
  MOV word [BP+0x16],AX
o64e8:
  MOV AX,word [BP+0xa]
  SUB word [BP+0x16],AX
  MOV word [BP+6],0
  CMP word [BP+0xc],0
  JZ o6538
o64f9:
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o651b
  MOV AX,word [BP+6]
  INC word [BP+6]
  MOV SI,word [BP+0x3c]
  ADD SI,AX
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o64f9
o651b:
  MOV AX,word [BP+0x16]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x16],AX
  JS o6577
  MOV AX,word [BP+6]
  INC word [BP+6]
  MOV SI,word [BP+0x3c]
  ADD SI,AX
  MOV AX,word [BP+0x14]
  MOV byte [SI],AL
  JMP o651b
o6538:
  MOV AX,word [BP+0x16]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x16],AX
  JS o6555
  MOV AX,word [BP+6]
  INC word [BP+6]
  MOV SI,word [BP+0x3c]
  ADD SI,AX
  MOV AX,word [BP+0x14]
  MOV byte [SI],AL
  JMP o6538
o6555:
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o6577
  MOV AX,word [BP+6]
  INC word [BP+6]
  MOV SI,word [BP+0x3c]
  ADD SI,AX
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o6555
o6577:
  MOV AX,word [BP+6]
  MOV SI,word [BP+0x40]
  MOV word [SI],AX
  MOV AX,word [BP+0x3a]
  INC AX
  ADD SP,0x36
  POP BP
  RET
o6588:
  CMP word [BP+0x12],-1
  JNZ o6593
  MOV word [BP+0x12],6
o6593:
  CMP word [BP+0x12],0x14
  JLE o659e
  MOV word [BP+0x12],0x14
o659e:
  MOV AX,word [BP+0x12]
  INC AX
  LEA BX,word [BP+0x22]
  PUSH BX
  LEA BX,word [BP+0x10]
  PUSH BX
  LEA BX,word [BP+0x18]
  PUSH BX
  PUSH word [BP+0x1a]
  PUSH AX
  MOV BX,word [BP+0x3e]
  PUSH word [BX]
  CALL o6bd3
  MOV SP,BP
  MOV SI,word [BP+0x3e]
  ADD word [SI],8
  LEA BX,word [BP+0x22]
  MOV CX,word [BP+0x18]
  TEST CX,CX
  MOV word [BP+0xa],AX
  MOV word [BP+6],CX
  MOV word [BP+0x1c],BX
  JNS o65d8
  NEG word [BP+6]
o65d8:
  CMP word [BP+0x1a],2
  JNZ o65ef
  CMP word [BP+0xa],0
  JZ o65ea
  CMP word [BP+6],6
  JGE o65ef
o65ea:
  MOV word [BP+0x1a],0
o65ef:
  CMP word [BP+0xa],0
  JZ o65f8
  DEC word [BP+0x18]
o65f8:
  XOR AX,AX
  MOV word [BP+6],AX
  CMP word [BP+0x10],0
  JZ o66o6
  INC word [BP+6]
o66o6:
  CMP word [BP+0x1a],0
  JZ o662d
  MOV AX,word [BP+0x12]
  INC AX
  MOV BX,word [BP+6]
  ADD BX,AX
  MOV AX,word [BP+0x18]
  TEST AX,AX
  MOV word [BP+6],BX
  JS o6622
  ADD word [BP+6],AX
o6622:
  CMP word [BP+0x12],0
  JZ o6659
  INC word [BP+6]
  JMP o6659
o662d:
  MOV AX,word [BP+0x12]
  ADD AX,6
  ADD word [BP+6],AX
  MOV AX,word [BP+0x18]
  TEST AX,AX
  JNS o6641
  NEG AX
  JMP o6644
o6641:
  MOV AX,word [BP+0x18]
o6644:
  CMP AX,0x63
  MOV word [BP+8],AX
  JLE o664f
  INC word [BP+6]
o664f:
  CMP word [BP+8],0x3e7
  JLE o6659
  INC word [BP+6]
o6659:
  CMP word [BP+0xc],0
  JNZ o6688
  MOV AX,word [BP+0x16]
  CMP AX,word [BP+6]
  JLE o6688
  MOV BX,word [BP+6]
  SUB word [BP+0x16],BX
o666d:
  MOV AX,word [BP+0x16]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x16],AX
  JS o6688
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV AX,word [BP+0x14]
  MOV byte [SI],AL
  INC word [BP+6]
  JMP o666d
o6688:
  CMP word [BP+0x10],0
  JZ o6697
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x2d
o6697:
  CMP word [BP+0x1a],0
  JNZ o66ao
  JMP o6782
o66ao:
  MOV AX,word [BP+0x18]
  TEST AX,AX
  JNS o67ob
  MOV SI,word [BP+0x3c]
  MOV AX,SI
  MOV word [BP],AX
  INC AX
  MOV byte [SI],0x30
  MOV SI,AX
  MOV word [BP+0x3c],AX
  INC AX
  MOV byte [SI],0x2e
  MOV word [BP+0x3c],AX
o66bf:
  MOV AX,word [BP+0x12]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x12],AX
  JNS o66cd
  JMP o685c
o66cd:
  MOV AX,word [BP+0x18]
  INC AX
  TEST AX,AX
  MOV word [BP+0x18],AX
  JNS o66e3
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x30
  JMP o66bf
o66e3:
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o67oo
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o66bf
o67oo:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x30
  JMP o66bf
o67ob:
  MOV AX,word [BP+0x18]
  DEC word [BP+0x18]
  TEST AX,AX
  JS o673d
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o6732
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o67ob
o6732:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x30
  JMP o67ob
o673d:
  CMP word [BP+0x12],0
  JZ o674c
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x2e
o674c:
  MOV AX,word [BP+0x12]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x12],AX
  JNS o675a
  JMP o685c
o675a:
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o6777
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o674c
o6777:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x30
  JMP o674c
o6782:
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o679f
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o67a8
o679f:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x30
o67a8:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x2e
o67b1:
  MOV AX,word [BP+0x12]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x12],AX
  JS o67e4
  MOV AX,word [BP+0xa]
  DEC AX
  TEST AX,AX
  MOV word [BP+0xa],AX
  JS o67d9
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV DI,word [BP+0x1c]
  INC word [BP+0x1c]
  MOV AL,byte [DI]
  MOV byte [SI],AL
  JMP o67b1
o67d9:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x30
  JMP o67b1
o67e4:
  MOV SI,word [BP+0x3c]
  MOV AX,SI
  MOV word [BP],AX
  INC AX
  MOV byte [SI],0x45
  MOV BX,word [BP+0x18]
  TEST BX,BX
  MOV word [BP+0x3c],AX
  JNS o68o7
  MOV SI,AX
  INC word [BP+0x3c]
  MOV byte [SI],0x2d
  NEG word [BP+0x18]
  JMP o681o
o68o7:
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV byte [SI],0x2b
o681o:
  MOV word [BP+0xa],0xb
o6815:
  MOV AX,word [BP+0xa]
  DEC AX
  MOV SI,AX
  MOV word [BP+0xa],AX
  MOV AX,word [BP+0x18]
  MOV BX,0xa
  CWD
  IDIV BX
  ADD DX,0x30
  MOV byte [BP+SI+0x22],DL
  MOV AX,word [BP+0x18]
  CWD
  IDIV BX
  MOV word [BP+0x18],AX
  CMP word [BP+0xa],9
  JG o6815
  CMP word [BP+0x18],0
  JNZ o6815
o6842:
  MOV AX,word [BP+0xa]
  CMP AX,0xb
  JGE o685c
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  INC word [BP+0xa]
  MOV DI,AX
  MOV AL,byte [BP+DI+0x22]
  MOV byte [SI],AL
  JMP o6842
o685c:
  CMP word [BP+0xc],1
  JNZ o688b
  MOV AX,word [BP+0x16]
  CMP AX,word [BP+6]
  JLE o688b
  MOV BX,word [BP+6]
  SUB word [BP+0x16],BX
o687o:
  MOV AX,word [BP+0x16]
  DEC AX
  TEST AX,AX
  MOV word [BP+0x16],AX
  JS o688b
  MOV SI,word [BP+0x3c]
  INC word [BP+0x3c]
  MOV AX,word [BP+0x14]
  MOV byte [SI],AL
  INC word [BP+6]
  JMP o687o
o688b:
  MOV AX,word [BP+6]
  MOV SI,word [BP+0x40]
  MOV word [SI],AX
  MOV AX,word [BP+0x3a]
  INC AX
  ADD SP,0x36
  POP BP
  RET

;----------------------------------------------------------------------------
; o689c — Floating-point normalize
; Normalizes a floating-point value by shifting mantissa left until
; the high bit is set, adjusting the exponent accordingly.
; Used after FP arithmetic operations.
;----------------------------------------------------------------------------
o689c:
  PUSH CX
  MOV SI,AX
  AND SI,0x7ff0
  SHR SI,4
  SUB SI,0x3ff
  POP CX
  MOV AH,AL
  MOV AL,BH
  MOV BH,BL
  MOV BL,CH
  MOV CH,CL
  MOV CL,DH
  MOV DH,DL
  XOR DL,DL
  MOV DI,3
o68bf:
  SHL DX,1
  RCL CX,1
  RCL BX,1
  RCL AX,1
  DEC DI
  JNZ o68bf
  OR AX,0x8000
  RET

;----------------------------------------------------------------------------
; o68ce — Floating-point denormalize
; Denormalizes a floating-point value by shifting mantissa right
; and incrementing the exponent. Inverse of o689c.
;----------------------------------------------------------------------------
o68ce:
  AND DI,0x8000
  PUSH DI
  SUB SI,0xb
  TEST AX,AX
  JNZ o69o9
  SUB SI,0x10
  MOV AX,BX
  TEST AX,AX
  JNZ o69o3
  SUB SI,0x10
  MOV AX,CX
  TEST AX,AX
  JNZ o68fb
  SUB SI,0x10
  MOV AX,DX
  TEST AX,AX
  JNZ o68f7
  POP DI
  RET
o68f7:
  XOR DX,DX
  JMP o69o9
o68fb:
  MOV BX,DX
  XOR CX,CX
  XOR DX,DX
  JMP o69o9
o69o3:
  MOV BX,CX
  MOV CX,DX
  XOR DX,DX
o69o9:
  TEST AX,0xffe0
  JZ o6939
o69oe:
  INC SI
  SHR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  RCR DI,1
  TEST AX,0xffe0
  JNZ o69oe
  TEST DI,DI
  JNS o6939
  ADD DX,1
  ADC CX,0
  ADC BX,0
  ADC AX,0
  JMP o69o9
o693o:
  DEC SI
  SHL DX,1
  RCL CX,1
  RCL BX,1
  RCL AX,1
o6939:
  TEST AX,0x10
  JZ o693o
  POP DI
  ADD SI,0x3ff
  JLE o6959
  CMP SI,0x7ff
  JGE o6965
  PUSH CX
  AND AX,0xf
  SHL SI,4
  OR SI,DI
  OR AX,SI
  POP CX
  RET
o6959:
  MOV AX,1
  PUSH AX
  CALL o61of
  POP AX
  XOR AX,AX
  JMP o6972
o6965:
  MOV AX,2
  PUSH AX
  CALL o61of
  POP AX
  MOV AX,0x7ff0
  OR AX,DI
o6972:
  XOR BX,BX
  XOR CX,CX
  XOR DX,DX
  RET

o6a3f:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,word [BP+6]
  AND AX,0x7f
  PUSH AX
  MOV AX,6
  PUSH AX
  CALL o6b15
  MOV SP,BP
  MOV AX,word [BP+6]
  ADD SP,2
  POP BP
  RET

o6b15:
  PUSH BP
  MOV BP,SP
  MOV AX,word [BP+4]
  MOV AH,AL
  MOV DX,word [BP+6]
  INT 0x21
  XOR AH,AH
  POP BP
  RET

o6b26:
  MOV SI,0x40
  XOR AX,AX
  MOV BX,word [BP+4]
  MOV CX,word [BP+6]
  MOV DX,word [BP+8]
  MOV DI,word [BP+0xa]
o6b37:
  SHL DI,1
  RCL DX,1
  RCL CX,1
  RCL BX,1
  RCL AX,1
  CMP AX,0xa
  JB o6b4a
  SUB AX,0xa
  INC DI
o6b4a:
  DEC SI
  JNZ o6b37
  MOV word [BP+4],BX
  MOV word [BP+6],CX
  MOV word [BP+8],DX
  MOV word [BP+0xa],DI
  RET

o6b5a:
  MOV AX,word [BP+0xa]
  SHL AX,1
  MOV word [BP+0xa],AX
  MOV AX,word [BP+8]
  RCL AX,1
  MOV word [BP+8],AX
  MOV AX,word [BP+6]
  RCL AX,1
  MOV word [BP+6],AX
  MOV AX,word [BP+4]
  RCL AX,1
  MOV word [BP+4],AX
  RET

o6b7b:
  MOV BX,AX
  XOR CX,CX
  SHL AX,1
  RCL CX,1
  SHL AX,1
  RCL CX,1
  ADD AX,BX
  ADC CX,0
  SHL AX,1
  RCL CX,1
  RET

o6b91:
  XOR CX,CX
  MOV DI,6
o6b96:
  MOV AX,word [BP+DI+4]
  MOV word [BP+DI+4],CX
  CALL o6b7b
  MOV BX,word [BP+DI+4]
  ADD AX,BX
  ADC CX,0
  MOV word [BP+DI+4],AX
  DEC DI
  DEC DI
  JNS o6b96
  RET

o6baf:
  MOV AX,word [BP+4]
  MOV BX,word [BP+6]
  MOV CX,word [BP+8]
  MOV DX,word [BP+0xa]
o6bbb:
  SHR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  DEC SI
  JNZ o6bbb
  MOV word [BP+4],AX
  MOV word [BP+6],BX
  MOV word [BP+8],CX
  MOV word [BP+0xa],DX
  RET

o6bd3:
  PUSH BP
  SUB SP,0x28
  MOV BP,SP
  MOV word [BP],0
  MOV word [BP+0xc],0
  MOV SI,word [BP+0x2c]
  MOV AX,word [SI+6]
  TEST AX,AX
  JNS o6bf2
  OR word [BP],0x8000
o6bf2:
  AND AX,0x7fff
  JNZ o6co7
  MOV DI,AX
  OR DI,word [SI+4]
  JNZ o6co7
  OR DI,word [SI+2]
  JNZ o6co7
  OR DI,word [SI]
  JZ o6c83
o6co7:
  SHR AX,4
  SUB AX,0x3fe
  MOV word [BP+0xe],AX
  MOV CX,word [SI]
  MOV BX,word [SI+2]
  MOV AX,word [SI+4]
  MOV SI,word [SI+6]
  XOR DX,DX
  MOV DI,5
o6c21:
  SHR SI,1
  RCR AX,1
  RCR BX,1
  RCR CX,1
  RCR DX,1
  DEC DI
  JNZ o6c21
  OR AX,0x8000
  MOV word [BP+4],AX
  MOV word [BP+6],BX
  MOV word [BP+8],CX
  MOV word [BP+0xa],DX
  MOV word [BP+0xc],0
o6c42:
  MOV SI,word [BP+0xe]
  MOV CX,SI
  TEST SI,SI
  JZ o6cb4
  JNS o6c5d
  ADD SI,3
  JS o6c65
  MOV SI,1
  CALL o6baf
  INC word [BP+0xe]
  JMP o6c42
o6c5d:
  CALL o6b26
  INC word [BP+0xc]
  JMP o6c74
o6c65:
  MOV SI,4
  ADD word [BP+0xe],SI
  CALL o6baf
  CALL o6b91
  DEC word [BP+0xc]
o6c74:
  TEST word [BP+4],0x8000
  JNZ o6c42
  DEC word [BP+0xe]
  CALL o6b5a
  JMP o6c74
o6c83:
  XOR SI,SI
  OR word [BP],0x4000
o6c8a:
  XOR CX,CX
  TEST word [BP],0x4000
  JNZ o6cb4
  MOV AX,word [BP+4]
  OR AX,word [BP+6]
  JNZ o6ca3
  MOV AX,word [BP+8]
  OR AX,word [BP+0xa]
  JZ o6cb4
o6ca3:
  CALL o6b91
  TEST CX,CX
  JNZ o6cb4
  CMP SI,1
  JNZ o6cb4
  DEC word [BP+0xc]
  JMP o6ca3
o6cb4:
  ADD CL,0x30
  MOV byte [BP+SI+0x14],CL
  INC SI
  CMP SI,0x14
  JL o6c8a
  MOV word [BP+0x10],1
  MOV AX,word [BP+0x30]
  MOV SI,word [BP+0x2e]
  TEST AX,AX
  JZ o6cda
  MOV CX,1
  MOV AX,word [BP+0xc]
  DEC AX
  ADD SI,AX
  JS o6do7
o6cda:
  MOV CX,0x14
  CMP SI,0x12
  JGE o6do7
  MOV CX,SI
  MOV AL,byte [BP+SI+0x15]
  ADD AL,5
o6ce9:
  CMP AL,0x3a
  JL o6do7
  MOV byte [BP+SI+0x15],0x30
  INC byte [BP+SI+0x14]
  MOV AL,byte [BP+SI+0x14]
  DEC SI
  JNS o6ce9
  INC word [BP+0xc]
  DEC word [BP+0x10]
  CMP word [BP+0x30],0
  JZ o6do7
  INC CX
o6do7:
  MOV DI,word [BP+0x36]
  MOV SI,word [BP+0x10]
  XOR BX,BX
o6dof:
  MOV AL,byte [BP+SI+0x14]
  MOV byte [DI],AL
  INC BX
  INC DI
  CMP BX,CX
  JGE o6d2b
  INC SI
  CMP SI,0x14
  JL o6dof
  MOV AL,0x30
o6d22:
  MOV byte [DI],AL
  INC DI
  INC BX
  CMP BX,word [BP+0x2e]
  JL o6d22
o6d2b:
  XOR AX,AX
  TEST word [BP],0x8000
  JZ o6d3c
  TEST word [BP],0x4000
  JNZ o6d3c
  DEC AX
o6d3c:
  MOV SI,word [BP+0x34]
  MOV word [SI],AX
  MOV AX,word [BP+0xc]
  MOV SI,word [BP+0x32]
  MOV word [SI],AX
  TEST word [BP],0x4000
  JZ o6d52
  XOR CX,CX
o6d52:
  MOV AX,CX
  ADD SP,0x28
  POP BP
  RET

  DB "Copyright(c) 1983 Windmill Software Inc."

;============================================================================
; BMP Background Image Loader
; Loads STYX.BMP (320x200 or 160x200, 4-bit uncompressed) and decodes it
; into bmp_background buffer in CGA-interlaced layout for background reveal.
; If the file is missing or invalid, bmp_loaded stays 0 and the game
; continues with normal solid-color territory display.
;============================================================================
;============================================================================
; load_level_bmp — Load level-specific BMP background
; Constructs filename "STYXn.BMP" (n = current level digit 1-9)
; from p74d4, then calls load_bmp_background.
; If the file doesn't exist, bmp_loaded will be 0 and the game
; falls back to the standard color method.
;============================================================================
load_level_bmp:
  CMP byte [no_images],0
  JNZ .no_img
  MOV AX,[p74d4]         ;Get current level (1-9)
  ADD AL,'0'             ;Convert to ASCII digit
  MOV [bmp_filename+4],AL ;Patch filename: "STYXn.BMP"
  CALL load_bmp_background
  RET
.no_img:
  MOV byte [bmp_loaded],0
  RET

;============================================================================
; load_bmp_background — BMP Background Image Loader
; Loads the BMP file named by bmp_filename as the background image
; that is revealed when territory is claimed.
;
; Supports: 4-bit uncompressed BMP, 160×200 or 320×200 resolution.
; For 320-wide BMPs, downsamples to 160 by skipping every other pixel.
;
; Process:
;   1. Opens bmp_filename ("STYXn.BMP") via DOS INT 21h
;   2. Reads 118-byte BMP header into bmp_hdr
;   3. Validates: must be 4-bit, uncompressed (BI_RGB)
;   4. Converts BGRA palette to V6355D format (convert_bmp_palette)
;   5. Reads rows bottom-up (BMP format) into CGA-interlaced layout:
;      - Even rows → bmp_background[y/2 * 80]
;      - Odd rows  → bmp_background[0x2000 + y/2 * 80]
;   6. For 320-wide: reads full row into bmp_row_buf, copies every
;      other nibble to produce 80-byte output row
;   7. Sets bmp_loaded = 1 on success
;
; The bmp_background buffer (16000 bytes) mirrors the VRAM layout
; so pixels can be directly substituted during screen refresh.
;============================================================================
load_bmp_background:
  PUSH BP
  MOV BP,SP
  PUSH SI
  PUSH DI

  MOV byte [bmp_loaded],0

  ; Open STYX.BMP (read-only)
  MOV DX,bmp_filename
  MOV AX,0x3D00
  INT 0x21
  JC .bmp_fail
  MOV word [bmp_file_handle],AX

  ; Read 118 bytes: file header (14) + info header (40) + palette (64)
  MOV BX,AX
  MOV DX,bmp_hdr
  MOV CX,118
  MOV AH,0x3F
  INT 0x21
  JC .bmp_close
  CMP AX,118
  JB .bmp_close

  ; Validate BMP signature 'BM'
  CMP word [bmp_hdr],0x4D42
  JNE .bmp_close

  ; Must be 4-bit uncompressed
  CMP word [bmp_hdr+28],4
  JNE .bmp_close
  CMP word [bmp_hdr+30],0
  JNE .bmp_close

  ; Seek to pixel data offset
  MOV BX,word [bmp_file_handle]
  MOV DX,word [bmp_hdr+10]
  MOV CX,word [bmp_hdr+12]
  MOV AX,0x4200
  INT 0x21
  JC .bmp_close

  ; Determine width and downsampling
  MOV AX,word [bmp_hdr+18]
  MOV word [bmp_img_width],AX
  MOV byte [bmp_downsample],0
  CMP AX,160
  JBE .bmp_wok
  MOV byte [bmp_downsample],1
.bmp_wok:

  ; Get height (use absolute value)
  MOV AX,word [bmp_hdr+22]
  TEST AX,AX
  JNS .bmp_hpos
  NEG AX
.bmp_hpos:
  CMP AX,200
  JBE .bmp_hok
  MOV AX,200
.bmp_hok:
  MOV word [bmp_img_height],AX

  ; Calculate bytes per row in BMP file (with 4-byte padding)
  MOV AX,word [bmp_img_width]
  INC AX
  SHR AX,1
  ADD AX,3
  AND AX,0xFFFC
  MOV word [bmp_bytes_per_row],AX

  ; Convert BMP palette to V6355 format
  CALL convert_bmp_palette

  ; Decode pixel data: BMP is bottom-up, decode to CGA-interlaced layout
  MOV AX,word [bmp_img_height]
  DEC AX
  MOV word [bmp_cur_row],AX

.bmp_rowloop:
  ; Read one BMP row
  MOV BX,word [bmp_file_handle]
  MOV DX,bmp_row_buf
  MOV CX,word [bmp_bytes_per_row]
  MOV AH,0x3F
  INT 0x21
  JC .bmp_decodedone
  OR AX,AX
  JZ .bmp_decodedone

  ; Calculate destination offset in bmp_background
  ; Even rows: (row/2)*80          Odd rows: (row/2)*80 + 8000
  MOV AX,word [bmp_cur_row]
  PUSH AX
  SHR AX,1
  MOV BX,80
  MUL BX
  MOV DI,AX
  POP AX
  TEST AL,1
  JZ .bmp_iseven
  ADD DI,8000
.bmp_iseven:
  ADD DI,bmp_background

  ; Downsample or direct copy
  CMP byte [bmp_downsample],0
  JE .bmp_directcopy

  ; --- Downsample 320 -> 160 ---
  ; Take pixels 0,2 from each pair of input bytes
  MOV SI,bmp_row_buf
  MOV CX,80
.bmp_dsloop:
  LODSB
  AND AL,0xF0
  MOV AH,AL
  LODSB
  SHR AL,4
  OR AL,AH
  MOV byte [DI],AL
  INC DI
  LOOP .bmp_dsloop
  JMP .bmp_rowdone

.bmp_directcopy:
  MOV SI,bmp_row_buf
  MOV CX,80
.bmp_cploop:
  LODSB
  MOV byte [DI],AL
  INC DI
  LOOP .bmp_cploop

.bmp_rowdone:
  MOV AX,word [bmp_cur_row]
  OR AX,AX
  JZ .bmp_decodedone
  DEC AX
  MOV word [bmp_cur_row],AX
  JMP .bmp_rowloop

.bmp_decodedone:
  ; Rearrange palette so game-critical indices get proper colors,
  ; then remap background pixels to match the new index assignments.
  CALL rearrange_palette_for_game
  MOV byte [bmp_loaded],1

.bmp_close:
  MOV BX,word [bmp_file_handle]
  OR BX,BX
  JZ .bmp_fail
  MOV AH,0x3E
  INT 0x21

.bmp_fail:
  POP DI
  POP SI
  POP BP
  RET

;============================================================================
; Convert BMP BGRA palette (at bmp_hdr+54) to V6355 format (bmp_palette)
;
; V6355 palette format: 2 bytes per color
;   Byte 1: Red (bits 0-2, range 0-7)
;   Byte 2: Green (bits 4-6) | Blue (bits 0-2)
;
; All 16 BMP colors are loaded as-is.  After loading, the separate
; rearrange_palette_for_game routine swaps entries so that the
; game's hardcoded color indices (0,7,12,15) get visually
; appropriate colors chosen by brightness analysis.
;============================================================================
;----------------------------------------------------------------------------
; convert_bmp_palette — BMP BGRA to V6355D palette format
; Converts 16-color BMP palette (4 bytes per entry: B,G,R,A) stored
; in bmp_hdr+54 to the V6355D 2-byte format in bmp_palette.
;   Byte 0: Red   = (R >> 5) & 7    (3-bit, port DEh byte 1)
;   Byte 1: Green = ((G >> 5) & 7) << 4  |  Blue = (B >> 5) & 7
;           (port DEh byte 2: bits 4-6=green, bits 0-2=blue)
;----------------------------------------------------------------------------
convert_bmp_palette:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH SI
  PUSH DI

  MOV SI,bmp_hdr+54
  MOV DI,bmp_palette
  MOV CX,16

.cvt_loop:
  LODSB
  MOV BL,AL
  LODSB
  MOV BH,AL
  LODSB
  SHR AL,5
  MOV byte [DI],AL
  INC DI
  MOV AL,BH
  AND AL,0xE0
  SHR AL,1
  MOV AH,AL
  MOV AL,BL
  SHR AL,5
  OR AL,AH
  MOV byte [DI],AL
  INC DI
  LODSB
  LOOP .cvt_loop

  ; BMP palette loaded as-is — rearrange_palette_for_game will
  ; swap entries to put appropriate colors at game-critical indices.

  POP DI
  POP SI
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; Set V6355 palette from BMP data (bmp_palette, 32 bytes)
;============================================================================
;----------------------------------------------------------------------------
; set_bmp_game_palette — Apply BMP palette for gameplay
; Called after BMP loading to set up the palette.
; Rearranges the BMP palette so game-critical color indices
; get appropriate brightness levels (via rearrange_palette_for_game),
; then programs the V6355D palette registers from bmp_palette.
; Outputs 32 bytes to port DEh (16 colors × 2 bytes each),
; bracketed by port DDh control: 40h=open, 80h=close.
;----------------------------------------------------------------------------
set_bmp_game_palette:
  PUSH AX
  PUSH CX
  PUSH SI

  CLI
  MOV AL,0x40
  OUT 0xDD,AL
  JMP SHORT $+2

  MOV SI,bmp_palette
  MOV CX,32
.bmp_pal_write:
  LODSB
  OUT 0xDE,AL
  JMP SHORT $+2
  LOOP .bmp_pal_write

  MOV AL,0x80
  OUT 0xDD,AL
  STI

  POP SI
  POP CX
  POP AX
  RET

;============================================================================
; rearrange_palette_for_game
; Analyzes brightness of all 16 BMP palette entries and rearranges them
; so that the game's hardcoded color indices get visually appropriate colors:
;   Index 0  = darkest   (game background / empty area)
;   Index 15 = brightest  (text / UI)
;   Index 7  = 2nd bright (border lines / unclaimed area)
;   Index 12 = 3rd bright (ball trails)
; All 16 original BMP colors are preserved by swapping indices.
; After palette rearrangement, remaps all pixel data in bmp_background.
; Brightness = R + G + B  (each 0-7, total range 0-21)
;============================================================================
;============================================================================
; rearrange_palette_for_game — Brightness-based palette rearrangement
; Ensures game-critical color indices have appropriate brightness:
;   Index 0  ← darkest color  (background)
;   Index 15 ← brightest color (text, player)
;   Index 7  ← 2nd brightest  (border)
;   Index 12 ← 3rd brightest  (trail/path)
;
; Algorithm:
;   1. Calculate brightness for each of 16 colors: R + G + B
;      (from bmp_palette, where R=byte0, G=byte1>>4, B=byte1&7)
;   2. Find darkest → swap with index 0 in bmp_palette
;   3. Find brightest → swap with index 15
;   4. Find 2nd brightest → swap with index 7
;   5. Find 3rd brightest → swap with index 12
;   6. Build pal_remap[old_index] = new_index table
;   7. Build pal_inv_remap[new_index] = old_index (inverse)
;   8. Remap all 16000 bytes of bmp_background using pal_inv_remap
;      (each byte = 2 pixels × 4 bits, both nibbles remapped)
;
; This ensures the BMP image looks correct while the game
; can use its hardcoded color indices for gameplay elements.
;============================================================================
rearrange_palette_for_game:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI

  ; --- Step 1: compute brightness for each palette entry ---
  ;     and initialize identity remap: pal_remap[i] = i
  XOR BX,BX
.pal_calc:
  MOV byte [pal_remap+BX],BL
  MOV SI,BX
  SHL SI,1
  MOV AL,byte [bmp_palette+SI]       ;R (0-7)
  MOV AH,byte [bmp_palette+SI+1]
  MOV DL,AH
  SHR DL,4                           ;G (0-7)
  AND AH,0x07                        ;B (0-7)
  ADD AL,DL
  ADD AL,AH                          ;brightness = R+G+B (0-21)
  MOV byte [pal_brightness+BX],AL
  INC BX
  CMP BX,16
  JB .pal_calc

  ; --- Step 2: find darkest (min brightness) → swap to position 0 ---
  XOR BX,BX                          ;BX = best position
  MOV AL,byte [pal_brightness]       ;AL = best (min) brightness
  MOV SI,1
.dark_scan:
  CMP SI,16
  JGE .dark_found
  CMP byte [pal_brightness+SI],AL
  JGE .dark_skip
  MOV AL,byte [pal_brightness+SI]
  MOV BX,SI
.dark_skip:
  INC SI
  JMP .dark_scan
.dark_found:
  OR BX,BX
  JZ .dark_ok
  XOR DI,DI                          ;swap pos 0 ↔ BX
  CALL .swap_pal
.dark_ok:

  ; --- Step 3: find brightest (max) in positions 1-15 → swap to 15 ---
  MOV BX,1
  MOV AL,byte [pal_brightness+1]
  MOV SI,2
.bright_scan:
  CMP SI,16
  JGE .bright_found
  CMP byte [pal_brightness+SI],AL
  JLE .bright_skip
  MOV AL,byte [pal_brightness+SI]
  MOV BX,SI
.bright_skip:
  INC SI
  JMP .bright_scan
.bright_found:
  CMP BX,15
  JE .bright_ok
  MOV DI,15
  CALL .swap_pal
.bright_ok:

  ; --- Step 4: find 2nd brightest in positions 1-14 → swap to 7 ---
  MOV BX,1
  MOV AL,byte [pal_brightness+1]
  MOV SI,2
.second_scan:
  CMP SI,15                          ;stop before position 15
  JGE .second_found
  CMP byte [pal_brightness+SI],AL
  JLE .second_skip
  MOV AL,byte [pal_brightness+SI]
  MOV BX,SI
.second_skip:
  INC SI
  JMP .second_scan
.second_found:
  CMP BX,7
  JE .second_ok
  MOV DI,7
  CALL .swap_pal
.second_ok:

  ; --- Step 5: find 3rd brightest in positions 1-14 (skip 7) → swap to 12 ---
  MOV BX,1
  MOV AL,byte [pal_brightness+1]
  MOV SI,2
.third_scan:
  CMP SI,15                          ;stop before position 15
  JGE .third_found
  CMP SI,7                           ;skip position 7
  JE .third_skip
  CMP byte [pal_brightness+SI],AL
  JLE .third_skip
  MOV AL,byte [pal_brightness+SI]
  MOV BX,SI
.third_skip:
  INC SI
  JMP .third_scan
.third_found:
  CMP BX,12
  JE .third_ok
  MOV DI,12
  CALL .swap_pal
.third_ok:

  ; --- Step 6: build inverse remap table ---
  ; pal_remap[new_pos] = old_original_index  (built during swaps)
  ; pal_inv_remap[old_index] = new_position  (needed for pixel remap)
  XOR BX,BX
.inv_build:
  MOV AL,byte [pal_remap+BX]
  XOR AH,AH
  MOV SI,AX
  MOV byte [pal_inv_remap+SI],BL
  INC BX
  CMP BX,16
  JB .inv_build

  ; --- Step 7: remap all pixels in bmp_background ---
  ; For each byte, remap both nibbles using pal_inv_remap
  MOV SI,bmp_background
  MOV CX,16000
.remap_px:
  MOV AL,byte [SI]
  ; Remap high nibble
  MOV AH,AL
  SHR AH,4
  XOR BH,BH
  MOV BL,AH
  MOV AH,byte [pal_inv_remap+BX]
  SHL AH,4
  ; Remap low nibble
  AND AL,0x0F
  MOV BL,AL
  MOV AL,byte [pal_inv_remap+BX]
  OR AL,AH
  MOV byte [SI],AL
  INC SI
  LOOP .remap_px

  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

; --- Swap palette positions DI and BX ---
; Updates pal_brightness, pal_remap, and bmp_palette (2 bytes per entry)
.swap_pal:
  PUSH AX
  PUSH DX
  PUSH SI
  ; Swap brightness[DI] ↔ brightness[BX]
  MOV AL,byte [pal_brightness+DI]
  MOV AH,byte [pal_brightness+BX]
  MOV byte [pal_brightness+DI],AH
  MOV byte [pal_brightness+BX],AL
  ; Swap remap[DI] ↔ remap[BX]
  MOV AL,byte [pal_remap+DI]
  MOV AH,byte [pal_remap+BX]
  MOV byte [pal_remap+DI],AH
  MOV byte [pal_remap+BX],AL
  ; Swap palette[DI*2..+1] ↔ palette[BX*2..+1]
  MOV SI,DI
  SHL SI,1
  PUSH BX
  SHL BX,1
  MOV AX,word [bmp_palette+SI]
  MOV DX,word [bmp_palette+BX]
  MOV word [bmp_palette+SI],DX
  MOV word [bmp_palette+BX],AX
  POP BX
  POP SI
  POP DX
  POP AX
  RET

;============================================================================
; STARTUP BMP SCREEN — 8-Bit BMP with CGA Palette Flip
; Uses PC1-BMP4 flip-first per-scanline V6355D palette reprogramming
; technique in CGA 320x200x4 mode for 3 independent colors per scanline.
;
; Pass 1 (load_startup_bmp, called once at startup):
;   Reads STYX.BMP, analyzes per-scanline color frequencies, builds
;   palette stream data. Uses bmp_background area for temp buffers.
;
; Pass 2 (show_startup_screen, called to display):
;   Re-reads STYX.BMP, remaps pixels to 2bpp CGA, renders to VRAM.
;   Uses p12e shadow buffer for temp buffers (free during CGA mode).
;   Enters FLIP-FIRST display loop until keypress.
;============================================================================

; --- Temp buffer equates (Pass 1: bmp_background, Pass 2: p12e) ---
ss_bmp_header     equ bmp_background
ss_p1_row_buffer  equ bmp_background + 1088
ss_p1_color_count equ bmp_background + 1412
ss_p1_clc         equ bmp_background + 1924
ss_bulk_buffer    equ p12e + 1024           ; Bulk read buffer (3200 bytes, safe in p12e's free area)

ss_p2_row_buffer  equ p12e
ss_p2_remap_table equ p12e + 324

;============================================================================
; load_startup_bmp — Load and analyze STYX.BMP (called once at startup)
; Sets ss_loaded=1 on success. Uses bmp_background for temp buffers.
;============================================================================
load_startup_bmp:
  PUSH SI
  PUSH DI

  MOV byte [ss_loaded],0

  ; Open STYX.BMP
  MOV DX,ss_filename
  MOV AX,0x3D00
  INT 0x21
  JC .fail
  MOV [ss_file_handle],AX

  ; Read header + palette (up to 1078 bytes)
  MOV BX,AX
  MOV DX,ss_bmp_header
  MOV CX,1078
  MOV AH,0x3F
  INT 0x21
  JC .close
  CMP AX,54
  JB .close

  ; Validate BMP signature 'BM'
  CMP word [ss_bmp_header],0x4D42
  JNE .close

  ; Detect bits per pixel
  MOV AX,[ss_bmp_header + 28]
  CMP AX,4
  JE .bpp4
  CMP AX,8
  JE .bpp8
  JMP .close

.bpp4:
  MOV byte [ss_bpp],4
  MOV word [ss_num_colors],16
  MOV word [ss_row_bytes],160
  JMP .bpp_ok

.bpp8:
  MOV byte [ss_bpp],8
  MOV word [ss_num_colors],256
  MOV word [ss_row_bytes],320

.bpp_ok:
  ; Must be uncompressed
  CMP word [ss_bmp_header + 30],0
  JNE .close

  ; Must be 320 wide
  CMP word [ss_bmp_header + 18],320
  JNE .close

  ; Height: accept positive 200 or absolute value
  MOV AX,[ss_bmp_header + 22]
  TEST AX,AX
  JNS .hpos
  NEG AX
.hpos:
  CMP AX,200
  JNE .close

  ; Save pixel data offset
  MOV AX,[ss_bmp_header + 10]
  MOV [ss_data_offset_lo],AX
  MOV AX,[ss_bmp_header + 12]
  MOV [ss_data_offset_hi],AX

  ; Convert palette
  CALL ss_convert_palette

  ; Find background (darkest color)
  CALL ss_find_bg_index

  ; Seek to pixel data for Pass 1
  MOV BX,[ss_file_handle]
  MOV DX,[ss_data_offset_lo]
  MOV CX,[ss_data_offset_hi]
  MOV AX,0x4200
  INT 0x21
  JC .close

  ; Pass 1: analyze all scanlines
  CALL ss_analyze_image

  ; Reorder by stability
  CALL ss_reorder_by_stability

  ; Build palette stream (2400 bytes)
  CALL ss_build_palette_stream

  ; Build stream lengths (200 bytes)
  CALL ss_build_stream_lengths

  MOV byte [ss_loaded],1

.close:
  MOV BX,[ss_file_handle]
  OR BX,BX
  JZ .fail
  MOV AH,0x3E
  INT 0x21

.fail:
  POP DI
  POP SI
  RET

;============================================================================
; show_startup_screen — Display STYX.BMP as startup/attract screen
; On first call: reads STYX.BMP, renders to off-screen bmp_background
; buffer (text splash stays visible), saves to cache segment, then
; switches to CGA mode 4 and copies to VRAM.
; On subsequent calls: restores from cache (no disk I/O needed).
; Draws high scores, programs palette, enters FLIP-FIRST V6355D
; palette streaming display loop with animated raster bars.
; Video stays disabled until the first palette frame is ready, ensuring
; a clean transition. On keypress, disables video before returning
; to prevent palette flash during the transition to gameplay.
;============================================================================
show_startup_screen:
  PUSH SI
  PUSH DI

  ; Check if we have a cached copy of the rendered VRAM
  CMP byte [ss_vram_cached],1
  JE .restore_from_cache

  ; --- First time: render from BMP file ---
  CLD

  ; Open file for Pass 2
  MOV DX,ss_filename
  MOV AX,0x3D00
  INT 0x21
  JC .show_fail
  MOV [ss_file_handle],AX

  ; Seek to pixel data
  MOV BX,AX
  MOV DX,[ss_data_offset_lo]
  MOV CX,[ss_data_offset_hi]
  MOV AX,0x4200
  INT 0x21
  JC .show_close

  ; Pass 2: render to off-screen buffer (text splash stays visible)
  CALL ss_render_to_vram

.show_close:
  MOV BX,[ss_file_handle]
  MOV AH,0x3E
  INT 0x21

  ; Save rendered buffer to cache segment (if allocated)
  CMP word [ss_vram_cache_seg],0
  JZ .skip_cache_save
  CALL ss_save_to_cache
  MOV byte [ss_vram_cached],1
.skip_cache_save:
  JMP SHORT .mode_switch

.restore_from_cache:
  ; Restore bmp_background from cache segment
  CALL ss_restore_from_cache

.mode_switch:
  ; --- Quick switch: text → mode 4 with video disabled ---
  MOV AL,0x02
  OUT 0xD8,AL                     ; Disable video (last text frame lingers)

  MOV AX,0x0004
  INT 0x10                        ; Set CGA mode 4 (invisible)
  CLD

  MOV AL,0x02
  OUT 0xD8,AL                     ; Re-disable (BIOS may have re-enabled)

  ; Copy off-screen buffer to CGA VRAM
  CALL ss_copy_buffer_to_vram

  ; Draw high scores while display is still off (BIOS writes to VRAM)
  CALL o3e6d

  ; Program initial palette (entry 0 = black, entries 2-7 from BMP)
  CALL ss_program_initial_palette

  ; Initialize raster bar state
  MOV byte [ss_bar1_sine_idx],0
  MOV byte [ss_bar2_sine_idx],85   ;120° offset
  CALL ss_build_scanline_table

  ; Clear stale keypress
  MOV byte [pc3],0

  ; Set PAL_EVEN, bg = entry 0
  XOR AL,AL
  OUT 0xD9,AL

  ; Wait for VBLANK, render first frame while display is off, then enable
  CALL ss_wait_vblank
  CALL ss_render_frame

  ; Enable video
  MOV AL,0x0A
  OUT 0xD8,AL

  ; Display loop: animate bars, render_frame per VSYNC, check for keypress
.display_loop:
  ; Update bar positions (during VBLANK / between frames)
  ADD byte [ss_bar1_sine_idx],2    ;Speed 2
  MOV AL,[ss_bar1_sine_idx]
  XOR AH,AH
  MOV SI,AX
  MOV AL,[ss_sine_table + SI]
  SHR AL,2                        ;0-97 → 0-24
  ADD AL,SS_BAR_START              ;Offset into bar zone
  MOV [ss_bar1_y],AL

  ADD byte [ss_bar2_sine_idx],3    ;Speed 3
  MOV AL,[ss_bar2_sine_idx]
  XOR AH,AH
  MOV SI,AX
  MOV AL,[ss_sine_table + SI]
  SHR AL,2
  ADD AL,SS_BAR_START
  MOV [ss_bar2_y],AL

  CALL ss_build_scanline_table

  CALL ss_wait_vblank
  CALL ss_render_frame
  MOV AL,byte [pc3]
  TEST AL,AL
  JZ .display_loop
  XOR AH,AH
  AND AX,0x80
  JNZ .display_loop         ;Ignore key-release events

  ; Disable video before returning to prevent palette flash
  MOV AL,0x02
  OUT 0xD8,AL

.show_fail:
  POP DI
  POP SI
  RET

;============================================================================
; ss_convert_palette — Convert BMP BGRA palette to RGB888 + V6355D format
;============================================================================
ss_convert_palette:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH SI
  PUSH DI

  MOV SI,ss_bmp_header + 54
  XOR DI,DI
  MOV CX,[ss_num_colors]

.cvt_loop:
  LODSB
  MOV [ss_pal_b + DI],AL       ;Blue
  LODSB
  MOV [ss_pal_g + DI],AL       ;Green
  LODSB
  MOV [ss_pal_r + DI],AL       ;Red

  ; Build V6355D 2-byte entry
  MOV BX,DI
  SHL BX,1
  MOV AL,[ss_pal_r + DI]
  SHR AL,5
  MOV [ss_v6355_pal + BX],AL

  MOV AL,[ss_pal_g + DI]
  AND AL,0xE0
  SHR AL,1
  MOV AH,AL
  MOV AL,[ss_pal_b + DI]
  SHR AL,5
  OR AL,AH
  MOV [ss_v6355_pal + BX + 1],AL

  LODSB                         ;Skip alpha byte
  INC DI
  LOOP .cvt_loop

  POP DI
  POP SI
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_find_bg_index — Auto-detect darkest palette entry as background
;============================================================================
ss_find_bg_index:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI

  XOR AX,AX                    ;AX = best index
  MOV DX,0x7FFF                ;DX = min brightness sum
  XOR BX,BX
  MOV CX,[ss_num_colors]

.fbg_loop:
  PUSH AX
  XOR SI,SI
  XOR AH,AH
  MOV AL,[ss_pal_r + BX]
  ADD SI,AX
  MOV AL,[ss_pal_g + BX]
  ADD SI,AX
  MOV AL,[ss_pal_b + BX]
  ADD SI,AX
  POP AX

  CMP SI,DX
  JAE .fbg_skip
  MOV DX,SI
  MOV AX,BX

.fbg_skip:
  INC BX
  LOOP .fbg_loop

  MOV [ss_bg_index],AL

  ; Force bg to black in palette tables
  XOR BH,BH
  MOV BL,AL
  MOV byte [ss_pal_r + BX],0
  MOV byte [ss_pal_g + BX],0
  MOV byte [ss_pal_b + BX],0
  SHL BX,1
  MOV word [ss_v6355_pal + BX],0

  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_analyze_image — Pass 1: Read all BMP rows, find top 3 per scanline
; BMP is bottom-up: first row read = screen row 199.
;============================================================================
ss_analyze_image:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI

  MOV word [ss_cur_row],199
  MOV word [ss_bulk_remaining],0   ; Reset bulk buffer for Pass 1

.ai_loop:
  MOV DX,ss_p1_row_buffer
  CALL ss_read_bmp_row
  JC .ai_done
  CMP AX,[ss_row_bytes]
  JB .ai_done

  CALL ss_analyze_scanline

  ; C64-style border cycling: change border color each row
  PUSH AX
  MOV AL,[ss_border_ctr]
  OUT 0xD9,AL
  INC byte [ss_border_ctr]
  AND byte [ss_border_ctr],0x0F
  POP AX

  MOV AX,[ss_cur_row]
  OR AX,AX
  JZ .ai_done
  DEC word [ss_cur_row]
  JMP .ai_loop

.ai_done:
  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_analyze_scanline — Count colors, find top 3 for current row
;============================================================================
ss_analyze_scanline:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI

  ; Clear color counts (256 words)
  PUSH ES
  PUSH DS
  POP ES
  MOV DI,ss_p1_color_count
  MOV CX,256
  XOR AX,AX
  REP STOSW
  POP ES

  ; Count pixel colors
  MOV SI,ss_p1_row_buffer
  CMP byte [ss_bpp],8
  JE .count_8bpp

  ; --- 4bpp: 2 pixels per byte ---
  MOV CX,160
  XOR BH,BH
.count4:
  LODSB
  MOV AH,AL
  SHR AL,4
  MOV BL,AL
  SHL BX,1
  INC word [ss_p1_color_count + BX]
  SHR BX,1
  MOV AL,AH
  AND AL,0x0F
  MOV BL,AL
  SHL BX,1
  INC word [ss_p1_color_count + BX]
  SHR BX,1
  LOOP .count4
  JMP .count_done

  ; --- 8bpp: 1 pixel per byte ---
.count_8bpp:
  MOV CX,320
  XOR BH,BH
.count8:
  LODSB
  MOV BL,AL
  SHL BX,1
  INC word [ss_p1_color_count + BX]
  SHR BX,1
  LOOP .count8

.count_done:
  ; Exclude background
  XOR BX,BX
  MOV BL,[ss_bg_index]
  SHL BX,1
  MOV word [ss_p1_color_count + BX],0

  ; Find top 3
  CALL ss_find_max_color
  MOV [ss_top3_temp],AL
  XOR BX,BX
  MOV BL,AL
  SHL BX,1
  MOV word [ss_p1_color_count + BX],0

  CALL ss_find_max_color
  MOV [ss_top3_temp + 1],AL
  XOR BX,BX
  MOV BL,AL
  SHL BX,1
  MOV word [ss_p1_color_count + BX],0

  CALL ss_find_max_color
  MOV [ss_top3_temp + 2],AL

  ; Store top3 for this scanline
  MOV BX,[ss_cur_row]
  MOV AX,BX
  SHL AX,1
  ADD BX,AX
  MOV AL,[ss_top3_temp]
  MOV [ss_scanline_top3 + BX],AL
  MOV AL,[ss_top3_temp + 1]
  MOV [ss_scanline_top3 + BX + 1],AL
  MOV AL,[ss_top3_temp + 2]
  MOV [ss_scanline_top3 + BX + 2],AL

  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_find_max_color — Find palette index with highest pixel count
; Returns: AL = best index (ss_bg_index if no non-zero counts remain)
;============================================================================
ss_find_max_color:
  PUSH BX
  PUSH CX
  PUSH DX

  XOR AX,AX
  MOV AL,[ss_bg_index]
  XOR DX,DX
  XOR BX,BX
  MOV CX,[ss_num_colors]

.fmc_loop:
  CMP [ss_p1_color_count + BX],DX
  JBE .fmc_skip
  MOV DX,[ss_p1_color_count + BX]
  MOV AX,BX
  SHR AX,1

.fmc_skip:
  ADD BX,2
  DEC CX
  JNZ .fmc_loop

  POP DX
  POP CX
  POP BX
  RET

;============================================================================
; ss_reorder_by_stability — Reorder top3: most stable → high entries (6/7)
;============================================================================
ss_reorder_by_stability:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI

  ; Clear line presence counts (256 words)
  PUSH ES
  PUSH DS
  POP ES
  MOV DI,ss_p1_clc
  MOV CX,256
  XOR AX,AX
  REP STOSW
  POP ES

  ; Count lines where each color appears
  MOV SI,ss_scanline_top3
  MOV CX,200
.rbs_count:
  LODSB
  CMP AL,[ss_bg_index]
  JE .rbs_s1
  XOR BX,BX
  MOV BL,AL
  SHL BX,1
  INC word [ss_p1_clc + BX]
.rbs_s1:
  LODSB
  CMP AL,[ss_bg_index]
  JE .rbs_s2
  XOR BX,BX
  MOV BL,AL
  SHL BX,1
  INC word [ss_p1_clc + BX]
.rbs_s2:
  LODSB
  CMP AL,[ss_bg_index]
  JE .rbs_s3
  XOR BX,BX
  MOV BL,AL
  SHL BX,1
  INC word [ss_p1_clc + BX]
.rbs_s3:
  LOOP .rbs_count

  ; Find most common → ss_global_c (entries 6/7)
  XOR AX,AX
  MOV AL,[ss_bg_index]
  XOR DX,DX
  XOR BX,BX
  MOV CX,[ss_num_colors]
.find1:
  CMP [ss_p1_clc + BX],DX
  JBE .f1_skip
  MOV DX,[ss_p1_clc + BX]
  MOV AX,BX
  SHR AX,1
.f1_skip:
  ADD BX,2
  LOOP .find1

  MOV [ss_global_c],AL
  CMP AL,[ss_bg_index]
  JE .no_reorder
  XOR BX,BX
  MOV BL,AL
  SHL BX,1
  MOV word [ss_p1_clc + BX],0

  ; Find 2nd most common → ss_global_b (entries 4/5)
  XOR AX,AX
  MOV AL,[ss_bg_index]
  XOR DX,DX
  XOR BX,BX
  MOV CX,[ss_num_colors]
.find2:
  CMP [ss_p1_clc + BX],DX
  JBE .f2_skip
  MOV DX,[ss_p1_clc + BX]
  MOV AX,BX
  SHR AX,1
.f2_skip:
  ADD BX,2
  LOOP .find2

  MOV [ss_global_b],AL

  ; Reorder each line's top3
  MOV SI,ss_scanline_top3
  MOV CX,200
.reorder:
  MOV AL,[SI]
  MOV AH,[SI + 1]
  MOV DL,[SI + 2]

  ; Place global_c in slot 2
  MOV DH,[ss_global_c]
  CMP DL,DH
  JE .chk_b
  CMP AL,DH
  JE .c_in_0
  CMP AH,DH
  JE .c_in_1
  JMP .chk_b
.c_in_0:
  XCHG AL,DL
  JMP .chk_b
.c_in_1:
  XCHG AH,DL
.chk_b:
  MOV DH,[ss_global_b]
  CMP DH,[ss_bg_index]
  JE .rbs_store
  CMP AH,DH
  JE .rbs_store
  CMP AL,DH
  JNE .rbs_store
  XCHG AL,AH
.rbs_store:
  MOV [SI],AL
  MOV [SI + 1],AH
  MOV [SI + 2],DL
  ADD SI,3
  LOOP .reorder

.no_reorder:
  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_build_palette_stream — Build interleaved V6355D data for entries 2-7
; 200 lines x 12 bytes = 2400 bytes total.
;============================================================================
ss_build_palette_stream:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI

  XOR CX,CX
  MOV DI,ss_palette_stream

.bps_loop:
  ; Far line (N+2) — inactive pre-load target
  MOV BX,CX
  ADD BX,2
  CMP BX,200
  JB .far_ok
  SUB BX,200
.far_ok:
  MOV AX,BX
  SHL AX,1
  ADD BX,AX
  MOV AL,[ss_scanline_top3 + BX]
  MOV [ss_bps_cur_a],AL
  MOV AL,[ss_scanline_top3 + BX + 1]
  MOV [ss_bps_cur_b],AL
  MOV AL,[ss_scanline_top3 + BX + 2]
  MOV [ss_bps_cur_c],AL

  ; Near line (N+1) — passthrough
  MOV BX,CX
  INC BX
  CMP BX,200
  JB .near_ok
  SUB BX,200
.near_ok:
  MOV AX,BX
  SHL AX,1
  ADD BX,AX
  MOV AL,[ss_scanline_top3 + BX]
  MOV [ss_bps_nxt_a],AL
  MOV AL,[ss_scanline_top3 + BX + 1]
  MOV [ss_bps_nxt_b],AL
  MOV AL,[ss_scanline_top3 + BX + 2]
  MOV [ss_bps_nxt_c],AL

  TEST CL,1
  JNZ .bps_odd

  ; EVEN line: E2,E4,E6=far(inactive), E3,E5,E7=near(active)
  XOR BX,BX
  MOV BL,[ss_bps_cur_a]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI],AX
  XOR BX,BX
  MOV BL,[ss_bps_nxt_a]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 2],AX
  XOR BX,BX
  MOV BL,[ss_bps_cur_b]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 4],AX
  XOR BX,BX
  MOV BL,[ss_bps_nxt_b]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 6],AX
  XOR BX,BX
  MOV BL,[ss_bps_cur_c]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 8],AX
  XOR BX,BX
  MOV BL,[ss_bps_nxt_c]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 10],AX
  JMP .bps_next

.bps_odd:
  ; ODD line: E2,E4,E6=near(active), E3,E5,E7=far(inactive)
  XOR BX,BX
  MOV BL,[ss_bps_nxt_a]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI],AX
  XOR BX,BX
  MOV BL,[ss_bps_cur_a]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 2],AX
  XOR BX,BX
  MOV BL,[ss_bps_nxt_b]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 4],AX
  XOR BX,BX
  MOV BL,[ss_bps_cur_b]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 6],AX
  XOR BX,BX
  MOV BL,[ss_bps_nxt_c]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 8],AX
  XOR BX,BX
  MOV BL,[ss_bps_cur_c]
  SHL BX,1
  MOV AX,[ss_v6355_pal + BX]
  MOV [DI + 10],AX

.bps_next:
  ADD DI,12
  INC CX
  CMP CX,200
  JB .bps_loop

  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_build_stream_lengths — Determine skip(0) or write(12) per scanline
;============================================================================
ss_build_stream_lengths:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH SI
  PUSH DI

  MOV byte [ss_stream_len],12       ;Line 0 always full
  MOV SI,1

.bsl_loop:
  MOV BX,SI
  MOV AX,BX
  SHL AX,1
  ADD BX,AX

  MOV DI,SI
  ADD DI,2
  CMP DI,200
  JB .bsl_ok
  SUB DI,200
.bsl_ok:
  MOV AX,DI
  SHL AX,1
  ADD DI,AX

  MOV AL,[ss_scanline_top3 + BX]
  CMP AL,[ss_scanline_top3 + DI]
  JNE .bsl_full
  MOV AL,[ss_scanline_top3 + BX + 1]
  CMP AL,[ss_scanline_top3 + DI + 1]
  JNE .bsl_full
  MOV AL,[ss_scanline_top3 + BX + 2]
  CMP AL,[ss_scanline_top3 + DI + 2]
  JNE .bsl_full

  MOV byte [ss_stream_len + SI],0
  JMP .bsl_next

.bsl_full:
  MOV byte [ss_stream_len + SI],12

.bsl_next:
  INC SI
  CMP SI,200
  JB .bsl_loop

  POP DI
  POP SI
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_render_to_vram — Pass 2: Read BMP, remap pixels, write to off-screen
; buffer (bmp_background) with C64-style border cycling (text mode
; splash stays visible). Uses p12e area for row_buffer and remap_table.
;============================================================================
ss_render_to_vram:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI
  PUSH DI
  PUSH ES

  PUSH DS
  POP ES                          ; ES = DS (write to bmp_background)
  MOV word [ss_cur_row],199
  MOV word [ss_bulk_remaining],0   ; Reset bulk buffer for Pass 2

.rv_loop:
  MOV DX,ss_p2_row_buffer
  CALL ss_read_bmp_row
  JC .rv_done
  CMP AX,[ss_row_bytes]
  JB .rv_done

  CALL ss_build_remap_table

  ; Calculate CGA VRAM offset (interlaced)
  MOV AX,[ss_cur_row]
  PUSH AX
  SHR AX,1
  MOV BX,80
  MUL BX
  MOV DI,AX
  POP AX
  TEST AL,1
  JZ .rv_even
  ADD DI,0x2000
.rv_even:
  ADD DI,bmp_background             ; Offset into off-screen buffer

  MOV SI,ss_p2_row_buffer
  MOV BX,ss_p2_remap_table
  MOV CX,80

  CMP byte [ss_bpp],8
  JE .rv_8

  ; --- 4bpp conversion ---
.rv_4:
  XOR DH,DH
  LODSB
  MOV DL,AL
  SHR AL,4
  XLAT
  OR DH,AL
  SHL DH,2
  MOV AL,DL
  AND AL,0x0F
  XLAT
  OR DH,AL
  SHL DH,2
  LODSB
  MOV DL,AL
  SHR AL,4
  XLAT
  OR DH,AL
  SHL DH,2
  MOV AL,DL
  AND AL,0x0F
  XLAT
  OR DH,AL
  MOV AL,DH
  STOSB
  LOOP .rv_4
  JMP .rv_cv_done

  ; --- 8bpp conversion ---
.rv_8:
  XOR DH,DH
  LODSB
  XLAT
  OR DH,AL
  SHL DH,2
  LODSB
  XLAT
  OR DH,AL
  SHL DH,2
  LODSB
  XLAT
  OR DH,AL
  SHL DH,2
  LODSB
  XLAT
  OR DH,AL
  MOV AL,DH
  STOSB
  LOOP .rv_8

.rv_cv_done:

  ; C64-style border cycling (text mode still active)
  PUSH AX
  MOV AL,[ss_border_ctr]
  OUT 0xD9,AL
  INC byte [ss_border_ctr]
  AND byte [ss_border_ctr],0x0F
  POP AX

  MOV AX,[ss_cur_row]
  OR AX,AX
  JZ .rv_done
  DEC word [ss_cur_row]
  JMP .rv_loop

.rv_done:
  POP ES
  POP DI
  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_copy_buffer_to_vram — Copy bmp_background to CGA VRAM at 0xB800
; Even bank: 8000 bytes at offset 0, Odd bank: 8000 bytes at offset 0x2000
; Call with video disabled. Uses REP MOVSW for speed.
;============================================================================
ss_copy_buffer_to_vram:
  PUSH AX
  PUSH CX
  PUSH SI
  PUSH DI
  PUSH DS
  PUSH ES

  MOV AX,0xB800
  MOV ES,AX

  ; Copy even bank (8000 bytes)
  MOV SI,bmp_background
  XOR DI,DI
  MOV CX,4000
  REP MOVSW

  ; Copy odd bank (8000 bytes)
  MOV SI,bmp_background + 0x2000
  MOV DI,0x2000
  MOV CX,4000
  REP MOVSW

  POP ES
  POP DS
  POP DI
  POP SI
  POP CX
  POP AX
  RET

;============================================================================
; ss_save_to_cache — Copy bmp_background (16192 bytes) to cache segment
;============================================================================
ss_save_to_cache:
  PUSH CX
  PUSH SI
  PUSH DI
  PUSH DS
  PUSH ES

  MOV AX,[ss_vram_cache_seg]
  MOV ES,AX                       ; ES = cache segment
  MOV SI,bmp_background
  XOR DI,DI
  MOV CX,8096                     ; 16192 / 2
  REP MOVSW

  POP ES
  POP DS
  POP DI
  POP SI
  POP CX
  RET

;============================================================================
; ss_restore_from_cache — Copy cache segment back to bmp_background
;============================================================================
ss_restore_from_cache:
  PUSH AX
  PUSH CX
  PUSH SI
  PUSH DI
  PUSH DS
  PUSH ES

  MOV AX,DS                       ; Save data segment
  MOV ES,AX                       ; ES = data segment (destination)
  MOV AX,[ss_vram_cache_seg]
  MOV DS,AX                       ; DS = cache segment (source)
  XOR SI,SI                       ; Source: cache segment offset 0
  MOV DI,bmp_background           ; Dest: bmp_background in data segment
  MOV CX,8096                     ; 16192 / 2
  REP MOVSW

  POP ES
  POP DS
  POP DI
  POP SI
  POP CX
  POP AX
  RET

;============================================================================
; ss_build_remap_table — Build BMP index → CGA value (0-3) lookup
; CGA: 0=black, 1=ColorA(E2/3), 2=ColorB(E4/5), 3=ColorC(E6/7)
;============================================================================
ss_build_remap_table:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI

  MOV BX,[ss_cur_row]
  MOV AX,BX
  SHL AX,1
  ADD BX,AX

  MOV AL,[ss_scanline_top3 + BX]
  MOV [ss_top3_temp],AL
  MOV AL,[ss_scanline_top3 + BX + 1]
  MOV [ss_top3_temp + 1],AL
  MOV AL,[ss_scanline_top3 + BX + 2]
  MOV [ss_top3_temp + 2],AL

  XOR CX,CX

.brt_loop:
  CMP CL,[ss_bg_index]
  JE .brt_black
  CMP CL,[ss_top3_temp]
  JE .brt_1
  CMP CL,[ss_top3_temp + 1]
  JE .brt_2
  CMP CL,[ss_top3_temp + 2]
  JE .brt_3
  CALL ss_find_nearest
  JMP .brt_store

.brt_black:
  XOR AL,AL
  JMP .brt_store
.brt_1:
  MOV AL,1
  JMP .brt_store
.brt_2:
  MOV AL,2
  JMP .brt_store
.brt_3:
  MOV AL,3

.brt_store:
  MOV BX,CX
  MOV [ss_p2_remap_table + BX],AL
  INC CX
  CMP CX,[ss_num_colors]
  JB .brt_loop

  POP SI
  POP DX
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_find_nearest — Find nearest CGA value by RGB Manhattan distance
; Input: CL = BMP palette index    Output: AL = CGA value (0-3)
;============================================================================
ss_find_nearest:
  PUSH BX
  PUSH CX
  PUSH DX
  PUSH SI

  XOR BH,BH
  MOV BL,CL

  ; Distance to black (0,0,0)
  XOR DX,DX
  XOR AH,AH
  MOV AL,[ss_pal_r + BX]
  ADD DX,AX
  MOV AL,[ss_pal_g + BX]
  ADD DX,AX
  MOV AL,[ss_pal_b + BX]
  ADD DX,AX
  MOV [ss_nn_best_dist],DX
  MOV byte [ss_nn_best_cga],0

  ; Distance to Color A
  MOV AL,[ss_top3_temp]
  CMP AL,[ss_bg_index]
  JE .fn_done
  XOR AH,AH
  MOV SI,AX
  CALL ss_compute_dist
  CMP DX,[ss_nn_best_dist]
  JAE .fn_try2
  MOV [ss_nn_best_dist],DX
  MOV byte [ss_nn_best_cga],1

.fn_try2:
  MOV AL,[ss_top3_temp + 1]
  CMP AL,[ss_bg_index]
  JE .fn_done
  XOR AH,AH
  MOV SI,AX
  CALL ss_compute_dist
  CMP DX,[ss_nn_best_dist]
  JAE .fn_try3
  MOV [ss_nn_best_dist],DX
  MOV byte [ss_nn_best_cga],2

.fn_try3:
  MOV AL,[ss_top3_temp + 2]
  CMP AL,[ss_bg_index]
  JE .fn_done
  XOR AH,AH
  MOV SI,AX
  CALL ss_compute_dist
  CMP DX,[ss_nn_best_dist]
  JAE .fn_done
  MOV byte [ss_nn_best_cga],3

.fn_done:
  MOV AL,[ss_nn_best_cga]

  POP SI
  POP DX
  POP CX
  POP BX
  RET

;============================================================================
; ss_compute_dist — RGB888 Manhattan distance |R1-R2|+|G1-G2|+|B1-B2|
; Input: BX = index 1, SI = index 2    Output: DX = distance
;============================================================================
ss_compute_dist:
  XOR DX,DX
  MOV AL,[ss_pal_r + BX]
  SUB AL,[ss_pal_r + SI]
  JNC .r_pos
  NEG AL
.r_pos:
  XOR AH,AH
  ADD DX,AX
  MOV AL,[ss_pal_g + BX]
  SUB AL,[ss_pal_g + SI]
  JNC .g_pos
  NEG AL
.g_pos:
  XOR AH,AH
  ADD DX,AX
  MOV AL,[ss_pal_b + BX]
  SUB AL,[ss_pal_b + SI]
  JNC .b_pos
  NEG AL
.b_pos:
  XOR AH,AH
  ADD DX,AX
  RET

;============================================================================
; ss_read_bmp_row — Buffered BMP row reader
; Reads SS_BULK_ROWS rows per DOS call, serves one row at a time.
; Input: DX = target buffer address
; Returns: CF set on error, AX = bytes read (one row)
;============================================================================
ss_read_bmp_row:
  PUSH BX
  PUSH CX
  PUSH SI
  PUSH DI

  CMP word [ss_bulk_remaining],0
  JNE .br_serve

  ; Buffer empty — read up to SS_BULK_ROWS rows from disk
  PUSH DX                         ; Save caller's target buffer
  MOV AX,SS_BULK_ROWS
  MUL word [ss_row_bytes]         ; AX = total bytes to read
  MOV CX,AX
  MOV DX,ss_bulk_buffer
  MOV BX,[ss_file_handle]
  MOV AH,0x3F
  INT 0x21
  JC .br_err_pop

  ; Calculate rows actually read (AX = bytes read from DOS)
  XOR DX,DX
  DIV word [ss_row_bytes]         ; AX = rows, DX = remainder
  OR AX,AX
  JZ .br_err_pop
  MOV [ss_bulk_remaining],AX
  MOV word [ss_bulk_ptr],ss_bulk_buffer
  POP DX                          ; Restore caller's target buffer
  JMP SHORT .br_serve

.br_err_pop:
  POP DX
  JMP SHORT .br_error

.br_serve:
  ; Copy one row from bulk buffer to caller's buffer (DX)
  PUSH ES
  PUSH DS
  POP ES                          ; ES = DS
  MOV SI,[ss_bulk_ptr]
  MOV DI,DX                       ; DI = caller's target buffer
  MOV CX,[ss_row_bytes]
  REP MOVSB
  POP ES

  ; Advance bulk pointer, decrement remaining
  MOV AX,[ss_row_bytes]
  ADD [ss_bulk_ptr],AX
  DEC word [ss_bulk_remaining]

  MOV AX,[ss_row_bytes]           ; Return: AX = bytes for one row
  CLC
  JMP SHORT .br_done

.br_error:
  STC

.br_done:
  POP DI
  POP SI
  POP CX
  POP BX
  RET

;============================================================================
; ss_program_initial_palette — Set V6355D entries 0-7 for first frame
;============================================================================
ss_program_initial_palette:
  PUSH AX
  PUSH BX
  PUSH SI

  CLI
  MOV AL,0x40
  OUT 0xDD,AL
  JMP SHORT $+2

  ; E0: black (background)
  XOR AL,AL
  OUT 0xDE,AL
  JMP SHORT $+2
  OUT 0xDE,AL
  JMP SHORT $+2
  ; E1: black (unused in CGA mode 4)
  OUT 0xDE,AL
  JMP SHORT $+2
  OUT 0xDE,AL
  JMP SHORT $+2

  ; E2 = line 0 Color A
  XOR BX,BX
  MOV BL,[ss_scanline_top3]
  SHL BX,1
  MOV AL,[ss_v6355_pal + BX]
  OUT 0xDE,AL
  JMP SHORT $+2
  MOV AL,[ss_v6355_pal + BX + 1]
  OUT 0xDE,AL
  JMP SHORT $+2

  ; E3 = line 1 Color A
  XOR BX,BX
  MOV BL,[ss_scanline_top3 + 3]
  SHL BX,1
  MOV AL,[ss_v6355_pal + BX]
  OUT 0xDE,AL
  JMP SHORT $+2
  MOV AL,[ss_v6355_pal + BX + 1]
  OUT 0xDE,AL
  JMP SHORT $+2

  ; E4 = line 0 Color B
  XOR BX,BX
  MOV BL,[ss_scanline_top3 + 1]
  SHL BX,1
  MOV AL,[ss_v6355_pal + BX]
  OUT 0xDE,AL
  JMP SHORT $+2
  MOV AL,[ss_v6355_pal + BX + 1]
  OUT 0xDE,AL
  JMP SHORT $+2

  ; E5 = line 1 Color B
  XOR BX,BX
  MOV BL,[ss_scanline_top3 + 4]
  SHL BX,1
  MOV AL,[ss_v6355_pal + BX]
  OUT 0xDE,AL
  JMP SHORT $+2
  MOV AL,[ss_v6355_pal + BX + 1]
  OUT 0xDE,AL
  JMP SHORT $+2

  ; E6 = line 0 Color C
  XOR BX,BX
  MOV BL,[ss_scanline_top3 + 2]
  SHL BX,1
  MOV AL,[ss_v6355_pal + BX]
  OUT 0xDE,AL
  JMP SHORT $+2
  MOV AL,[ss_v6355_pal + BX + 1]
  OUT 0xDE,AL
  JMP SHORT $+2

  ; E7 = line 1 Color C
  XOR BX,BX
  MOV BL,[ss_scanline_top3 + 5]
  SHL BX,1
  MOV AL,[ss_v6355_pal + BX]
  OUT 0xDE,AL
  JMP SHORT $+2
  MOV AL,[ss_v6355_pal + BX + 1]
  OUT 0xDE,AL
  JMP SHORT $+2

  MOV AL,0x80
  OUT 0xDD,AL
  STI

  POP SI
  POP BX
  POP AX
  RET

;============================================================================
; ss_render_frame — Per-scanline palette programming across 4 zones
;============================================================================
;
; Ported from palram9.asm. Called once per frame after wait_vblank.
;
; Uses the V6355D's dual palette bank feature ("CGA palette flip") to
; display more than 4 colors in 320×200 CGA mode 4. Two palette banks
; (PAL_EVEN = 0x00, PAL_ODD = 0x20) are alternated each scanline via
; port 0xD9. Each bank has entries E0-E7: E0 is shared by both banks
; (background color), while E2-E7 hold 3 independent colors per bank.
; By writing different colors to each bank's E2-E7, and flipping which
; bank is active at each HBLANK, each scanline can display 3 independent
; colors from the full 512-color V6355D palette. Writes happen during
; HBLANK to the INACTIVE bank ("flip-first"), so the 12-byte REP OUTSB
; spill past HBLANK is invisible.
;
; After 48 lines of flip-first, both banks have converged to the same
; E2-E7 values (the image has uniform colors from line 48 onward).
; Flipping stops and E2-E7 persist for the rest of the frame, including
; the bar zone where green STYX letters must remain visible.
;
; ZONE 1a — IMAGE (lines 0-47, 48 lines):
;   Flip-first E2-E7 streaming from ss_palette_stream.
;   Each HBLANK: flip bank via 0xD9, write 12 bytes (E2-E7) to inactive
;   bank via REP OUTSB to port 0xDE. After 48 even flips, BL/BH return
;   to their original values.
;
; ZONE 1b — IMAGE (lines 48-127, 80 lines):
;   Idle — HBLANK sync only, no palette writes. E2-E7 are already
;   correct in both banks from Zone 1a. Saves ~1200 I/O writes/frame.
;
; ZONE 2 — RASTER BARS (lines 128-173, 46 lines):
;   Entry 0 only — animated color bars behind green STYX letters.
;   Pre-fetch R into AH and G|B into [ss_bar_gb] BEFORE HBLANK wait.
;   During HBLANK: open E0 (0x40), write R, write G|B, close (0x80).
;   No palette flip needed (E0 is shared by both banks).
;
; ZONE 3 — IMAGE (lines 174-199, 26 lines):
;   Idle — HBLANK sync only, like Zone 1b.
;
; Parameters (defined at top of file, change to adjust layout):
;   SS_FLIP_LINES  equ 48     ; Lines of flip-first palette streaming
;   SS_BAR_START   equ 128    ; First scanline of raster bar zone
;   SS_BAR_END     equ 174    ; First scanline after bar zone (174-1=173)
;
; Register plan (matches palram9):
;   DX = 0xDE permanently (PORT_REG_DATA)
;   SI = palette_stream pointer (Zone 1a only, advanced by REP OUTSB)
;   DI = scanline_colors pointer (all zones, advanced 2 bytes/line)
;   CX = scanline counter (counts down from 200)
;   BL/BH = PAL_ODD (0x20) / PAL_EVEN (0x00) — Zone 1a flip-first
;   AH = pre-fetched R byte (Zone 2 bar burst)
;============================================================================
ss_render_frame:
  CLI
  CLD

  MOV SI,ss_palette_stream
  MOV DI,ss_scanline_colors
  MOV CX,200
  MOV DX,0xDE                   ;DX = PORT_REG_DATA permanently
  MOV BL,0x20                   ;PAL_ODD
  MOV BH,0x00                   ;PAL_EVEN

  ;=== ZONE 1a: IMAGE — lines 0 to 47 (flip-first E2-E7) ===
.z1a_image:
.z1a_wl:
  IN AL,0xDA
  TEST AL,0x01
  JNZ .z1a_wl
.z1a_wh:
  IN AL,0xDA
  TEST AL,0x01
  JZ .z1a_wh

  ; FLIP FIRST
  MOV AL,BL
  OUT 0xD9,AL
  XCHG BL,BH

  ; Write E2-E7 (12 bytes)
  MOV AL,0x44
  OUT 0xDD,AL

  PUSH CX
  MOV CX,12
  REP OUTSB
  POP CX

  MOV AL,0x80
  OUT 0xDD,AL

  ADD DI,2                      ;Advance past unused bar slot
  DEC CX
  CMP CX,200 - SS_FLIP_LINES
  JA .z1a_image

  ;=== ZONE 1b: IMAGE — lines 48 to 127 (no flip, colors stable) ===
  ; E2-E7 already correct in both banks from Zone 1a.
.z1b_idle:
.z1b_wl:
  IN AL,0xDA
  TEST AL,0x01
  JNZ .z1b_wl
.z1b_wh:
  IN AL,0xDA
  TEST AL,0x01
  JZ .z1b_wh

  ADD DI,2
  DEC CX
  CMP CX,200 - SS_BAR_START
  JA .z1b_idle

  ;=== ZONE 2: RASTER BARS — lines 128 to 173 (entry 0 only, 46 lines) ===
  ; E2-E7 persist with correct image colors (including green for STYX).
.z2_bar:
  ; Pre-fetch color into registers (during visible area — free time)
  MOV AH,[DI]                  ;AH = R (survives wait loop)
  MOV AL,[DI + 1]
  MOV [ss_bar_gb],AL            ;Save G|B in memory
  ADD DI,2

.z2_wl:
  IN AL,0xDA
  TEST AL,0x01
  JNZ .z2_wl
.z2_wh:
  IN AL,0xDA
  TEST AL,0x01
  JZ .z2_wh

  ; --- Critical HBLANK: pre-fetched burst, 1 memory read ---
  MOV AL,0x40
  OUT 0xDD,AL                  ;Open E0
  MOV AL,AH                    ;R from AH (preserved)
  OUT DX,AL                    ;R → 0xDE
  MOV AL,[ss_bar_gb]            ;G|B from saved byte
  OUT DX,AL                    ;G|B → 0xDE
  MOV AL,0x80
  OUT 0xDD,AL                  ;Close

  DEC CX
  CMP CX,200 - SS_BAR_END
  JA .z2_bar

  ;=== ZONE 3: IMAGE — lines 174 to 199 (no flip, colors stable) ===
  ; E2-E7 still correct from Zone 1a, no writes needed.
.z3_idle:
.z3_wl:
  IN AL,0xDA
  TEST AL,0x01
  JNZ .z3_wl
.z3_wh:
  IN AL,0xDA
  TEST AL,0x01
  JZ .z3_wh

  ADD DI,2
  LOOP .z3_idle

  ; --- End of frame: reset E0 to black, restore PAL_EVEN ---
  MOV AL,0x40
  OUT 0xDD,AL
  XOR AL,AL
  OUT DX,AL                    ;E0 R = 0
  OUT DX,AL                    ;E0 G|B = 0
  MOV AL,0x80
  OUT 0xDD,AL

  MOV AL,0x00                  ;PAL_EVEN
  OUT 0xD9,AL

  STI
  RET

;============================================================================
; ss_build_scanline_table — Pre-compute raster bar RGB pairs for 200 lines
;============================================================================
; Fills ss_scanline_colors (200 × 2 bytes). Image zone lines are black
; (0,0). Bar zone lines get the red/blue gradients at animated positions.
;============================================================================
ss_build_scanline_table:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH DI

  ; Fill entire table with black
  MOV DI,ss_scanline_colors
  XOR AX,AX
  MOV CX,200
.clear_loop:
  MOV [DI],AX
  ADD DI,2
  LOOP .clear_loop

  ; Draw both bars with hysteresis to prevent Z-order jitter.
  ; Only swap draw order when Y gap exceeds 2 scanlines.
  MOV AL,[ss_bar1_y]
  MOV AH,[ss_bar2_y]
  CMP byte [ss_bar_zorder],0
  JNE .check_swap_to_blue
  ; Currently blue on top — swap to red only if red_y + 2 < blue_y
  MOV DL,AL
  ADD DL,2
  CMP DL,AH
  JB .set_red_on_top
  JMP .draw_blue_top
.check_swap_to_blue:
  ; Currently red on top — swap to blue only if blue_y + 2 < red_y
  MOV DL,AH
  ADD DL,2
  CMP DL,AL
  JB .set_blue_on_top
  JMP .draw_red_top
.set_red_on_top:
  MOV byte [ss_bar_zorder],1
.draw_red_top:
  CALL .draw_blue_bar
  CALL .draw_red_bar
  JMP .bars_done
.set_blue_on_top:
  MOV byte [ss_bar_zorder],0
.draw_blue_top:
  CALL .draw_red_bar
  CALL .draw_blue_bar
.bars_done:

  POP DI
  POP CX
  POP BX
  POP AX
  RET

; --- Draw red bar at ss_bar1_y ---
.draw_red_bar:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH SI

  MOV AL,[ss_bar1_y]
  XOR AH,AH
  MOV BX,AX
  SHL BX,1                      ;×2 for word entries
  MOV SI,ss_red_gradient
  MOV CX,14

.dr_loop:
  CMP BX,200 * 2
  JAE .dr_skip
  MOV AX,[SI]
  MOV [ss_scanline_colors + BX],AX
.dr_skip:
  ADD BX,2
  ADD SI,2
  LOOP .dr_loop

  POP SI
  POP CX
  POP BX
  POP AX
  RET

; --- Draw blue bar at ss_bar2_y ---
.draw_blue_bar:
  PUSH AX
  PUSH BX
  PUSH CX
  PUSH SI

  MOV AL,[ss_bar2_y]
  XOR AH,AH
  MOV BX,AX
  SHL BX,1
  MOV SI,ss_blue_gradient
  MOV CX,14

.db_loop:
  CMP BX,200 * 2
  JAE .db_skip
  MOV AX,[SI]
  MOV [ss_scanline_colors + BX],AX
.db_skip:
  ADD BX,2
  ADD SI,2
  LOOP .db_loop

  POP SI
  POP CX
  POP BX
  POP AX
  RET

;============================================================================
; ss_wait_vblank — Synchronize to the start of the visible frame
;============================================================================
; 1. Wait for VBLANK START (bit 3 = 1)
; 2. Wait for VBLANK END (bit 3 = 0) — returns at line 0
;============================================================================
ss_wait_vblank:
.wv_wait_start:
  IN AL,0xDA
  TEST AL,0x08
  JNZ .wv_in_vblank
  JMP .wv_wait_start
.wv_in_vblank:
.wv_wait_end:
  IN AL,0xDA
  TEST AL,0x08
  JNZ .wv_wait_end
  RET

; === End of Startup BMP Screen code ===

codeend:

;============================================================================
;                        DATA SECTION
;============================================================================
; All game state variables, lookup tables, sprite bitmaps, string
; constants, and buffers. Variables use the original Styx naming
; convention: 'p' prefix + hex offset (from original binary).
;
; KEY VARIABLE GROUPS:
;   p46          = Error message strings
;   p79/p7b/p87  = CGA CRTC register tables
;   p95-pab      = Temporary variables for line drawing algorithm
;   pbo-pbf      = Keyboard pressed flags (0xFF = currently held)
;   pco          = Sound enabled flag (0xFF = on)
;   pc1          = Key event pending flag
;   pc3          = Last keyboard scancode received
;   pc9          = CGA snow wait skip (FFFFh on V6355D = no snow)
;   pcb          = VRAM write enable flag
;   pd3/pd4      = Direction state (0=R,2=D,4=L,6=U,1/3/5/7=diag)
;   pd5/pd7      = Joystick axis values
;   pdd          = Keyboard scancode dispatch table (29 entries)
;   p12e         = Shadow VRAM buffer (8000 bytes)
;   pc1_cga_colors = V6355D palette table (16 colors × 2 bytes)
;   p215o        = File I/O buffer (512 bytes, STYX.SCO)
;   p2354        = RLE-encoded title screen bitmap
;   p38bc-p38c5  = Sound state (mode, timer, counter, pulse)
;   p38ca-p38f6  = Enemy state arrays (2 enemies max)
;   p38f8        = Enemy trail ring buffer (128 words)
;   p39f8-p3ao8  = Tail segment state arrays
;   p3a1o        = Path recording buffer (358 words)
;   p3cf8/cfa    = Player x/y position
;   p3doo-p3d24  = Player movement state machine variables
;   p4cc4/p64a8  = General-purpose buffers (1000 words each)
;   p5c64/p5c7f  = Border pattern data
;   p5c9a-p5cd8  = Floating-point temp storage & constants
;   p6c78-p6c9a  = Joystick calibration & game control state
;   p6c9c        = High score initials entry buffer
;   p6cca-p6cf8  = High score table (10 entries × score + initials)
;   p6d26/d67/da8= Enemy sprite bitmaps (3 color variants, 9×7)
;   p6de9        = Diamond sprite (3×5)
;   p6dfa-p6e53  = Game text strings
;   p6e56-p6e86  = Sound envelope/frequency state
;   p6e88-p6eao  = Floating-point math constants
;   p6eb4-p6f2o  = Digit bitmaps 0-9 (each 2×5 pixels)
;   p6f2c-p74aa  = Letter bitmaps A-Z + symbols (each 5×7 pixels)
;   p74do        = Death flag, p74d2 = Lives, p74d4 = Level
;   p74da        = "PRESS ANY KEY" string
;   p751c        = C-style character type table (256 bytes)
;   p761e        = Hex digit string "0123456789ABCDEF"
;   bmp_*        = BMP background system variables (at end)
;============================================================================

section .data vstart=0 align=16 follows=.text

; === DATA.ASM ===

; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

; PUBLIC p79,p7b,p87,p95,p97,p99,p9b,p9c,p9d,p9e,p9f,pa1,pa3,pa5,pa7
; PUBLIC pa9,paa,pab,pac,pae,pbo,pb1,pb2,pb3,pb4,pb5,pb6,pb7,pb8,pb9,pba,pbb,pbc
; PUBLIC pbd,pbe,pbf,pco,pc1,pc2,pc3,pc4,pc6,pc7,pc9,pcb,pcd,pcf,pd1,pd3,pd4,pd5
; PUBLIC pd7,pd9,pdb,pdd,p12e,pc1_cga_colors,p2o6e,p2oa7,p215o,p2351,p2354,p38bc,p38be,p38co
; PUBLIC p38c2
; PUBLIC p38c3,p38c5,p38c7,p38ca,p38cc,p38ce,p38do,p38d2,p38d6,p38da,p38de,p38e2
; PUBLIC p38e6,p38ea,p38ee,p38f2,p38f6,p38f8,p39f8,p39fa,p39fc,p39fe,p3aoo,p3ao2
; PUBLIC p3ao4,p3ao6,p3ao8,p3aoc,p3aoe,p3a1o,p3cdc,p3ceo,p3ce4,p3ce8,p3cec,p3cfo
; PUBLIC p3cf2,p3cf4,p3cf6,p3cf8,p3cfa,p3cfc,p3cfe,p3doo,p3do2,p3do4,p3do6,p3do8
; PUBLIC p3doa,p3doc,p3doe,p3d1o,p3d12,p3d14,p3d16,p3d18,p3d1a,p3d1c,p3d1e,p3d2o
; PUBLIC p3d22,p3d24,p4cc4,p5c64,p5c7f,p5c9a,p5ca2,p5caa,p5cb2,p5cb4,p5cb6,p5cb8
; PUBLIC p5cbc,p5cbe,p5cco,p5cc2,p5cc4,p5cc6,p5cc8,p5cca,p5ccc,p5cce,p5cdo,p5cd2
; PUBLIC p5cd4,p5cd6,p5cd8,p64a8,p6c78,p6c7a,p6c7c,p6c7e,p6c8o,p6c82,p6c84,p6c86
; PUBLIC p6c88,p6c8a,p6c8c,p6c8e,p6c9o,p6c92,p6c94,p6c96,p6c98,p6c9a,p6c9c,p6ca6
; PUBLIC p6cca,p6ccc,p6cce,p6cdo,p6cf6,p6cf8,p6cfa,p6d26,p6d67,p6da8,p6de9,p6dfa
; PUBLIC p6dfe
; PUBLIC p6eod,p6e17,p6e18,p6e2o,p6e28,p6e34,p6e37,p6e39,p6e44,p6e4d,p6e53,p6e56
; PUBLIC p6e5a,p6e5c,p6e5e,p6e6o,p6e62,p6e64,p6e66,p6e68,p6e6a,p6e6c,p6e6e,p6e7o
; PUBLIC p6e72,p6e74,p6e8o,p6e82,p6e84,p6e86,p6e88,p6e9o,p6e98,p6eao,p6eb4,p6eco
; PUBLIC p6ecc,p6ed8,p6ee4,p6efo,p6efc,p6fo8,p6f14,p6f2o,p6f2c,p6f51,p6f76,p6f9b
; PUBLIC p6fco,p6fe5,p7ooa,p7o2f,p7o54,p7o79,p7o9e,p7oc3,p7oe8,p71od,p7132,p7157
; PUBLIC p717c,p71a1,p71c6,p71eb,p721o,p7235,p725a,p727f,p72a4,p72c9,p72ee,p7313
; PUBLIC p7338,p735d,p7382,p73a7,p73cc,p73f1,p7416,p743b,p746o,p7485,p74aa,p74do
; PUBLIC p74d2,p74d4,p74d6,p74d8,p74da,p74eb,p74fc,p751c,p761e,p763o
; PUBLIC p,p2,p4,p46


;--- Misc pointers (stack/segment setup temps) ---
p:
  DW 0
p2:
  DW 0
p4:
  DW 0

; p6:
   times 0x40 DB 0

;--- Error message strings (debug/diagnostic) ---
p46:
  DB "error in sine    %d  ",10,13,0
  DB "error in sine value gen ",10,13,0
;--- CGA CRTC register initialization tables ---
; p79/p7b: 80-column mode registers; p87: 40-column mode registers
p79:
  DB 113,80
p7b:
  DB 89,10,124,6,100,112,2,1,32,0,0,0
p87:
  DB 56,40,45,10,127,6,100,112,2,1,32,0,0,0
;--- Line drawing algorithm temporaries (p95-pab) ---
p95:
  DW 0
p97:
  DW 0
p99:
  DW 0
p9b:
  DB 0
p9c:
  DB 0
p9d:
  DB 0
p9e:
  DB 0
p9f:
  DW 0
pa1:
  DW 0
pa3:
  DW 0
pa5:
  DW 0
pa7:
  DW 0
pa9:
  DB 0
paa:
  DB 0
pab:
  DB 0

;  pac:
;    DB 0,0
;  pae:
;    DB 0,0

;--- Keyboard state flags (pbo-pbf) ---
; Each byte: 0x00 = released, 0xFF = currently pressed
; Mapped from INT 9 handler via scancode dispatch
pbo:
  DB 0
pb1:
  DB 0
pb2:
  DB 0
pb3:
  DB 0
pb4:
  DB 0
pb5:
  DB 0
pb6:
  DB 0
pb7:
  DB 0
pb8:
  DB 0
pb9:
  DB 0
pba:
  DB 0
pbb:
  DB 0
pbc:
  DB 0
pbd:
  DB 0
pbe:
  DB 0
pbf:
  DB 255
;--- Sound enabled flag: 0xFF = sound on, 0x00 = muted ---
pco:
  DB 255
pc1:
  DB 0
pc2:
  DB 89
pc3:
  DB 0

;  pc4:
;    DB 0,0

pc6:
  DB 0
pc7:
  DW 0
pc9:
  DW -1             ;Non-zero = skip CGA snow wait (V6355D has no snow)
pcb:
  DW -1
pcd:
  DW 0
pcf:
  DW 0
pd1:
  DW 0
;--- Direction / input state ---
; pd3: current direction (0=right,2=down,4=left,6=up,odd=diagonal)
; pd4: previous direction
; pd5/pd7: joystick X/Y axis raw values
; pd9/pdb: joystick button / misc input state
pd3:
  DB 0
pd4:
  DB 0
pd5:
  DW 0
pd7:
  DW 0
pd9:
  DW 0
pdb:
  DW 0

;--- INT 9 keyboard scancode dispatch table ---
; 29 entries × 3 bytes: [scancode DB] [handler DW]
; Make codes (bit 7=0) set flags; break codes (bit 7=1) clear them.
pdd:
  DB 0x4b
  DW od7o
  DB 0xcb
  DW od8d
  DB 0x4d
  DW odb7
  DB 0xcd
  DW odd4
  DB 0x48
  DW odfe
  DB 0xc8
  DW oeoe
  DB 0x50
  DW oe1e
  DB 0xd0
  DW oe2e
  DB 0x49
  DW oe3e
  DB 0xc9
  DW oe4e
  DB 0x47
  DW oe5e
  DB 0xc7
  DW oe6e
  DB 0x51
  DW oe7e
  DB 0xd1
  DW oe8e
  DB 0x4f
  DW oe9e
  DB 0xcf
  DW oeae
  DB 0x3b
  DW oebd
  DB 0xbb
  DW oebd
  DB 0x1d
  DW oecf
  DB 0x9d
  DW oed7
  DB 0x38
  DW oedd
  DB 0xb8
  DW oee5
  DB 0x53
  DW oeeb
  DB 0xd3
  DW oef3
  DB 0x43
  DW oef9
  DB 0xc3
  DW ofoc
  DB 0x1
  DW of12
  DB 0x39
  DW oebe
  DB 0xb9
  DW oec9
;--- Shadow VRAM buffer (8000 bytes) ---
; All game rendering writes here first, then o5c3 copies to real VRAM.
; Layout mirrors V6355D interlaced format:
;   Bytes 0-3999:    even scanlines (rows 0,2,4,...198)
;   Bytes 4000-7999:  odd scanlines (rows 1,3,5,...199)
;   Each row = 80 bytes = 160 pixels × 4 bits/pixel
p12e:
  times 8000 DB 0

;--- PC1 V6355D CGA palette table (16 colors x 2 bytes = 32 bytes) ---
;    Byte 1: Red (bits 0-2, values 0-7)
;    Byte 2: Green (bits 4-6) | Blue (bits 0-2)
pc1_cga_colors:
  DB 0x0,0x0    ;0:  Black
  DB 0x0,0x5    ;1:  Blue
  DB 0x0,0x50    ;2:  Green
  DB 0x0,0x55    ;3:  Cyan
  DB 0x5,0x0    ;4:  Red
  DB 0x5,0x5    ;5:  Magenta
  DB 0x5,0x20    ;6:  Brown
  DB 0x5,0x55    ;7:  Light Gray
  DB 0x2,0x22    ;8:  Dark Gray
  DB 0x2,0x27    ;9:  Light Blue
  DB 0x2,0x72    ;10: Light Green
  DB 0x2,0x77    ;11: Light Cyan
  DB 0x7,0x22    ;12: Light Red
  DB 0x7,0x27    ;13: Light Magenta
  DB 0x7,0x70    ;14: Yellow
  DB 0x7,0x77    ;15: White

;  p2o6e:
;    DB 10,13,"This program requires the color graphics adapter card $"
;  p2oa7:
;    DB 10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13
;    DB "                    Please turn on the monitor connected to",10,13,10,13
;    DB "                    to your Color/Graphics display adapter. ",10,13,10,13
;    DB 10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,10,13,"$"
;  p214f:
;    DB 0

;--- File I/O buffer (512 bytes) ---
; Used for reading/writing STYX.SCO high score file
p215o:
  times 512 DB 0

;  p235o:
;    DB 0
;  p2351:
;    DB 0,100,21

;--- RLE-encoded title screen bitmap ---
; Decoded by o1142 to render the STYX logo on the attract screen.
; Format: 254,count,value = repeat 'value' 'count' times;
;         other bytes = literal pixel data.
p2354:
  DB 254,48,0,10,254,26,170
  DB 128,254,52,0,160,254,26,170,168,254,52,0,170,254,79,0
  DB 170,132,254,26,0,16,254,51,0,170,132,254,26,0,16,254
  DB 51,0,170,132,254,26,0,16,254,51,0,170,132,254,26,0
  DB 16,254,51,0,170,132,254,26,0,16,254,51,0,170,132,254
  DB 26,0,16,254,51,0,170,132,254,26,0,16,254,51,0,170
  DB 132,254,26,0,16,254,51,0,170,132,254,26,0,16,254,51
  DB 0,170,132,254,26,0,16,254,51,0,170,132,254,26,0,16
  DB 254,51,0,170,132,254,26,0,16,254,51,0,170,132,254,26
  DB 0,16,254,20,0,62,170,170,171,250,170,170,190,170,170,171
  DB 234,170,170,190,254,3,170,234,170,170,174,254,3,170,234,170
  DB 170,186,170,168,170,132,254,26,0,19,252,254,17,0,15,254
  DB 4,255,254,3,170,250,170,170,171,234,170,170,171,254,3,170
  DB 174,254,3,170,186,254,3,170,234,170,170,171,255,252,170,132
  DB 254,26,0,19,252,254,15,0,15,254,4,255,234,170,170,171
  DB 234,170,170,171,234,254,3,170,234,254,3,170,186,254,3,170
  DB 186,254,3,170,191,254,3,255,240,0,170,132,254,26,0,16
  DB 254,14,0,3,254,4,255,250,254,3,170,175,254,3,170,171
  DB 234,254,3,170,190,254,3,170,171,254,4,170,254,4,255,252
  DB 254,3,0,3,0,170,132,254,26,0,19,255,254,11,0,3
  DB 250,254,3,170,175,234,254,3,170,190,254,3,170,171,234,254
  DB 3,170,175,254,4,170,175,254,4,255,192,254,3,0,12,254
  DB 4,0,192,170,132,254,26,0,16,254,11,0,254,39,255,252
  DB 170,132,254,26,0,19,255,255,192,254,6,0,63,254,5,255
  DB 234,254,3,170,175,234,254,4,170,250,254,4,170,191,254,4
  DB 255,252,254,4,0,3,254,5,0,192,254,4,0,170,132,254
  DB 26,0,16,254,7,0,15,254,42,255,252,170,132,254,26,0
  DB 19,255,255,192,0,0,3,245,254,4,85,95,254,5,255,250
  DB 254,5,170,254,6,255,192,254,4,0,3,254,5,0,12,254
  DB 5,0,48,254,4,0,170,132,254,26,0,16,15,240,0,3
  DB 254,46,255,252,170,132,254,26,0,19,255,255,192,1,254,4
  DB 85,127,254,5,85,95,254,6,255,240,254,5,0,12,254,6
  DB 0,192,254,5,0,48,254,5,0,15,254,3,255,252,170,132
  DB 254,26,0,16,254,3,0,1,85,85,87,245,254,5,85,127
  DB 254,6,255,240,254,5,0,3,254,6,0,12,254,6,0,192
  DB 254,5,0,3,254,3,255,252,170,132,254,26,0,19,192,0
  DB 0,1,85,127,254,6,85,254,7,255,240,254,6,0,240,254
  DB 6,0,192,254,6,0,254,7,255,254,3,85,84,170,132,254
  DB 26,0,16,0,252,0,3,245,254,5,85,87,254,7,255,240
  DB 254,6,0,60,254,6,0,3,254,6,0,3,254,7,255,213
  DB 85,85,84,170,132,254,26,0,16,254,3,0,1,254,5,85
  DB 95,254,7,255,252,254,6,0,3,254,7,0,48,254,6,0
  DB 3,254,7,255,245,85,85,84,170,132,254,26,0,16,254,3
  DB 0,1,254,4,85,125,254,7,85,127,254,7,255,192,254,7
  DB 0,192,254,6,0,15,254,7,255,245,85,85,84,170,132,254
  DB 26,0,16,254,3,0,1,85,85,87,245,254,7,85,127,254
  DB 7,255,252,254,7,0,12,254,7,0,15,254,7,255,253,85
  DB 85,84,170,132,254,26,0,19,254,3,0,1,85,95,213,254
  DB 7,85,127,254,8,255,254,8,0,192,254,7,0,63,254,7
  DB 255,253,85,85,84,170,132,254,26,0,16,15,192,0,1,127
  DB 254,8,85,127,254,8,255,192,254,7,0,3,254,8,0,63
  DB 254,8,255,85,85,84,170,132,254,26,0,16,0,0,192,3
  DB 254,46,255,252,170,132,254,26,0,19,255,255,192,1,254,7
  DB 85,125,254,8,85,95,254,9,255,254,9,0,192,254,8,0
  DB 255,255,252,170,132,254,26,0,16,254,3,0,1,254,6,85
  DB 95,254,8,85,87,254,9,255,252,254,8,0,3,254,9,0
  DB 63,255,252,170,132,254,26,0,16,254,3,0,1,254,5,85
  DB 95,254,9,85,127,254,9,255,192,254,8,0,3,254,9,0
  DB 15,255,252,170,132,254,26,0,16,254,3,0,1,254,4,85
  DB 95,254,9,85,95,254,9,255,252,254,9,0,12,254,9,0
  DB 15,255,252,170,132,254,26,0,16,254,3,0,1,254,3,85
  DB 95,254,9,85,87,254,10,255,240,254,9,0,12,254,9,0
  DB 3,255,252,170,132,254,26,0,16,254,3,0,1,85,85,95
  DB 254,10,85,254,11,255,254,10,0,48,254,9,0,3,0,0
  DB 170,132,254,26,0,16,60,0,0,1,85,95,254,10,85,127
  DB 254,10,255,252,254,10,0,48,254,10,0,192,0,170,132,254
  DB 26,0,16,0,60,0,1,95,254,10,85,87,254,11,255,192
  DB 254,10,0,192,254,10,0,48,0,170,132,254,26,0,16,254
  DB 3,0,3,254,11,85,254,11,255,252,254,11,0,192,254,10
  DB 0,48,0,170,132,254,26,0,16,254,3,0,1,254,10,85
  DB 127,254,11,255,240,254,10,0,3,254,11,0,12,0,170,132
  DB 254,26,0,16,254,3,0,1,254,9,85,95,254,12,255,254
  DB 11,0,3,254,11,0,3,0,170,132,254,26,0,16,254,3
  DB 0,1,254,9,85,254,12,255,240,254,11,0,12,254,11,0
  DB 3,0,170,132,254,26,0,16,254,3,0,1,254,8,85,127
  DB 254,12,255,192,254,11,0,12,254,12,0,192,170,132,254,26
  DB 0,16,254,3,0,3,254,46,255,240,170,132,254,26,0,19
  DB 255,255,192,1,254,6,85,87,213,254,12,85,127,254,12,255
  DB 240,254,12,0,48,170,132,254,26,0,16,254,3,0,1,254
  DB 6,85,117,254,12,85,87,254,13,255,192,254,12,0,12,170
  DB 132,254,26,0,16,254,3,0,1,254,5,85,93,254,13,85
  DB 127,254,13,255,192,254,12,0,12,10,132,254,26,0,16,254
  DB 3,0,1,254,4,85,87,254,14,85,254,14,255,254,13,0
  DB 3,0,132,254,26,0,16,254,3,0,1,254,4,85,245,254
  DB 13,85,95,254,14,255,254,13,0,3,0,5,254,26,85,80
  DB 254,3,0,1,254,3,85,125,254,14,85,254,14,255,252,254
  DB 14,0,192,254,13,0,12,254,13,0,3,192,0,0,1,85
  DB 85,87,254,14,85,87,254,14,255,252,254,14,0,48,254,14
  DB 0,192,254,13,0,15,0,0,1,85,85,213,254,14,85,127
  DB 254,14,255,240,254,14,0,48,254,14,0,48,254,14,0,48
  DB 0,1,85,125,254,15,85,254,15,255,240,254,14,0,12,254
  DB 14,0,3,254,15,0,192,1,95,254,15,85,95,254,15,255
  DB 192,254,14,0,3,254,15,0,48,254,15,0,1,213,254,15
  DB 85,254,16,255,192,254,14,0,3,254,15,0,3,254,15,0
  DB 1,254,15,85,95,254,16,255,254,16,0,192,254,15,0,192
  DB 254,14,0,1,254,15,85,127,254,16,255,254,16,0,48,254
  DB 15,0,12,254,14,0,2,254,78,170,160,2,254,78,170,160
  DB 2,254,11,170,169,254,13,85,90,170,170,169,254,11,85,254
  DB 3,170,165,106,254,8,170,165,106,170,170,169,90,254,7,170
  DB 169,90,254,10,170,160,2,254,10,170,169,254,15,85,170,170
  DB 149,254,11,85,90,170,170,85,85,254,7,170,169,85,86,170
  DB 170,149,85,106,254,6,170,85,85,254,10,170,160,2,254,10
  DB 170,149,254,15,85,106,170,254,12,85,86,170,169,85,85,90
  DB 254,6,170,149,85,85,170,170,85,85,86,254,5,170,165,85
  DB 85,106,254,9,170,160,2,254,10,170,254,16,85,170,170,149
  DB 254,11,85,90,170,170,254,3,85,254,5,170,169,85,85,86
  DB 170,170,149,85,85,106,254,4,170,254,3,85,254,10,170,160
  DB 2,254,9,170,169,254,15,85,90,170,170,169,254,11,85,254
  DB 3,170,149,85,85,90,254,4,170,149,85,85,90,170,170,165
  DB 85,85,86,254,3,170,165,85,85,86,254,10,170,160,2,254
  DB 9,170,165,85,85,254,21,170,149,85,90,254,7,170,169,254
  DB 3,85,254,3,170,169,254,3,85,254,4,170,254,3,85,106
  DB 170,170,254,3,85,106,254,10,170,160,2,254,9,170,165,85
  DB 86,254,21,170,149,85,90,254,8,170,149,85,85,90,170,170
  DB 149,85,85,90,254,4,170,165,85,85,86,170,165,85,85,86
  DB 254,11,170,160,2,254,9,170,165,85,85,254,21,170,149,85
  DB 90,254,8,170,169,254,3,85,170,169,254,3,85,254,6,170
  DB 254,3,85,106,254,3,85,106,254,11,170,160,2,254,9,170
  DB 169,254,11,85,106,254,11,170,149,85,90,254,9,170,149,85
  DB 85,90,149,85,85,90,254,6,170,165,254,5,85,86,254,12
  DB 170,160,2,254,10,170,254,12,85,106,254,10,170,149,85,90
  DB 254,9,170,169,254,6,85,254,8,170,254,5,85,106,254,12
  DB 170,160,2,254,10,170,149,254,11,85,86,254,10,170,149,85
  DB 90,254,10,170,149,254,4,85,90,254,8,170,165,254,3,85
  DB 86,254,13,170,160,2,254,10,170,169,254,12,85,254,10,170
  DB 149,85,90,254,10,170,169,254,4,85,254,9,170,254,5,85
  DB 106,254,12,170,160,2,254,11,170,169,254,11,85,106,254,9
  DB 170,149,85,90,254,11,170,149,85,85,90,254,8,170,165,254
  DB 5,85,86,254,12,170,160,2,254,21,170,85,85,90,254,9
  DB 170,149,85,90,254,11,170,169,85,85,254,9,170,254,3,85
  DB 106,254,3,85,106,254,11,170,160,2,254,21,170,149,85,90
  DB 254,9,170,149,85,90,254,11,170,169,85,85,254,8,170,165
  DB 85,85,86,170,165,85,85,86,254,11,170,160,2,254,21,170
  DB 85,85,90,254,9,170,149,85,90,254,11,170,169,85,85,254
  DB 8,170,254,3,85,106,170,170,254,3,85,106,254,10,170,160
  DB 2,254,7,170,149,254,15,85,106,254,9,170,149,85,90,254
  DB 11,170,169,85,85,254,7,170,165,85,85,86,254,3,170,165
  DB 85,85,86,254,10,170,160,2,254,6,170,169,254,16,85,254
  DB 10,170,149,85,90,254,11,170,169,85,85,254,7,170,149,85
  DB 85,106,254,4,170,254,3,85,254,10,170,160,2,254,6,170
  DB 165,254,15,85,86,254,10,170,149,85,90,254,11,170,169,85
  DB 85,254,7,170,85,85,86,254,5,170,165,85,85,106,254,9
  DB 170,160,2,254,6,170,169,254,15,85,106,254,10,170,165,85
  DB 106,254,12,170,85,86,254,7,170,149,85,106,254,6,170,85
  DB 85,254,10,170,160,2,254,7,170,149,254,13,85,106,254,12
  DB 170,86,254,13,170,165,106,254,7,170,169,90,254,7,170,169
  DB 90,254,10,170,160,2,254,78,170,160,3,254,78,255,240,254
  DB 244,0,255,192,254,77,0,48,0,3,254,3,0,240,15,0
  DB 240,3,192,254,6,0,3,192,254,7,0,60,0,15,0,3
  DB 192,254,3,0,3,240,15,192,254,4,0,48,60,3,192,254
  DB 32,0,192,63,0,192,0,0,60,51,192,192,254,8,0,3
  DB 192,254,9,0,15,0,3,192,254,3,0,15,0,0,192,254
  DB 4,0,240,0,3,192,254,31,0,3,3,0,0,48,0,0
  DB 60,51,195,0,3,192,0,252,3,192,0,240,15,192,0,252
  DB 3,252,3,192,0,60,0,15,0,3,192,254,4,0,255,0
  DB 0,15,0,240,0,240,0,3,192,0,60,3,192,48,3,192
  DB 48,0,15,192,240,15,3,192,254,16,0,3,3,0,0,48
  DB 0,0,15,192,255,0,3,192,0,240,0,240,3,192,3,192
  DB 0,240,0,240,0,240,0,60,0,15,0,3,192,254,5,0
  DB 255,0,60,0,60,0,240,0,3,192,0,15,12,240,192,0
  DB 0,252,0,15,0,0,60,0,240,254,4,0,60,0,255,0
  DB 255,0,255,254,6,0,192,63,0,192,0,0,15,192,252,0
  DB 3,192,0,240,0,240,3,192,3,192,0,240,0,240,0,240
  DB 0,60,0,15,0,3,192,254,3,0,3,0,0,240,60,0
  DB 60,0,240,0,3,192,0,3,240,63,0,0,240,60,0,15
  DB 0,0,60,254,6,0,60,3,254,3,195,192,3,192,254,5
  DB 0,48,0,3,254,3,0,3,0,48,0,3,192,0,240,0
  DB 240,3,192,3,192,0,240,0,240,0,240,0,60,0,15,0
  DB 3,192,254,3,0,3,192,0,240,60,0,60,0,240,0,3
  DB 192,192,3,240,63,0,3,192,60,0,15,0,0,60,0,48
  DB 254,4,0,60,0,3,195,195,192,3,192,254,6,0,255,192
  DB 254,3,0,3,0,48,0,63,252,15,255,15,255,0,63,195
  DB 255,15,255,15,255,15,255,3,255,192,255,240,63,252,254,3
  DB 0,3,3,252,0,3,255,0,15,255,0,0,63,0,0,192
  DB 12,0,0,255,15,192,255,240,0,3,252,254,4,0,3,255
  DB 192,252,0,255,0,255,254,0,0,254,67,0,130,254,26,170
  DB 160,254,52,0,168,42,254,26,170,254,52,0,170,133,254,26
  DB 85,80,254,51,0,170,132,254,26,0,16,254,51,0,170,132
  DB 254,26,0,16,254,51,0,170,132,254,26,0,16,254,51,0
  DB 170,132,254,26,0,16,254,51,0,170,132,254,26,0,16,254
  DB 51,0,170,132,254,26,0,16,254,51,0,170,132,254,26,0
  DB 16,254,51,0,170,132,254,26,0,16,254,51,0,170,132,254
  DB 26,0,16,254,51,0,170,132,254,26,0,16,254,51,0,170
  DB 132,254,26,0,16,254,51,0,170,132,254,26,0,16,254,20
  DB 0,3,254,29,255,252,170,132,254,26,0,19,255,255,192,254
  DB 16,0,63,254,30,255,252,170,132,254,26,0,19,255,255,192
  DB 254,14,0,15,254,32,255,252,170,132,254,26,0,19,255,255
  DB 192,254,12,0,3,254,34,255,252,170,132,254,26,0,19,255
  DB 255,192,254,10,0,15,254,36,255,252,170,132,254,26,0,19
  DB 255,255,192,254,9,0,250,254,3,170,171,250,254,3,170,175
  DB 234,254,3,170,190,254,4,170,186,254,4,170,191,254,4,255
  DB 254,4,0,3,254,4,0,48,170,132,254,26,0,19,192,254
  DB 9,0,63,254,5,255,254,4,170,190,254,4,170,175,254,4
  DB 170,175,254,5,255,254,4,0,3,254,4,0,3,254,5,0
  DB 170,132,254,26,0,16,0,63,192,254,5,0,15,254,5,255
  DB 250,254,4,170,250,254,4,170,175,254,4,170,171,254,5,255
  DB 240,254,4,0,12,254,5,0,192,254,4,0,170,132,254,26
  DB 0,16,254,6,0,15,245,254,4,85,127,254,5,255,234,254
  DB 4,170,175,254,5,255,240,254,5,0,192,254,4,0,12,254
  DB 5,0,48,254,4,0,170,132,254,26,0,19,240,254,3,0
  DB 3,253,254,4,85,87,254,6,255,254,5,170,175,254,5,255
  DB 252,254,5,0,12,254,5,0,48,254,5,0,48,254,4,0
  DB 170,132,254,26,0,16,0,15,192,1,254,5,85,255,254,5
  DB 85,127,254,6,255,254,5,0,3,192,254,5,0,48,254,5
  DB 0,48,254,5,0,15,254,3,255,252,170,132,254,26,0,16
  DB 254,3,0,1,254,3,85,95,213,254,4,85,87,254,7,255
  DB 254,6,0,240,254,5,0,3,254,6,0,192,254,5,0,15
  DB 254,3,255,252,170,132,254,26,0,16,254,3,0,3,254,46
  DB 255,252,170,132,254,26,0,19,255,255,192,1,95,213,254,5
  DB 85,127,254,7,255,254,6,0,3,254,7,0,192,254,5,0
  DB 3,254,7,255,213,85,85,84,170,132,254,26,0,16,0,3
  DB 192,1,254,6,85,254,8,255,192,254,6,0,192,254,6,0
  DB 12,254,6,0,3,254,7,255,213,85,85,84,170,132,254,26
  DB 0,16,254,3,0,3,254,46,255,252,170,132,254,26,0,19
  DB 255,255,192,1,254,3,85,95,213,254,6,85,87,254,8,255
  DB 254,7,0,3,254,7,0,15,254,7,255,245,85,85,84,170
  DB 132,254,26,0,16,254,3,0,1,85,85,125,254,7,85,87
  DB 254,8,255,192,254,7,0,48,254,7,0,63,254,7,255,253
  DB 85,85,84,170,132,254,26,0,16,240,0,0,1,85,245,254
  DB 7,85,87,254,8,255,240,254,7,0,3,254,8,0,63,254
  DB 8,255,85,85,84,170,132,254,26,0,16,0,63,0,3,213
  DB 254,7,85,87,254,9,255,254,8,0,12,254,8,0,254,9
  DB 255,85,85,84,170,132,254,26,0,16,254,3,0,1,254,7
  DB 85,87,213,254,7,85,87,254,9,255,192,254,8,0,192,254
  DB 8,0,255,255,252,170,132,254,26,0,16,254,3,0,1,254
  DB 7,85,213,254,8,85,127,254,9,255,254,8,0,3,254,9
  DB 0,63,255,252,170,132,254,26,0,16,254,3,0,1,254,6
  DB 85,245,254,8,85,95,254,9,255,240,254,8,0,3,254,9
  DB 0,63,255,252,170,132,254,26,0,16,254,3,0,1,254,5
  DB 85,245,254,8,85,87,254,10,255,254,9,0,12,254,9,0
  DB 15,255,252,170,132,254,26,0,16,254,3,0,1,254,4,85
  DB 245,254,9,85,254,10,255,252,254,9,0,12,254,9,0,15
  DB 255,252,170,132,254,26,0,16,254,3,0,3,254,46,255,252
  DB 170,132,254,26,0,19,255,255,192,1,85,85,245,254,9,85
  DB 87,254,10,255,252,254,10,0,48,254,10,0,192,0,170,132
  DB 254,26,0,16,3,192,0,1,85,245,254,10,85,254,11,255
  DB 240,254,10,0,192,254,10,0,192,0,170,132,254,26,0,16
  DB 0,3,192,1,245,254,10,85,127,254,11,255,254,11,0,192
  DB 254,10,0,48,0,170,132,254,26,0,16,254,3,0,1,254
  DB 10,85,87,254,11,255,240,254,10,0,3,254,11,0,12,0
  DB 170,132,254,26,0,16,254,3,0,1,254,10,85,254,12,255
  DB 192,254,10,0,3,254,11,0,12,0,170,132,254,26,0,16
  DB 254,3,0,1,254,9,85,127,254,11,255,252,254,11,0,12
  DB 254,11,0,3,0,170,132,254,26,0,16,254,3,0,1,254
  DB 8,85,95,254,12,255,240,254,11,0,12,254,11,0,3,0
  DB 170,132,254,26,0,16,254,3,0,1,254,7,85,87,254,13
  DB 255,254,12,0,48,254,12,0,192,170,132,254,26,0,16,254
  DB 3,0,1,254,7,85,117,254,12,85,127,254,12,255,240,254
  DB 12,0,48,170,132,254,26,0,16,254,3,0,1,254,6,85
  DB 93,254,13,85,254,13,255,192,254,12,0,48,170,132,254,26
  DB 0,16,254,3,0,1,254,5,85,87,213,254,12,85,95,254
  DB 13,255,192,254,12,0,12,42,132,254,26,0,16,254,3,0
  DB 1,254,5,85,245,254,13,85,254,14,255,254,13,0,3,2
  DB 132,254,26,0,16,254,3,0,1,254,4,85,93,254,13,85
  DB 87,254,14,255,254,13,0,3,0,4,254,26,0,16,254,3
  DB 0,1,254,3,85,87,254,14,85,127,254,13,255,252,254,14
  DB 0,192,254,31,0,1,254,3,85,213,254,14,85,254,14,255
  DB 252,254,14,0,192,254,13,0,3,254,14,0,48,0,0,1
  DB 85,85,125,254,14,85,95,254,14,255,240,254,14,0,48,254
  DB 14,0,192,254,14,0,192,0,1,85,87,254,15,85,254,15
  DB 255,240,254,14,0,12,254,14,0,12,254,14,0,15,0,1
  DB 85,213,254,14,85,87,254,15,255,192,254,14,0,12,254,15
  DB 0,192,254,15,0,1,117,254,15,85,127,254,15,255,192,254
  DB 14,0,3,254,15,0,12,254,15,0,3,254,15,85,87,254
  DB 16,255,254,16,0,192,254,15,0,192,254,14,0,1,254,15
  DB 85,95,254,16,255,254,16,0,192,254,15,0,48,254,14,0
  DB 3,254,78,255,240,2,254,78,170,160,2,254,78,170,160,2
  DB 254,11,170,149,254,14,85,170,170,149,254,11,85,90,170,170
  DB 85,86,254,8,170,85,86,170,170,149,85,254,7,170,149,85
  DB 254,10,170,160,2,254,10,170,165,254,15,85,106,170,254,12
  DB 85,86,170,169,85,85,106,254,6,170,165,85,85,170,170,85
  DB 85,90,254,5,170,169,85,85,106,254,9,170,160,2,254,10
  DB 170,254,16,85,106,170,254,12,85,86,170,169,85,85,86,254
  DB 6,170,254,3,85,170,170,254,3,85,254,5,170,149,85,85
  DB 106,254,9,170,160,2,254,9,170,169,254,16,85,170,170,149
  DB 254,11,85,90,170,170,254,3,85,106,254,4,170,165,85,85
  DB 86,170,170,149,85,85,90,254,3,170,169,254,3,85,254,10
  DB 170,160,2,254,9,170,165,85,85,106,254,20,170,149,85,90
  DB 254,7,170,165,85,85,86,254,4,170,254,3,85,106,170,170
  DB 169,254,3,85,254,3,170,149,85,85,90,254,10,170,160,2
  DB 254,9,170,165,85,86,254,21,170,149,85,90,254,8,170,254
  DB 3,85,106,170,170,165,85,85,86,254,4,170,149,85,85,90
  DB 170,169,254,3,85,254,11,170,160,2,254,9,170,165,85,86
  DB 254,21,170,149,85,90,254,8,170,165,85,85,86,170,170,254
  DB 3,85,106,254,4,170,169,254,3,85,170,149,85,85,90,254
  DB 11,170,160,2,254,9,170,165,85,85,106,254,20,170,149,85
  DB 90,254,9,170,254,3,85,106,165,85,85,86,254,6,170,149
  DB 85,85,89,254,3,85,254,12,170,160,2,254,9,170,169,254
  DB 11,85,86,254,11,170,149,85,90,254,9,170,165,85,85,86
  DB 254,3,85,106,254,6,170,169,254,5,85,90,254,12,170,160
  DB 2,254,10,170,254,12,85,90,254,10,170,149,85,90,254,10
  DB 170,254,5,85,86,254,8,170,149,254,4,85,254,13,170,160
  DB 2,254,10,170,165,254,12,85,254,10,170,149,85,90,254,10
  DB 170,165,254,4,85,106,254,8,170,149,254,4,85,254,13,170
  DB 160,2,254,11,170,149,254,11,85,106,254,9,170,149,85,90
  DB 254,11,170,254,3,85,86,254,8,170,169,254,5,85,90,254
  DB 12,170,160,2,254,20,170,169,85,85,90,254,9,170,149,85
  DB 90,254,11,170,165,85,85,106,254,8,170,149,85,85,89,254
  DB 3,85,254,12,170,160,2,254,21,170,149,85,90,254,9,170
  DB 149,85,90,254,11,170,169,85,85,254,8,170,169,254,3,85
  DB 170,149,85,85,90,254,11,170,160,2,254,21,170,149,85,90
  DB 254,9,170,149,85,90,254,11,170,169,85,85,254,8,170,149
  DB 85,85,90,170,169,254,3,85,254,11,170,160,2,254,20,170
  DB 169,85,85,90,254,9,170,149,85,90,254,11,170,169,85,85
  DB 254,7,170,169,254,3,85,254,3,170,149,85,85,90,254,10
  DB 170,160,2,254,6,170,169,254,16,85,106,254,9,170,149,85
  DB 90,254,11,170,169,85,85,254,7,170,149,85,85,90,254,3
  DB 170,169,254,3,85,254,10,170,160,2,254,6,170,165,254,16
  DB 85,254,10,170,149,85,90,254,11,170,169,85,85,254,7,170
  DB 254,3,85,254,5,170,149,85,85,106,254,9,170,160,2,254
  DB 6,170,165,254,15,85,90,254,10,170,149,85,90,254,11,170
  DB 169,85,85,254,7,170,85,85,90,254,5,170,169,85,85,106
  DB 254,9,170,160,2,254,6,170,169,254,14,85,86,254,11,170
  DB 165,85,106,254,12,170,85,86,254,7,170,149,85,254,7,170
  DB 149,85,254,10,170,160,2,254,78,170,160,2,254,78,170,160
  DB 254,0,0,254,67,0,15,0,60,0,0,15,252,15,15,252
  DB 3,192,254,6,0,63,192,254,7,0,60,0,255,0,63,192
  DB 254,4,0,63,240,192,254,4,0,15,240,3,192,254,32,0
  DB 192,0,0,192,0,0,240,15,0,240,254,8,0,3,192,254
  DB 9,0,15,0,3,192,254,3,0,15,0,3,192,254,4,0
  DB 240,60,3,192,254,31,0,3,0,192,192,48,0,0,60,51
  DB 195,192,63,192,15,255,252,0,0,15,255,192,15,255,252,3
  DB 252,0,3,252,0,15,0,3,192,254,3,0,3,192,0,192
  DB 0,255,192,15,255,0,63,255,3,255,195,195,255,0,255,192
  DB 0,255,255,192,3,255,254,17,0,3,3,0,0,48,0,0
  DB 60,51,195,0,3,192,0,240,0,240,3,192,3,192,0,252
  DB 0,252,0,240,0,60,0,15,0,3,192,254,4,0,63,240
  DB 0,60,0,60,0,240,0,3,192,0,60,12,240,192,3,192
  DB 60,0,15,0,240,60,0,240,254,16,0,3,0,192,192,48
  DB 0,0,15,192,252,0,3,192,0,240,0,240,3,192,3,192
  DB 0,240,0,240,0,240,0,60,0,15,0,3,192,254,5,0
  DB 15,192,60,0,60,0,240,0,3,192,0,15,12,240,192,0
  DB 15,60,0,15,0,0,63,255,240,254,4,0,252,3,254,5
  DB 195,192,254,5,0,192,0,0,192,0,0,15,192,252,0,3
  DB 192,0,240,0,240,3,192,3,192,0,240,0,240,0,240,0
  DB 60,0,15,0,3,192,254,3,0,3,0,0,240,60,0,60
  DB 0,240,0,3,192,0,3,240,63,0,3,192,60,0,15,0
  DB 0,60,254,6,0,60,0,255,192,255,0,63,254,6,0,15
  DB 0,60,254,3,0,3,0,48,0,3,192,0,240,0,240,0
  DB 240,63,192,0,240,0,240,0,240,0,60,0,15,0,3,192
  DB 254,3,0,3,252,3,192,15,0,240,0,240,0,0,240,192
  DB 0,192,12,0,3,192,252,0,15,0,0,15,3,192,254,4
  DB 0,60,0,15,3,254,3,195,192,254,0,0,0,0,0,0
  DB 0 ;Not precisely sure where this RLE bitmap ends
;--- Sound state variables ---
; p38bc: sound mode (0=off, 1=timed pulse, 2=toggle square wave)
; p38be: current PIT timer value
; p38co: sound step counter
; p38c2: sound type/event ID
; p38c3: previous sound type
p38bc:
  DW 0
p38be:
  DW 2000
p38co:
  DW 0
p38c2:
  DB 0
p38c3:
  DW 1

;  p38c5:
;    DB 0,0
;  p38c7:
;    DB 0,0,0

;--- Enemy state arrays (2 enemies max, DW × 2 each) ---
; p38ca/cc: enemy X positions [0], [1]
; p38ce/do: enemy Y positions [0], [1]
; p38d2:    enemy X velocity (pair)
; p38d6:    enemy Y velocity (pair)
; p38da:    enemy direction (pair)
; p38de:    direction delta / turning rate (pair)
; p38e2:    direction change rate (pair)
; p38e6:    current speed (pair)
; p38ea:    target speed (pair)
; p38ee:    sprite frame (pair)
; p38f2:    animation counter (pair)
; p38f6:    misc enemy state
p38ca: ;Array
  DW 0
p38cc:
  DW 0
p38ce: ;Array
  DW 0
p38do:
  DW 0
p38d2: ;Array
  DW 0,0
p38d6: ;Array
  DW 0,0
p38da: ;Array
  DW 0,0
p38de: ;Array
  DW 0,0
p38e2: ;Array
  DW 0,0
p38e6: ;Array
  DW 0,0
p38ea: ;Array
  DW 0,0
p38ee: ;Array
  DW 0,0
p38f2: ;Array
  DW 0,0
p38f6:
  DW 0
;--- Enemy trail ring buffer (128 words) ---
; Records recent enemy positions for visual trail effect
p38f8:
  times 128 DW 0
;--- Tail segment state arrays ---
; Tracks the player's tail segments during territory claiming.
; Each pair is [current][previous] for 2 segments.
; p39f8/fa: segment X position
; p39fc/fe: segment Y position
; p3aoo/o2: segment direction
; p3ao4/o6: segment speed
; p3ao8:    segment state flags
; p3aoc/oe: segment counters
p39f8: ;Array
  DW 0
p39fa:
  DW 0
p39fc: ;Array
  DW 0
p39fe:
  DW 0
p3aoo:
  DW 0 ;Array
p3ao2:
  DW 0
p3ao4: ;Array
  DW 0
p3ao6:
  DW 0
p3ao8: ;Array
  DW 0,0
p3aoc: ;Array
  DW 0
p3aoe: ;Array
  DW 0
;--- Path recording buffer (358 words) ---
; Records the player's path coordinates during territory claiming.
; Each entry is an x,y coordinate pair. Used by flood fill to
; determine which side of the path to fill.
p3a1o:
  times 358 DW 0
p3cdc: ;Array
  DW 0,0
p3ceo: ;Array
  DW 0,0
p3ce4: ;Array
  DW 0,0
p3ce8: ;Array
  DW 0,0
p3cec: ;Array
  DW 0,0
p3cfo:
  DW 0
p3cf2:
  DW 0
p3cf4:
  DW 0
p3cf6:
  DW 0
;--- Player position ---
; p3cf8: player X coordinate (pixels)
; p3cfa: player Y coordinate (pixels)
p3cf8:
  DW 0
p3cfa:
  DW 0
p3cfc:
  DW 0
p3cfe:
  DW 0
;--- Player movement state machine variables ---
; p3doo: current direction (0-7)
; p3do2: pause/frozen flag
; p3do4: movement enabled (1=moving)
; p3do6: on-border flag
; p3do8: last direction
; p3doa-p3doe: saved state for territory claiming
; p3d1o-p3d12: movement delta X/Y
; p3d14: movement speed
; p3d16: territory state (2=safe on border, 1=in open, 0=claiming)
; p3d18-p3d24: additional movement/turn state
p3doo:
  DW 0
p3do2:
  DW 0
p3do4:
  DW 0
p3do6:
  DW 0
p3do8:
  DW 0
p3doa:
  DW 0
p3doc:
  DW 0
p3doe:
  DW 0
p3d1o:
  DW 0
p3d12:
  DW 0
p3d14:
  DW 0
p3d16:
  DW 0
p3d18:
  DW 0
p3d1a:
  DW 0
p3d1c:
  DW 0
p3d1e:
  DW 0
p3d2o:
  DW 0
p3d22:
  DW 0
p3d24:
  times 1000 DW 0
;--- General-purpose buffer (1000 words) ---
p4cc4:
  times 1000 DW 0
p5c64:
  DB 5,5,136,12,12,12,136
  DB 12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,136
  DB 12,12,12,136
p5c7f:
  DB 5,5,136,0,0,0,136,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,0,136,0,0,0,136
p5c9a:
  DB 0,0,0,160,153,177,148,64
p5ca2:
  DB 0,0,0,0,0,0,89,64
p5caa:
  DB 0,0,0,0,0,64,143,64
p5cb2:
  DW 0
p5cb4:
  DW 0
p5cb6:
  DW 0
p5cb8:
  DW 0

;    DW 0

p5cbc:
  DW 0
p5cbe:
  DW 0
p5cco:
  DW 0
p5cc2:
  DW 0
p5cc4:
  DW 0
p5cc6:
  DW 0
p5cc8:
  DW 0
p5cca:
  DW 0
p5ccc:
  DW 0
p5cce:
  DW 0
p5cdo:
  DW 0
p5cd2:
  DW 0
p5cd4:
  DW 0
p5cd6:
  DW 0
p5cd8:
  times 1000 DW 0
p64a8:
  times 1000 DW 0
;--- Joystick calibration & game control state ---
; p6c78: current effective direction (combined kb/joy)
; p6c7a/7c/7e/8o: joystick center calibration values
; p6c82: joystick enabled flag
; p6c84: action/fire button active flag
; p6c86/88: current score (32-bit, low/high word)
; p6c8a/8c: previous score checkpoint
; p6c8e/9o: misc game state
; p6c92/94: score tracking for bonus calculations
; p6c96: difficulty tier (2/3/5)
; p6c98: difficulty countdown timer
; p6c9a: input timeout flag
p6c78:
  DW 0
p6c7a:
  DW 0
p6c7c:
  DW 0
p6c7e:
  DW 0
p6c8o:
  DW 0
p6c82:
  DW 0
p6c84:
  DW 0
p6c86:
  DW 0
p6c88:
  DW 0
p6c8a:
  DW 0
p6c8c:
  DW 0
p6c8e:
  DW 0
p6c9o:
  DW 0
p6c92:
  DW 0
p6c94:
  DW 0
p6c96:
  DW 0
p6c98:
  DW 0
p6c9a:
  DW 0
p6c9c:
  times 10 DB 0
p6ca6:
  times 36 DB 0
p6cca:
  DW 0
p6ccc:
  DW 0
p6cce: ;Array
  DW 0
p6cdo: ;Array
  times 19 DW 0
p6cf6: ;Array
  DW 0
p6cf8:
  DW 0
p6cfa:
  DB 46
  DB 46,46,0,46,46,46,0,46,46,46,0,46,46,46,0,46
  DB 46,46,0,46,46,46,0,46,46,46,0,46,46,46,0,46
  DB 46,46,0,46,46,46,0,46,46,46,0
;--- Enemy sprite bitmaps (9×7 pixels, 3 color variants) ---
; p6d26: variant 1, p6d67: variant 2, p6da8: variant 3
; Each sprite: width(DW)=9, height(DW)=7, then 7 rows of pixel data
p6d26:
  DB 9,7,17,17,17
  DB 17,17,17,17,17,17,17,17,1,17,1,17,1,17,17,17
  DB 17,16,16,17,16,1,17,17,17,17,17,1,17,17,1,17
  DB 17,17,17,16,16,17,17,1,17,17,17,17,1,17,1,16
  DB 0,17,17,17,17,17,17,17,17,17,17,17
p6d67:
  DB 9,7,68,68
  DB 68,68,68,68,68,68,68,68,68,4,68,4,64,0,68,68
  DB 68,68,64,64,68,64,68,68,68,68,68,68,4,68,64,0
  DB 68,68,68,68,64,64,68,68,64,68,68,68,68,4,68,4
  DB 64,0,68,68,68,68,68,68,68,68,68,68,68
p6da8:
  DB 9,7,34
  DB 34,34,34,34,34,34,34,34,34,2,34,2,34,2,32,0
  DB 34,34,32,32,34,34,2,32,32,34,34,34,2,34,34,2
  DB 32,32,34,34,32,32,34,34,2,32,32,34,34,2,34,2
  DB 34,2,32,0,34,34,34,34,34,34,34,34,34,34
;--- Diamond sprite (3×5 pixels) ---
; Used as level/difficulty indicator icon
p6de9:
  DB 3,5
  DB 15,0,15,0,0,240,0,15,0,0,240,0,15,0,15
;--- Game text strings ---
; p6dfa: game UI labels ("NEW HIGH SCORE", "GAME OVER", etc.)
p6dfa:
  DB 46,46,46,0
p6dfe:
  DB "NEW HIGH SCORE",0
p6eod:
  DB "GAME OVER",0
p6e17:
  DB 0
p6e18:
  DB "       ",0
p6e2o:
  DB " BONUS ",0
p6e28:
  DB "HIGH SCORES",0
p6e34:
  DB "  ",0
p6e37:
  DB "s",0
p6e39:
  DB "ENTER YOUR",0
p6e44:
  DB "INITIALS",0
p6e4d:
  DB "_ _ _",0
p6e53:
  DB " ",0,0
p6e56:
  DW 0

;    DW 0

p6e5a:
  DW 0
p6e5c:
  DW 0
p6e5e:
  DW 0
p6e6o:
  DW 0
p6e62:
  DW 0
p6e64:
  DW 0
p6e66:
  DW 0
p6e68:
  DW 0
p6e6a:
  DW 0
p6e6c:
  DW 0
p6e6e:
  DW 0
p6e7o:
  DW 0
p6e72:
  DW 0
p6e74:
  DW 0

;    DW 5 DUP (0)

p6e8o:
  DW 0
p6e82:
  DW 0
p6e84:
  DW 0
p6e86:
  DW 0
p6e88:
  DB 245,185,218,138,253,101,233,63
p6e9o:
  DB 64,72,22,48,129,91,229,63
p6e98:
  DB 55,110,49,63,55,52,238,63
p6eao:
  DB 27,39,133,121,143,243,240,63
  DB 2,5,0,0,0,0,0,0,0,0,0,0
;--- Digit character bitmaps 0-9 ---
; Each: width(DW)=2, height(DW)=5, then 5 rows of pixel data
; Used by o4b72 for score/number rendering
p6eb4:
  DB 2,5,15,255,15,15,15,15,15,15,15,255
p6eco:
  DB 2,5,0,240,0,240,0,240,0,240,0,240
p6ecc:
  DB 2,5,15,255,0,15,15,255,15,0,15,255
p6ed8:
  DB 2,5,15,255,0,15,0,255,0,15,15,255
p6ee4:
  DB 2,5,15,0,15,15,15,255,0,15,0,15
p6efo:
  DB 2,5,15,255,15,0,15,255,0,15,15,255
p6efc:
  DB 2,5,15,255,15,0,15,255,15,15,15,255
p6fo8:
  DB 2,5,15,255,0,15,0,15,0,15,0,15
p6f14:
  DB 2,5,15,255,15,15,15,255,15,15,15,255
p6f2o:
  DB 2,5,15,255,15,15,15,255,0,15,0,15
;--- Letter character bitmaps A-Z + special chars ---
; Each: width(DW)=5, height(DW)=7, then 7 rows of pixel data
; Used by o4c8a for in-game text rendering
; A=p6f2c, B=p6f51, ... Z=p72c9
; Special: space=p72ee, period=p7313, underscore=p7338, etc.
p6f2c:
  DB 5,7
  DB 0,0,240,0,0
  DB 0,15,15,0,0
  DB 0,240,0,240,0
  DB 15,0,0,15,0
  DB 15,255,255,255,0
  DB 15,0,0,15,0
  DB 15,0,0,15,0
p6f51:
  DB 5,7,15,255,255,240,0,0,240,0
  DB 15,0,0,240,0,15,0,0,255,255,240,0,0,240,0,15
  DB 0,0,240,0,15,0,15,255,255,240,0
p6f76:
  DB 5,7,0,255,255
  DB 240,0,15,0,0,15,0,15,0,0,0,0,15,0,0,0
  DB 0,15,0,0,0,0,15,0,0,15,0,0,255,255,240,0
p6f9b:
  DB 5,7,15,255,255,240,0,0,240,0,15,0,0,240,0,15
  DB 0,0,240,0,15,0,0,240,0,15,0,0,240,0,15,0
  DB 15,255,255,240,0
p6fco:
  DB 5,7,15,255,255,255,0,15,0,0,0
  DB 0,15,0,0,0,0,15,255,255,0,0,15,0,0,0,0
  DB 15,0,0,0,0,15,255,255,255,0
p6fe5:
  DB 5,7,15,255,255,255
  DB 0,15,0,0,0,0,15,0,0,0,0,15,255,255,0,0
  DB 15,0,0,0,0,15,0,0,0,0,15,0,0,0,0
p7ooa:
  DB 5,7,0,255,255,240,0,15,0,0,15,0,15,0,0,0,0
  DB 15,0,0,0,0,15,0,15,255,0,15,0,0,15,0,0
  DB 255,255,240,0
p7o2f:
  DB 5,7,15,0,0,15,0,15,0,0,15,0
  DB 15,0,0,15,0,15,255,255,255,0,15,0,0,15,0,15
  DB 0,0,15,0,15,0,0,15,0
p7o54:
  DB 5,7,0,255,255,240,0
  DB 0,0,240,0,0,0,0,240,0,0,0,0,240,0,0,0
  DB 0,240,0,0,0,0,240,0,0,0,255,255,240,0
p7o79:
  DB 5,7
  DB 0,0,15,255,0,0,0,0,240,0,0,0,0,240,0,0
  DB 0,0,240,0,15,0,0,240,0,0,240,0,240,0,0,15
  DB 255,0,0
p7o9e:
  DB 5,7,15,0,0,240,0,15,0,240,0,0,15
  DB 240,0,0,0,15,15,0,0,0,15,0,240,0,0,15,0
  DB 15,0,0,15,0,0,240,0
p7oc3:
  DB 5,7,15,0,0,0,0,15
  DB 0,0,0,0,15,0,0,0,0,15,0,0,0,0,15,0
  DB 0,0,0,15,0,0,0,0,15,255,255,255,0
p7oe8:
  DB 5,7,15
  DB 0,0,15,0,15,240,0,255,0,15,15,15,15,0,15,0
  DB 240,15,0,15,0,0,15,0,15,0,0,15,0,15,0,0
  DB 15,0
p71od:
  DB 5,7,15,0,0,15,0,15,240,0,15,0,15,15
  DB 0,15,0,15,0,240,15,0,15,0,15,15,0,15,0,0
  DB 255,0,15,0,0,15,0
p7132:
  DB 5,7,0,255,255,240,0,15,0
  DB 0,15,0,15,0,0,15,0,15,0,0,15,0,15,0,0
  DB 15,0,15,0,0,15,0,0,255,255,240,0
p7157:
  DB 5,7,15,255
  DB 255,240,0,15,0,0,15,0,15,0,0,15,0,15,255,255
  DB 240,0,15,0,0,0,0,15,0,0,0,0,15,0,0,0
  DB 0
p717c:
  DB 5,7,0,255,255,240,0,15,0,0,15,0,15,0,0
  DB 15,0,15,0,0,15,0,15,0,15,15,0,15,0,0,255
  DB 0,0,255,255,240,0
p71a1:
  DB 5,7,15,255,255,240,0,15,0,0
  DB 15,0,15,0,0,15,0,15,255,255,240,0,15,0,15,0
  DB 0,15,0,0,240,0,15,0,0,15,0
p71c6:
  DB 5,7,0,255,255
  DB 240,0,15,0,0,15,0,15,0,0,0,0,0,255,255,240
  DB 0,0,0,0,15,0,15,0,0,15,0,0,255,255,240,0
p71eb:
  DB 5,7,15,255,255,255,0,0,0,240,0,0,0,0,240,0
  DB 0,0,0,240,0,0,0,0,240,0,0,0,0,240,0,0
  DB 0,0,240,0,0
p721o:
  DB 5,7,15,0,0,15,0,15,0,0,15
  DB 0,15,0,0,15,0,15,0,0,15,0,15,0,0,15,0
  DB 15,0,0,15,0,0,255,255,240,0
p7235:
  DB 5,7,15,0,0,15
  DB 0,15,0,0,15,0,15,0,0,15,0,15,0,0,15,0
  DB 0,240,0,240,0,0,15,15,0,0,0,0,240,0,0
p725a:
  DB 5,7,15,0,0,15,0,15,0,0,15,0,15,0,0,15,0
  DB 15,0,240,15,0,15,0,240,15,0,15,15,15,15,0,0
  DB 240,0,240,0
p727f:
  DB 5,7,15,0,0,15,0,0,240,0,240,0
  DB 0,15,15,0,0,0,0,240,0,0,0,15,15,0,0,0
  DB 240,0,240,0,15,0,0,15,0
p72a4:
  DB 5,7,15,0,0,15,0
  DB 0,240,0,240,0,0,15,15,0,0,0,0,240,0,0,0
  DB 0,240,0,0,0,0,240,0,0,0,0,240,0,0
p72c9:
  DB 5,7
  DB 15,255,255,255,0,0,0,0,240,0,0,0,15,0,0,0
  DB 0,240,0,0,0,15,0,0,0,0,240,0,0,0,15,255
  DB 255,255,0
p72ee:
  DB 5,7,0,0,0,0,0,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0
p7313:
  DB 5,7,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  DB 0,0,0,0,0,240,0,0,0,0,0,0,0
p7338:
  DB 5,7,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,255,255,240,0,0,0,0
  DB 0,0
p735d:
  DB 5,7,0,15,255,0,0,0,240,0,240,0,15,0
  DB 0,15,0,15,0,0,15,0,15,0,0,15,0,0,240,0
  DB 240,0,0,15,255,0,0
p7382:
  DB 5,7,0,0,240,0,0,0,15
  DB 240,0,0,0,240,240,0,0,0,0,240,0,0,0,0,240
  DB 0,0,0,0,240,0,0,0,255,255,240,0
p73a7:
  DB 5,7,0,255
  DB 255,240,0,15,0,0,15,0,0,0,0,15,0,0,0,15
  DB 240,0,0,15,240,0,0,0,240,0,0,0,15,255,255,255
  DB 0
p73cc:
  DB 5,7,15,255,255,255,0,0,0,0,240,0,0,0,15
  DB 0,0,0,0,255,240,0,0,0,0,15,0,15,0,0,15
  DB 0,0,255,255,240,0
p73f1:
  DB 5,7,0,0,15,240,0,0,0,240
  DB 240,0,0,15,0,240,0,0,240,0,240,0,15,255,255,255
  DB 0,0,0,0,240,0,0,0,0,240,0
p7416:
  DB 5,7,15,255,255
  DB 255,0,15,0,0,0,0,15,255,255,240,0,0,0,0,15
  DB 0,0,0,0,15,0,15,0,0,15,0,0,255,255,240,0
p743b:
  DB 5,7,0,0,15,0,0,0,0,240,0,0,0,15,0,0
  DB 0,0,240,255,240,0,15,0,0,15,0,15,0,0,15,0
  DB 0,255,255,240,0
p746o:
  DB 5,7,15,255,255,255,0,0,0,0,240
  DB 0,0,0,15,0,0,0,0,240,0,0,0,15,0,0,0
  DB 0,240,0,0,0,15,0,0,0,0
p7485:
  DB 5,7,0,255,255,240
  DB 0,15,0,0,15,0,15,0,0,15,0,0,255,255,240,0
  DB 15,0,0,15,0,15,0,0,15,0,0,255,255,240,0
p74aa:
  DB 5,7,0,255,255,240,0,15,0,0,15,0,15,0,0,15,0
  DB 0,255,255,240,0,0,0,15,0,0,0,0,240,0,0,0
  DB 15,0,0,0,0
;--- Game state flags ---
; p74do: death flag (non-zero = player just died)
; p74d2: remaining lives count
; p74d4: current level number (1-9)
; p74d6: level complete flag
; p74d8: game ID/magic value (0xAF)
p74do:
  DW 0
p74d2:
  DW 0
p74d4:
  DW 0
p74d6:
  DW 0
p74d8:
  DW 0
;--- "PRESS ANY KEY" and other prompt strings ---
p74da:
  DB "  PRESS ANY KEY ",0
p74eb:
  DB "                ",0

;  p74fc:
;    DB "This program is copy protected",0
;  p751b:
;    DB 0

;--- C-style character type classification table (256 bytes) ---
; Used by printf formatter (o6o56) for character classification
; (isdigit, isalpha, isspace, etc.)
p751c:
  DB 0,32,32,32,32,32,32,32,32,32,40,40,40,40,40
  DB 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
  DB 32,32,72,16,16,16,16,16,16,16,16,16,16,16,16,16
  DB 16,16,132,132,132,132,132,132,132,132,132,132,16,16,16,16
  DB 16,16,16,129,129,129,129,129,129,1,1,1,1,1,1,1
  DB 1,1,1,1,1,1,1,1,1,1,1,1,1,16,16,16
  DB 16,0,16,130,130,130,130,130,130,2,2,2,2,2,2,2
  DB 2,2,2,2,2,2,2,2,2,2,2,2,2,16,16,16
  DB 16,32,32,32,32,32,32,32,32,32,32,40,40,40,40,40
  DB 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
  DB 32,32,72,16,16,16,16,16,16,16,16,16,16,16,16,16
  DB 16,16,132,132,132,132,132,132,132,132,132,132,16,16,16,16
  DB 16,16,16,129,129,129,129,129,129,1,1,1,1,1,1,1
  DB 1,1,1,1,1,1,1,1,1,1,1,1,1,16,16,16
  DB 16,0,16,130,130,130,130,130,130,2,2,2,2,2,2,2
  DB 2,2,2,2,2,2,2,2,2,2,2,2,2,16,16,16
  DB 16,32,0
;--- Hex digit string for printf %x format ---
p761e:
  DB "0123456789ABCDEF",0,0
p763o:
  times 1738 DB 0
  DB 46
  DB 46,46,0,46,46,46,0,46,46,46,0,46,46,46,0,46
  DB 46,46,0,46,46,46,0,46,46,46,0,46,46,46,0,46
  DB 46,46,0,46,46,46,0,46,46,46,0,9,7,17,17,17
  DB 17,17,17,17,17,17,17,17,1,17,1,17,1,17,17,17
  DB 17,16,16,17,16,1,17,17,17,17,17,1,17,17,1,17
  DB 17,17,17,16,16,17,17,1,17,17,17,17,1,17,1,16
  DB 0,17,17,17,17,17,17,17,17,17,17,17,9,7,68,68
  DB 68,68,68,68,68,68,68,68,68,4,68,4,64,0,68,68
  DB 68,68,64,64,68,64,68,68,68,68,68,68,4,68,64,0
  DB 68,68,68,68,64,64,68,68,64,68,68,68,68,4,68,4
  DB 64,0,68,68,68,68,68,68,68,68,68,68,68,9,7,34
  DB 34,34,34,34,34,34,34,34,34,2,34,2,34,2,32,0
  DB 34,34,32,32,34,34,2,32,32,34,34,34,2,34,34,2
  DB 32,32,34,34,32,32,34,34,2,32,32,34,34,2,34,2
  DB 34,2,32,0,34,34,34,34,34,34,34,34,34,34,3,5
  DB 15,0,15,0,0,240,0,15,0,0,240,0,15,0,15,46
  DB 46,46,0,78,69,87,32,72,73,71,72,32,83,67,79,82
  DB 69,0,71,65,77,69,32,79,86,69,82,0,0,32,32,32
  DB 32,32,32,32,0,32,66,79,78,85,83,32,0,72,73,71
  DB 72,32,83,67,79,82,69,83,0,32,32,0,115,0,69,78
  DB 84,69,82,32,89,79,85,82,0,73,78,73,84,73,65,76
  DB 83,0,95,32,95,32,95,0,32,0,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  DB 0,0,0,0,0,0,0,0,0,0,0,0,0,245,185,218
  DB 138,253,101,233,63,64,72,22,48,129,91,229,63,55,110,49
  DB 63,55,52,238,63,27,39,133,121,143,243,240,63,2,5,0
  DB 0,0,0,0,0,0,0,0,0,2,5,15,255,15,15,15
  DB 15,15,15,15,255,2,5,0,240,0,240,0,240,0,240,0
  DB 240,2,5,15,255,0,15,15,255,15,0,15,255,2,5,15
  DB 255,0,15,0,255,0,15,15,255,2,5,15,0,15,15,15
  DB 255,0,15,0,15,2,5,15,255,15,0,15,255,0,15,15
  DB 255,2,5,15,255,15,0,15,255,15,15,15,255,2,5,15
  DB 255,0,15,0,15,0,15,0,15,2,5,15,255,15,15,15
  DB 255,15,15,15,255,2,5,15,255,15,15,15,255,0,15,0
  DB 15,5,7,0,0,240,0,0,0,15,15,0,0,0,240,0
  DB 240,0,15,0,0,15,0,15,255,255,255,0,15,0,0,15
  DB 0,15,0,0,15,0,5,7,15,255,255,240,0,0,240,0
  DB 15,0,0,240,0,15,0,0,255,255,240,0,0,240,0,15
  DB 0,0,240,0,15,0,15,255,255,240,0,5,7,0,255,255
  DB 240,0,15,0,0,15,0,15,0,0,0,0,15,0,0,0
  DB 0,15,0,0,0,0,15,0,0,15,0,0,255,255,240,0
  DB 5,7,15,255,255,240,0,0,240,0,15,0,0,240,0,15
  DB 0,0,240,0,15,0,0,240,0,15,0,0,240,0,15,0
  DB 15,255,255,240,0,5,7,15,255,255,255,0,15,0,0,0
  DB 0,15,0,0,0,0,15,255,255,0,0,15,0,0,0,0
  DB 15,0,0,0,0,15,255,255,255,0,5,7,15,255,255,255
  DB 0,15,0,0,0,0,15,0,0,0,0,15,255,255,0,0
  DB 15,0,0,0,0,15,0,0,0,0,15,0,0,0,0,5
  DB 7,0,255,255,240,0,15,0,0,15,0,15,0,0,0,0
  DB 15,0,0,0,0,15,0,15,255,0,15,0,0,15,0,0
  DB 255,255,240,0,5,7,15,0,0,15,0,15,0,0,15,0
  DB 15,0,0,15,0,15,255,255,255,0,15,0,0,15,0,15
  DB 0,0,15,0,15,0,0,15,0,5,7,0,255,255,240,0
  DB 0,0,240,0,0,0,0,240,0,0,0,0,240,0,0,0
  DB 0,240,0,0,0,0,240,0,0,0,255,255,240,0,5,7
  DB 0,0,15,255,0,0,0,0,240,0,0,0,0,240,0,0
  DB 0,0,240,0,15,0,0,240,0,0,240,0,240,0,0,15
  DB 255,0,0,5,7,15,0,0,240,0,15,0,240,0,0,15
  DB 240,0,0,0,15,15,0,0,0,15,0,240,0,0,15,0
  DB 15,0,0,15,0,0,240,0,5,7,15,0,0,0,0,15
  DB 0,0,0,0,15,0,0,0,0,15,0,0,0,0,15,0
  DB 0,0,0,15,0,0,0,0,15,255,255,255,0,5,7,15
  DB 0,0,15,0,15,240,0,255,0,15,15,15,15,0,15,0
  DB 240,15,0,15,0,0,15,0,15,0,0,15,0,15,0,0
  DB 15,0,5,7,15,0,0,15,0,15,240,0,15,0,15,15
  DB 0,15,0,15,0,240,15,0,15,0,15,15,0,15,0,0
  DB 255,0,15,0,0,15,0,5,7,0,255,255,240,0,15,0
  DB 0,15,0,15,0,0,15,0,15,0,0,15,0,15,0,0
  DB 15,0,15,0,0,15,0,0,255,255,240,0,5,7,15,255
  DB 255,240,0,15,0,0,15,0,15,0,0,15,0,15,255,255
  DB 240,0,15,0,0,0,0,15,0,0,0,0,15,0,0,0
  DB 0,5,7,0,255,255,240,0,15,0,0,15,0,15,0,0
  DB 15,0,15,0,0,15,0,15,0,15,15,0,15,0,0,255
  DB 0,0,255,255,240

;============================================================================
; BMP Background Image Data
;============================================================================
no_images:         DB 0          ;Flag: 1 if /N switch disables BMP loading
bmp_loaded:        DB 0          ;Flag: 1 if BMP successfully loaded
bmp_filename:      DB "STYX0.BMP",0  ;Digit at [bmp_filename+4] patched per level
bmp_file_handle:   DW 0
bmp_img_width:     DW 0
bmp_img_height:    DW 0
bmp_bytes_per_row: DW 0
bmp_cur_row:       DW 0
bmp_downsample:    DB 0          ;1 if 320->160 downsampling needed
bmp_hdr:           times 118 DB 0 ;BMP file header + info header + palette
bmp_row_buf:       times 164 DB 0 ;One BMP row (max 320@4bpp + padding)
bmp_palette:       times 32 DB 0  ;Converted V6355 palette (16 colors x 2)
pal_brightness:    times 16 DB 0  ;Brightness values (R+G+B, 0-21) per entry
pal_remap:         times 16 DB 0  ;Forward map: pal_remap[new_pos] = old_index
pal_inv_remap:     times 16 DB 0  ;Inverse map: pal_inv_remap[old_index] = new_pos

;--- Background image buffer: 16000 bytes ---
; Even rows (0,2,4,...198) at offset 0, odd rows (1,3,...199) at offset 8000
; Each bank: 100 rows x 80 bytes = 8000 bytes
; Total: 16192 bytes for CGA interlaced layout (8192 + 8000)
bmp_background:    times 16192 DB 0

;============================================================================
; Startup BMP Screen Data (persistent across gameplay)
;============================================================================
ss_loaded:          DB 0          ;1 if startup BMP analyzed successfully
ss_bpp:             DB 0          ;4 or 8 bits per pixel
ss_num_colors:      DW 0          ;16 or 256 palette entries
ss_row_bytes:       DW 0          ;Bytes per BMP row (160 or 320)
ss_data_offset_lo:  DW 0          ;BMP pixel data offset (lo word)
ss_data_offset_hi:  DW 0          ;BMP pixel data offset (hi word)
ss_bg_index:        DB 0          ;Darkest palette entry (background)
ss_global_b:        DB 0          ;2nd most common color (entries 4/5)
ss_global_c:        DB 0          ;Most common color (entries 6/7)
ss_cur_row:         DW 0          ;Current row during processing
ss_file_handle:     DW 0          ;DOS file handle for STYX.BMP
ss_top3_temp:       DB 0,0,0      ;Temp: top 3 color indices
ss_nn_best_dist:    DW 0          ;Temp: nearest-neighbor best distance
ss_nn_best_cga:     DB 0          ;Temp: nearest-neighbor best CGA value
ss_bps_cur_a:       DB 0          ;Temp: far line color A
ss_bps_cur_b:       DB 0          ;Temp: far line color B
ss_bps_cur_c:       DB 0          ;Temp: far line color C
ss_bps_nxt_a:       DB 0          ;Temp: near line color A
ss_bps_nxt_b:       DB 0          ;Temp: near line color B
ss_bps_nxt_c:       DB 0          ;Temp: near line color C
ss_filename:        DB "STYX.BMP",0
ss_border_ctr:      DB 0            ;C64-style border color cycling counter
ss_bulk_remaining:  DW 0            ;Rows left in bulk buffer
ss_bulk_ptr:        DW 0            ;Pointer to next row in bulk buffer
ss_vram_cache_seg:  DW 0            ;Segment for cached startup VRAM (0=none)
ss_vram_cached:     DB 0            ;1 if startup VRAM is cached

;--- Loading splash screen (ANSI color codes) ---
ss_splash:
  DB 0x1B,'[2J',0x1B,'[H'          ;Clear screen, home cursor
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB '                              '
  DB 0x1B,'[1;36m'                  ;Bright Cyan
  DB 'Olivetti Prodest PC1'
  DB 0x1B,'[0m',0x0D,0x0A
  DB '                                '
  DB 0x1B,'[1;33m'                  ;Bright Yellow
  DB 'STYX Remastered'
  DB 0x1B,'[0m',0x0D,0x0A
  DB 0x0D,0x0A
  DB '                                '
  DB 0x1B,'[1;35m'                  ;Bright Magenta
  DB 'Retro Erik'
  DB 0x1B,'[0m'
  DB ' 2026',0x0D,0x0A
  DB 0x0D,0x0A
  DB 0x0D,0x0A
  DB '                                   '
  DB 0x1B,'[1;33m'                  ;Bright Yellow
  DB 'Loading...'
  DB 0x1B,'[0m',0x0D,0x0A,'$'
ss_pal_r:           times 256 DB 0 ;Red channel (0-255) per palette entry
ss_pal_g:           times 256 DB 0 ;Green channel per palette entry
ss_pal_b:           times 256 DB 0 ;Blue channel per palette entry
ss_v6355_pal:       times 512 DB 0 ;V6355D 2-byte entries (up to 256 colors)
ss_scanline_top3:   times 600 DB 0 ;Top 3 colors per scanline (3 x 200)
ss_stream_len:      times 200 DB 0 ;Per-line: 0=skip, 12=full write
ss_palette_stream:  times 2400 DB 0 ;Interleaved V6355D data (12 bytes x 200)

;--- Raster bar data (palram9-style) ---
ss_bar1_y:          DB 0            ;Bar 1 screen Y position (absolute)
ss_bar2_y:          DB 0            ;Bar 2 screen Y position (absolute)
ss_bar1_sine_idx:   DB 0            ;Bar 1 sine table index (0-255)
ss_bar2_sine_idx:   DB 85           ;Bar 2 sine table index (120° offset)
ss_bar_gb:          DB 0            ;Pre-fetched G|B byte for bar zone burst
ss_bar_zorder:      DB 0            ;0 = blue on top, 1 = red on top

; Green E2-E7 data for OUTSB (12 bytes: 6 entries × 2 bytes each)
; All entries = pure green (R=0, G=7, B=0) → V6355D: R=0x00, GB=0x70
ss_green_e2e7:
  DB 0x00,0x70, 0x00,0x70, 0x00,0x70, 0x00,0x70, 0x00,0x70, 0x00,0x70

; Red gradient: 14 lines (R ramps 1→7→1, 1 line each), G=0, B=0
ss_red_gradient:
  DB 1,0x00,  2,0x00,  3,0x00,  4,0x00,  5,0x00,  6,0x00,  7,0x00
  DB 7,0x00,  6,0x00,  5,0x00,  4,0x00,  3,0x00,  2,0x00,  1,0x00

; Blue gradient: 14 lines (B ramps 1→7→1, 1 line each), R=0, G=0
ss_blue_gradient:
  DB 0,0x01,  0,0x02,  0,0x03,  0,0x04,  0,0x05,  0,0x06,  0,0x07
  DB 0,0x07,  0,0x06,  0,0x05,  0,0x04,  0,0x03,  0,0x02,  0,0x01

; Sine table (256 entries, values 0-97) — same as palram9
ss_sine_table:
  DB 50, 51, 52, 53, 55, 56, 57, 58, 59, 61, 62, 63, 64, 65, 66, 68
  DB 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84
  DB 84, 85, 86, 87, 87, 88, 89, 89, 90, 90, 91, 91, 92, 92, 93, 93
  DB 94, 94, 94, 95, 95, 95, 96, 96, 96, 96, 97, 97, 97, 97, 97, 97
  DB 97, 97, 97, 97, 97, 97, 97, 97, 96, 96, 96, 96, 95, 95, 95, 94
  DB 94, 94, 93, 93, 92, 92, 91, 91, 90, 90, 89, 89, 88, 87, 87, 86
  DB 85, 84, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71
  DB 70, 69, 68, 66, 65, 64, 63, 62, 61, 59, 58, 57, 56, 55, 53, 52
  DB 50, 49, 48, 47, 45, 44, 43, 42, 41, 39, 38, 37, 36, 35, 34, 32
  DB 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16
  DB 16, 15, 14, 13, 13, 12, 11, 11, 10, 10,  9,  9,  8,  8,  7,  7
  DB  6,  6,  6,  5,  5,  5,  4,  4,  4,  4,  3,  3,  3,  3,  3,  3
  DB  3,  3,  3,  3,  3,  3,  3,  3,  4,  4,  4,  4,  5,  5,  5,  6
  DB  6,  6,  7,  7,  8,  8,  9,  9, 10, 10, 11, 11, 12, 13, 13, 14
  DB 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
  DB 30, 31, 32, 34, 35, 36, 37, 38, 39, 41, 42, 43, 44, 45, 47, 48

; Per-scanline raster bar colors (200 × 2 bytes = 400 bytes)
ss_scanline_colors: times 200 * 2 DB 0

