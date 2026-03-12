; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

PUBLIC o172,o17b,o227,o2a9,o2c1,o2e7,o41c,o44b,o4c3,o4f2,o543,o55o,o562,o5c3
PUBLIC o64o,o6a7,o71d,o793,o82b,o8c1,o9ob,o933,o95b,oa59,oa6e,oa7d,oa89,oab6
PUBLIC oae7,ob18,ob49,oc43,oc63,oc83,oca3,occf,ocec,od2e,od5a,od7o,od8d,odb7
PUBLIC odd4,odfe,oeoe,oe1e,oe2e,oe3e,oe4e,oe5e,oe6e,oe7e,oe8e,oe9e,oeae,oebe
PUBLIC oec9,oecf,oed7,oedd,oee5,oeeb,oef3,oef9,ofoc,of12,of18,ofce
PUBLIC o1o5o,o1o61,o1o77,o1o9a,o1oc3,o1ofe,o1142,o117f,o11dd,o1227,o135f,o1391
PUBLIC o17ae,o18bf,o18ec,o1a11,o1add,o1ae5,o1bo9,o1bab,o1dcb,o1def,o1e72,o1f25
PUBLIC o1f49,o1f6f,o1fa8
PUBLIC pc1_set_cga_palette,pc1_disable_mode
PUBLIC _exit,_print,_quiet,volume,int8speed,lmul,ldiv,_setspeedmul,_setmode
PUBLIC _printhelp,delay1,delay2

_TEXT SEGMENT WORD PUBLIC 'CODE'

MAIN:
  CLI
  MOV AX,offset codeend
  ADD AX,0f
  SHR AX,4
  MOV BX,CS
  ADD AX,BX
  MOV DS,AX
  MOV SS,AX
  MOV BX,01000
  SUB BX,AX
  TEST BX,0f000
  MOV BX,0fff0
  MOV SP,BX
  STI
  MOV W[p],BX
  MOV AX,offset p763o
  MOV W[p2],AX
  PUSH ES
  XOR AX,AX
  PUSH AX
  MOV BP,SP
  MOV SI,080
  MOV CL,0
  INC SI
  XOR CH,CH
  MOV BX,CX
  ADD BX,4
  AND BX,0fffe
  SUB SP,BX
  MOV DI,SP
  MOV B[DI],063
  INC DI
  JCXZ o161
  MOV B[DI],020
  INC DI
o159:
  MOV AL,020
  MOV B[DI],AL
  INC SI
  INC DI
  LOOP o159
o161:
  XOR AX,AX
  MOV B[DI],AL
  MOV AX,DS
  MOV ES,AX
  MOV AX,SP
  PUSH AX
  CALL o17b
  MOV SP,BP
  RETF

o172:
  MOV AX,W[p]
  SUB AX,4
  MOV SP,AX
  RETF

o17b:
  CALL cmdline
  CALL calibrate
  PUSH BP
  SUB SP,4
  MOV BP,SP
o181:
  MOV SI,W[BP+8]
  MOV AL,B[SI]
  XOR AH,AH
  INC AX
  MOV DI,AX
  MOV AL,B[DI+p751c]
  XOR AH,AH
  AND AX,8
  JZ o19b
  INC W[BP+8]
  JMP o181
o19b:
  MOV SI,W[BP+8]
  MOV AL,B[SI]
  XOR AH,AH
  TEST AX,AX
  JZ o2od
  CMP W[p4],020
  JGE o2od
  MOV AX,W[p4]
  INC W[p4]
  SHL AX,1
  MOV DI,AX
  MOV AX,SI
  MOV W[DI+6],AX
o1be:
  MOV SI,W[BP+8]
  MOV AL,B[SI]
  XOR AH,AH
  TEST AX,AX
  MOV W[BP],AX
  JZ o1df
  INC AX
  MOV DI,AX
  MOV AL,B[DI+p751c]
  XOR AH,AH
  AND AX,8
  JNZ o1df
  INC W[BP+8]
  JMP o1be
o1df:
  MOV SI,W[BP+8]
  MOV AL,B[SI]
  XOR AH,AH
  TEST AX,AX
  JZ o2od
  MOV SI,W[BP+8]
  INC W[BP+8]
  MOV B[SI],0
o1f3:
  MOV SI,W[BP+8]
  MOV AL,B[SI]
  XOR AH,AH
  INC AX
  MOV DI,AX
  MOV AL,B[DI+p751c]
  XOR AH,AH
  AND AX,8
  JZ o19b
  INC W[BP+8]
  JMP o1f3
o2od:
  MOV AX,6
  PUSH AX
  PUSH W[p4]
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
  SUB SP,0a
  MOV BP,SP
  XOR AX,AX
  OUT 043,AL
  IN AL,040
  MOV BL,AL
  MOV W[BP],AX
  IN AL,040
  MOV BH,AL
  MOV W[BP+4],BX
  MOV AL,040
  OUT 043,AL
  IN AL,041    ;RAM refresh counter?
  MOV BL,AL
  IN AL,041
  MOV BH,AL
  MOV AX,W[BP+4]
  IMUL BX
  MOV CL,8
  SAR AX,CL
  AND AX,0ff
  MOV CX,W[BP+0e]
  INC CX
  MOV W[BP+8],AX
  IMUL CX
  MOV W[BP+0e],CX
  MOV CL,8
  SAR AX,CL
  MOV W[BP+6],BX
  ADD SP,0a
  POP BP
  RET

o2a9:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,W[BP+6]
  TEST AX,AX
  JNS o2b9
  NEG W[BP+6]
o2b9:
  MOV AX,W[BP+6]
  ADD SP,2
  POP BP
  RET

o2c1:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,W[BP+6]
  ADD AX,05a
  CMP AX,0168
  MOV W[BP+6],AX
  JL o2da
  SUB W[BP+6],0168
o2da:
  PUSH W[BP+6]
  CALL o2e7
  MOV SP,BP
  ADD SP,2
  POP BP
  RET

o2e7:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  MOV AX,W[BP+0c]
  MOV BX,05a
  CWD
  IDIV BX
  JMP o34b
o2f8:
  MOV AX,W[BP+0c]
  MOV W[BP+6],1
  MOV W[BP+4],AX
  JMP o35b
o3o5:
  MOV AX,0b4
  SUB AX,W[BP+0c]
  MOV W[BP+6],1
  MOV W[BP+4],AX
  JMP o35b
o315:
  MOV AX,W[BP+0c]
  SUB AX,0b4
  MOV W[BP+6],-1
  MOV W[BP+4],AX
  JMP o35b
o325:
  MOV AX,0168
  SUB AX,W[BP+0c]
  MOV W[BP+6],-1
  MOV W[BP+4],AX
  JMP o35b
o335:
  PUSH W[BP+0c]
  MOV AX,offset p46
  PUSH AX
  CALL o6o56
  MOV SP,BP
  JMP o35b

o343:
  DW offset o2f8,offset o3o5,offset o315,offset o325

o34b:
  MOV SI,AX
  CMP SI,4
  JNB o359
  SHL SI,1
  CS: JMP W[SI+o343]
o359:
  JMP o335
o35b:
  MOV AX,W[BP+4]
  MOV BX,0a
  CWD
  IDIV BX
  MOV SI,AX
  CMP SI,0a
  JNB o3e5
  SHL SI,1
  CS: MOV BX,W[SI+o3fo]
  MOV AX,W[BP+6]
  IMUL BX
o414:
  ADD SP,8
  POP BP
  RET
o3e5:
  MOV AX,05e
  PUSH AX
  CALL o6o56
  MOV SP,BP
  MOV AX,W[BP+2]
  JMP o414

o3fo:
  DW 0,011,022,031,040,04c,056,05d,062,064

o41c:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  PUSH AX
  PUSH DX
  PUSH CX
  MOV W[BP+2],0
o427:
  MOV AX,W[BP+2]
  CMP AX,W[BP+0a]
  JGE o444
  CS: MOV AX,W[volume]
  CS: MOV DX,W[volume+2]
  MOV CX,10
o434:
  LOOP o434
  MOV CX,10
  SUB AX,1
  SBB DX,0
  JC o43f
  JMP o434
o43f:
  INC W[BP+2]
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
  CS: MOV AX,W[volume]
  CS: MOV DX,W[volume+2]
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
  CS: MOV AX,W[volume]
  CS: MOV DX,W[volume+2]
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


speed0:
  DW 291
_speedmul:
  DW 100
_mode:
  DW 0

volume:
  DW 0,0

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
  OR DI,0c
d2:
  OR CX,CX
  JNS d3
  NEG CX
  NEG BX
  SBB CX,0
  XOR DI,4
d3:
  MOV BP,CX
  MOV CX,020
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

calibrate:
  CALL getkips ;Now we have the computer KIPS speed in DX:AX
  CS: MOV BX,W[_speedmul]
  XOR CX,CX
  CALL lmul
  CS: MOV BX,W[speed0]
  XOR CX,CX
  CALL ldiv
  CMP AX,0
  JNE savevol
  CMP DX,0
  JNE savevol
  INC AX
savevol:
  CS: MOV W[volume],AX
  CS: MOV W[volume+2],DX
  RET

cmdline:
  PUSH ES
  PUSH BP
  MOV AX,CS
  SUB AX,010
  PUSH AX
  MOV AX,081
  PUSH AX
  CALL _parsecmd
  POP AX
  POP AX
  POP BP
  POP ES
  RET

getkips:
  PUSH ES
  MOV AX,040
  MOV ES,AX
  XOR AX,AX
  XOR DX,DX
  ES: MOV SI,W[06c]
zerotime:
  ES: CMP SI,W[06c]
  JZ zerotime
  ES: MOV SI,W[06c]
getkloop:
  CALL timekips
  ES: CMP SI,W[06c]
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
  DW 0a0f7,0
  DW 09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0
  DW 09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0
  DW 09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0
  DW 09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0,09801,0
  DW 09801,0,09801,0,09801,0,09801,0
  POP SI
  POP DX
  POP AX
  RET

o449:
  DW 0

o44b:
  PUSH BP
  MOV BP,SP
  MOV DX,03d8
  MOV AL,2           ;320x200 mode (disabled)
  OUT DX,AL
  MOV SI,offset p87  ;CGA registers
  MOV CX,010         ;16 of them
  MOV BL,0           ;This one first
o47a:
  MOV DX,03d4
  MOV AL,BL
  OUT DX,AL          ;Index register
  MOV DX,03d5
  MOV AL,B[SI]
  OUT DX,AL          ;Output value (screws up VGA CRTC controller)
  INC SI
  INC BL
  LOOP o47a
  MOV DX,03d9
  MOV AL,0
  OUT DX,AL          ;Background 0
  INC DX             ;This wasn't here before - believed to be in error
o491:
  IN AL,DX
  TEST AL,8          ;Retrace
  JZ o491
  MOV DX,03d8
  MOV AL,0a
  OUT DX,AL          ;Enable graphics
  PUSH DS
  MOV AX,0
  MOV DS,AX
  MOV AL,B[0410]     ;Equipment
  AND AL,0cf
  OR AL,010
  MOV B[0410],AL     ;Initial video mode=1
  POP DS
  MOV AX,4
  INT 010            ;Set video mode to 320x200x4
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV BH,1
  MOV AH,0b
  INT 010            ;Set palette value to argument (only 0 used)
  XOR BX,BX
  INT 010
  MOV AX,0ff         ;Success result
  POP BP
  RET

vgasave:
  DB 0

o4c3:
  PUSH DS
  MOV AX,040
  MOV DS,AX
  MOV AL,B[089]
  POP DS
  CS: MOV B[vgasave],AL
  CS: MOV W[_mode],1    ;PC1: always CGA mode
  RET

nonefound:
  MOV AX,errormsg
  PUSH AX
  CALL _print
  POP AX
_exit:
  MOV AX,04c01
  INT 021

_setmode:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  CS: MOV W[_mode],AX
  POP BP
  RET

_setspeedmul:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  CS: MOV W[_speedmul],AX
  POP BP
  RET

helpmsg:
  DB "STYX - Copyright (c) 1983 Windmill software",10,13
  DB "Restored 1998 by AJ Software",10,13
  DB "http://fly.to/digger",10,13,10,13
  DB "Command line syntax:",10,13
  DB "  STYX [[/S:]speed] [/C] [/V] [/Q]",10,13,10,13
  DB "/C = Use CGA graphics",10,13
  DB "/V = Use VGA graphics",10,13
  DB "/Q = Quiet mode (no sound at all)",10,13,"$"

errormsg:
  DB "CGA or better adapter required.",10,13
  DB "Use /C for CGA or /V for EGA or better if you believe you have one."
  DB 10,13,"$"

_printhelp:
  MOV AX,offset helpmsg
  PUSH AX
  CALL _print
  POP AX
  RET

_print:
  PUSH BP
  PUSH DS
  MOV BP,SP
  MOV AH,9
  MOV DX,W[BP+6]
  MOV DS,CS
  INT 021
  POP DS
  POP BP
  RET

_quiet:
  MOV W[pco],0
  RET

o4f2:
  PUSH BP
  MOV BP,SP
  MOV DX,0201
  ES: MOV W[pd9],0
  ES: MOV W[pdb],0
  IN AL,DX
  TEST AL,010
  JNZ o512
  ES: MOV W[pd9],0ff
o512:
  TEST AL,020
  JNZ o51d
  ES: MOV W[pdb],0ff
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
  ES: MOV W[pd5],BX
  ES: MOV W[pd7],CX
  POP BP
  RET

o543:      ;Set up PC1 hidden 160x200x16 mode
  PUSH BP
  MOV BP,SP
  ;--- Enable hidden graphics mode on V6355D ---
  ; Unlock 16-color mode via mode control port
  MOV AL,04a            ;Graphics mode, video ON
  OUT 0d8,AL
  JMP SHORT $+2
  ; Border defaults to black (color 0) — no need to set
  ; Set CGA palette
  CALL pc1_set_cga_palette
  ; Clear VRAM at B000h (16KB = 8192 words)
  PUSH ES
  MOV AX,0b000
  MOV ES,AX
  XOR DI,DI
  MOV CX,04000         ;16384 bytes
  XOR AL,AL
  REP STOSB
  POP ES
  POP BP
  RET

;--- PC1 palette programming routines ---
pc1_set_cga_palette:
  PUSH AX
  PUSH CX
  PUSH SI
  CLI                    ;Disable interrupts during palette writes
  MOV AL,040             ;Open palette for writing
  OUT 0dd,AL
  JMP SHORT $+2
  MOV SI,offset pc1_cga_colors
  MOV CX,020            ;32 bytes (16 colors x 2)
pc1_pal_loop:
  MOV AL,B[SI]
  OUT 0de,AL             ;Write palette byte
  JMP SHORT $+2
  INC SI
  LOOP pc1_pal_loop
  MOV AL,080             ;Close palette
  OUT 0dd,AL
  STI                    ;Re-enable interrupts
  POP SI
  POP CX
  POP AX
  RET

;--- PC1 hidden mode disable (for exit) ---
pc1_disable_mode:
  MOV AL,065
  OUT 0dd,AL
  JMP SHORT $+2
  MOV AL,09
  OUT 0de,AL
  JMP SHORT $+2
  MOV AL,028             ;Text mode
  OUT 0d8,AL
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

o5c3:         ;Redraw screen (PC1 hidden mode — double-draw)
  PUSH BP
  MOV BP,SP
  PUSH ES
  MOV AX,0b000
  MOV ES,AX
  ; Copy shadow -> even bank (0000-1F3F) using REP MOVSW
  MOV SI,offset p12e
  XOR DI,DI
  MOV CX,4000
  REP MOVSW
  ; Copy shadow -> odd bank (2000-3F3F) using REP MOVSW
  MOV SI,offset p12e
  MOV DI,02000
  MOV CX,4000
  REP MOVSW
  POP ES
  POP BP
  RET

o64o:
  PUSH BP
  MOV BP,SP
  MOV BX,W[BP+4]
  AND BX,0f
  MOV BH,BL
  SHL BH,4
  MOV CX,056
  MOV DI,offset p12e
  ADD DI,0371
o65a:
  ES: MOV W[pc7],0
o661:
  MOV AL,B[DI]
  MOV AH,AL
  AND AL,0f
  CMP AL,8
  JZ o678
  TEST AL,8
  JNZ o673
  AND AL,0f
  JNZ o678
o673:
  AND AH,0f0
  OR AH,BL
o678:
  MOV AL,AH
  AND AH,0f0
  CMP AH,080
  JZ o69o
  TEST AH,080
  JNZ o68c
  AND AH,0f0
  JNZ o69o
o68c:
  AND AL,0f
  OR AL,BH
o69o:
  MOV B[DI],AL
  INC DI
  ES: INC W[pc7]
  ES: CMP W[pc7],04e
  JB o661
  ADD DI,2
  LOOP o65a
  POP BP
  RET

o6a7:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV W[pcd],AX
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV AX,W[BP+8]
  AND AL,0f
  MOV CH,AL
  MOV CL,CH
  ROL CH,1
  ROL CH,1
  ROL CH,1
  ROL CH,1
  MOV AX,W[BP+0a]
  MOV W[pcf],AX
  CALL oa59
  JZ o6d6
  JMP o717
o6d6:
  CALL oa6e
  ADD DI,offset p12e
  TEST AX,1
  JNZ o6fc
o6e4:
  MOV AL,B[DI]
  AND AL,0f0
  CMP AL,CH
  JNZ o717
  ES: MOV AX,W[pcf]
  ES: CMP W[pcd],AX
  JNB o717
  ES: INC W[pcd]
o6fc:
  MOV AL,B[DI]
  AND AL,0f
  CMP AL,CL
  JNZ o717
  ES: MOV AX,W[pcf]
  ES: CMP W[pcd],AX
  JNB o717
  ES: INC W[pcd]
  INC DI
  JMP o6e4
o717:
  ES: MOV AX,W[pcd]
  POP BP
  RET

o71d:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV W[pcd],AX
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV AX,W[BP+8]
  AND AL,0f
  MOV CH,AL
  MOV CL,CH
  ROL CH,1
  ROL CH,1
  ROL CH,1
  ROL CH,1
  MOV AX,W[BP+0a]
  MOV W[pcf],AX
  CALL oa59
  JZ o74c
  JMP o78d
o74c:
  CALL oa6e
  ADD DI,offset p12e
  TEST AX,1
  JNZ o772
o75a:
  MOV AL,B[DI]
  AND AL,0f0
  CMP AL,CH
  JZ o78d
  ES: MOV AX,W[pcf]
  ES: CMP W[pcd],AX
  JNB o78d
  ES: INC W[pcd]
o772:
  MOV AL,B[DI]
  AND AL,0f
  CMP AL,CL
  JZ o78d
  ES: MOV AX,W[pcf]
  ES: CMP W[pcd],AX
  JNB o78d
  ES: INC W[pcd]
  INC DI
  JMP o75a
o78d:
  ES: MOV AX,W[pcd]
  POP BP
  RET

o793:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV W[pcd],AX
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV AX,W[BP+8]
  AND AL,0f
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
  ADD DI,offset p12e
  TEST AX,1
  JNZ o7f6
o7ca:
  MOV AL,B[DI]
  MOV AH,AL
  AND AL,0f0
  CMP AL,070
  JZ o825
  CMP AL,080
  JZ o825
  CMP AL,CH
  JZ o825
  ES: CMP W[pcd],0a0
  JNB o825
  ES: INC W[pcd]
  ES: INC W[pd1]
  AND AH,0f
  OR AH,CH
  MOV B[DI],AH
o7f6:
  MOV AL,B[DI]
  MOV AH,AL
  AND AL,0f
  CMP AL,7
  JZ o825
  CMP AL,8
  JZ o825
  CMP AL,CL
  JZ o825
  ES: CMP W[pcd],0a0
  JNB o825
  ES: INC W[pcd]
  ES: INC W[pd1]
  AND AH,0f0
  OR AH,CL
  MOV B[DI],AH
  INC DI
  JMP o7ca
o825:
  ES: MOV AX,W[pcd]
  POP BP
  RET

o82b:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV W[pcd],AX
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV AX,W[BP+8]
  AND AL,0f
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
  ADD DI,offset p12e
  TEST AX,1
  JZ o88d
o862:
  MOV AL,B[DI]
  MOV AH,AL
  AND AL,0f
  CMP AL,7
  JZ o8bb
  CMP AL,8
  JZ o8bb
  CMP AL,CL
  JZ o8bb
  ES: CMP W[pcd],0
  JB o8bb
  ES: INC W[pd1]
  ES: DEC W[pcd]
  AND AH,0f0
  OR AH,CL
  MOV B[DI],AH
o88d:
  MOV AL,B[DI]
  MOV AH,AL
  AND AL,0f0
  CMP AL,070
  JZ o8bb
  CMP AL,080
  JZ o8bb
  CMP AL,CH
  JZ o8bb
  ES: CMP W[pcd],0
  JB o8bb
  ES: INC W[pd1]
  ES: DEC W[pcd]
  AND AH,0f
  OR AH,CH
  MOV B[DI],AH
  DEC DI
  JMP o862
o8bb:
  ES: MOV AX,W[pcd]
  POP BP
  RET

o8c1:         ;Clear screen to colour (PC1 hidden mode)
  PUSH BP
  MOV BP,SP
  MOV BX,W[BP+4]
  AND BX,0f
  MOV BH,BL
  SHL BH,4
  OR BL,BH        ;BL = color in both nibbles
  ; Wait for VBlank
  MOV DX,0da
o8e5:
  IN AL,DX
  TEST AL,8
  JZ o8e5
  ; Clear shadow buffer (8000 bytes) using word fill
  MOV DI,offset p12e
  MOV AL,BL
  MOV AH,BL
  MOV CX,4000
  REP STOSW
  ; Clear VRAM at B000h (both banks, 16384 bytes total)
  PUSH ES
  MOV AX,0b000
  MOV ES,AX
  XOR DI,DI
  MOV AL,BL
  MOV AH,BL
  MOV CX,02000     ;8192 words = 16384 bytes
  REP STOSW
  POP ES
  ; Wait for VBlank after clear
  MOV DX,0da
o8fd:
  IN AL,DX
  TEST AL,8
  JZ o8fd
  POP BP
  RET

o9ob:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV AX,W[BP+8]
  AND AL,0f
  MOV CH,AL
  MOV BP,0
  MOV SI,0
  PUSH DS
  MOV AX,0b000
  MOV DS,AX
  CALL o95b
  MOV AX,SI
  POP DS
  POP BP
  RET

o933:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV AX,W[BP+8]
  AND AL,0f
  MOV CH,AL
  MOV BP,1
  MOV SI,0
  PUSH DS
  MOV AX,0b000
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
  AND AL,0f
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  POP AX
  CMP BP,1
  JZ o9a9
  AND AL,0f0
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
  AND AL,0f0
  SHR AL,4
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  SHL CH,4
  POP AX
  CMP BP,1
  JZ o9a9
  AND AL,0f
  OR AL,CH
  CALL oa89
  RET
o9d9:           ;Direct VRAM write (BP=2): write CH byte to VRAM + shadow
  CALL oa6e
  MOV DX,0da
  ES: CMP W[pc9],0
  JNZ o9f9
  ES: CMP W[pcb],0
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
  MOV B[DI],CH          ;Write even row (bank 0)
  PUSH DI
  ADD DI,02000
  MOV B[DI],CH          ;Write odd row (bank 1) — double-draw
  POP DI
o9fb:
  PUSH DI
  ADD DI,offset p12e
  ES: MOV B[DI],CH      ;Write shadow buffer
  POP DI
  RET
oao7:
  CALL oa6e
  TEST AX,1
  JZ oa3o
  CALL oa7d
  PUSH AX
  AND AL,0f
  ES: MOV B[pc6],AL
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  POP AX
  AND AL,0f0
  ES: CMP B[pc6],CH
  JNZ oa2f
  CALL oa89
oa2f:
  RET
oa3o:
  CALL oa7d
  PUSH AX
  AND AL,0f0
  ES: MOV B[pc6],AL
  SHR AL,4
  MOV DX,1
  MOV CL,AL
  SHL DX,CL
  OR SI,DX
  SHL CH,4
  POP AX
  AND AL,0f
  ES: CMP B[pc6],CH
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
  OR SI,080
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
  ADD DI,offset p12e
  ES: MOV AL,B[DI]
  POP DI
  RET

oa89:           ;Write AL to VRAM (both rows) + shadow buffer at DI
  MOV AH,AL
  MOV DX,0da
  ES: CMP W[pc9],0
  JNZ oaa8
  ES: CMP W[pcb],0
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
  MOV B[DI],AH          ;Write even row (bank 0)
  PUSH DI
  ADD DI,02000           ;Odd row bank
  MOV B[DI],AH          ;Write odd row (bank 1) — double-draw
  POP DI
oaaa:
  PUSH DI
  ADD DI,offset p12e
  ES: MOV B[DI],AH      ;Write shadow buffer
  POP DI
  RET

oab6:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV W[pa1],AX
  MOV AX,W[BP+6]
  MOV W[pa3],AX
  MOV AX,W[BP+8]
  MOV W[pa5],AX
  MOV AX,W[BP+0a]
  MOV W[pa7],AX
  MOV AX,W[BP+0c]
  AND AX,0f
  MOV B[pa9],AL
  MOV BP,0
  MOV SI,0
  CALL ob49
  MOV AX,SI
  POP BP
  RET

oae7:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV W[pa1],AX
  MOV AX,W[BP+6]
  MOV W[pa3],AX
  MOV AX,W[BP+8]
  MOV W[pa5],AX
  MOV AX,W[BP+0a]
  MOV W[pa7],AX
  MOV AX,W[BP+0c]
  AND AX,0f
  MOV B[pa9],AL
  MOV BP,3
  MOV SI,0
  CALL ob49
  MOV AX,SI
  POP BP
  RET

ob18:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV W[pa1],AX
  MOV AX,W[BP+6]
  MOV W[pa3],AX
  MOV AX,W[BP+8]
  MOV W[pa5],AX
  MOV AX,W[BP+0a]
  MOV W[pa7],AX
  MOV AX,W[BP+0c]
  AND AX,0f
  MOV B[pa9],AL
  MOV BP,1
  MOV SI,0
  CALL ob49
  MOV AX,SI
  POP BP
  RET

ob49:
  MOV AX,W[pa5]
  SUB AX,W[pa1]
  MOV W[p95],AX
  MOV AX,W[pa7]
  SUB AX,W[pa3]
  MOV W[p97],AX
  MOV B[p9b],0
  MOV B[p9c],1
  MOV B[p9d],1
  MOV B[p9e],0
  CMP W[p95],0
  JGE ob81
  MOV B[p9d],0ff
  NEG W[p95]
ob81:
  CMP W[p97],0
  JGE ob91
  NEG W[p97]
  MOV B[p9c],0ff
ob91:
  MOV AX,W[p97]
  CMP W[p95],AX
  JGE obbe
  PUSH W[p95]
  MOV AX,W[p97]
  MOV W[p95],AX
  POP W[p97]
  MOV AL,B[p9d]
  MOV B[p9b],AL
  MOV B[p9d],0
  MOV AL,B[p9c]
  MOV B[p9e],AL
  MOV B[p9c],0
obbe:
  MOV AX,W[p95]
  SHR AX,1
  MOV W[p99],AX
  MOV W[p9f],1
  MOV AX,W[pa1]
  MOV BL,AL
  MOV AX,W[pa3]
  MOV BH,AL
  CALL oc13
obd9:
  MOV AX,W[p95]
  CMP W[p9f],AX
  JLE obe3
  RET
obe3:
  ADD BL,B[p9d]
  ADD BH,B[p9e]
  MOV AX,W[p97]
  ADD W[p99],AX
  INC W[p9f]
  MOV AX,W[p95]
  CMP W[p99],AX
  JLE ocoe
  MOV AX,W[p95]
  SUB W[p99],AX
  ADD BL,B[p9b]
  ADD BH,B[p9c]
ocoe:
  CALL oc13
  JMP obd9

oc13:
  MOV CH,B[pa9]
  PUSH BX
  PUSH DS
  MOV AX,0b000
  MOV DS,AX
  CALL o95b
  POP DS
  POP BX
  RET

oc43:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV B[paa],AL
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV DI,W[BP+8]
  MOV SI,0
  MOV BP,0
  CALL oca3
  MOV AX,SI
  POP BP
  RET

oc63:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV B[paa],AL
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV DI,W[BP+8]
  MOV SI,0
  MOV BP,1
  CALL oca3
  MOV AX,SI
  POP BP
  RET

oc83:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV BL,AL
  MOV B[paa],AL
  MOV AX,W[BP+6]
  MOV BH,AL
  MOV DI,W[BP+8]
  MOV SI,0
  MOV BP,2
  CALL oca3
  MOV AX,SI
  POP BP
  RET

oca3:
  MOV CL,B[DI]
  MOV B[pab],CL
  INC DI
  MOV CH,B[DI]
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
  MOV BL,B[paa]
  MOV CL,B[pab]
  JMP ocad
occe:
  RET

occf:
  PUSH CX
  MOV CH,B[DI]
  CMP CH,058
  JZ ocea
  CMP CH,088
  JZ ocea
  PUSH BX
  PUSH DI
  PUSH DS
  MOV AX,0b000
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
  CS: MOV W[o449],AX
  PUSH DS
  MOV AX,0
  MOV DS,AX
  MOV DI,024
  MOV AX,W[DI]
  MOV BX,W[DI+2]
  MOV CX,offset od2e
  MOV DX,CS
  CLI
  MOV W[DI],CX
  MOV W[DI+2],DX
  STI
  POP DS
  CS: MOV W[int9save],AX
  CS: MOV W[int9save+2],BX
  RET

restoreint9:
  CS: MOV CX,W[int9save]
  CS: MOV DX,W[int9save+2]
  XOR AX,AX
  MOV DS,AX
  MOV W[024],CX
  MOV W[026],DX
  RET

od2e:
  STI
  PUSH AX
  PUSH CX
  PUSH SI
  PUSH DS
  CLD
  CS: MOV AX,W[o449]
  MOV DS,AX
  IN AL,060
  PUSH AX
  IN AL,061
  MOV AH,AL
  OR AL,080
  OUT 061,AL
  XCHG AH,AL
  OUT 061,AL
  POP AX
  MOV B[pc3],AL
  CALL od5a
  CLI
  MOV AL,020
  OUT 020,AL
  POP DS
  POP SI
  POP CX
  POP AX
;  CS: JMP D[int9save]
  IRET

od5a:
  MOV SI,offset pdd
  MOV AL,B[pc3]
  MOV CX,01d
od63:
  CMP AL,B[SI]
  JZ od6d
  ADD SI,3
  LOOP od63
  CMP AL,044
  JNZ nokey
  JMP ofbe
nokey:
  RET
od6d:
  INC SI
  JMP W[SI]

od7o:
  MOV B[pbo],0ff
  MOV B[pd3],4
  MOV B[pd4],4
  MOV B[pb8],1
  MOV B[pb9],1
  CALL ofce
  RET

od8d:
  MOV B[pbo],0
  CMP B[pd3],4
  JNZ od9c
  CALL of18
od9c:
  CMP B[pb8],1
  JZ oda4
  RET
oda4:
  CMP B[pb1],0ff
  JNZ odb1
  MOV B[pb8],2
  RET
odb1:
  MOV B[pb8],0
  RET

odb7:
  MOV B[pb1],0ff
  MOV B[pd3],0
  MOV B[pd4],0
  MOV B[pb8],2
  MOV B[pb9],2
  CALL ofce
  RET

odd4:
  MOV B[pb1],0
  CMP B[pd3],0
  JNZ ode3
  CALL of18
ode3:
  CMP B[pb8],2
  JZ odeb
  RET
odeb:
  CMP B[pbo],0ff
  JNZ odf8
  MOV B[pb8],1
  RET
odf8:
  MOV B[pb8],0
  RET

odfe:
  MOV B[pb2],0ff
  MOV B[pd3],2
  MOV B[pd4],2
  RET

oeoe:
  MOV B[pb2],0
  CMP B[pd3],2
  JNZ oe1d
  CALL of18
oe1d:
  RET

oe1e:
  MOV B[pb3],0ff
  MOV B[pd3],6
  MOV B[pd4],6
  RET

oe2e:
  MOV B[pb3],0
  CMP B[pd3],6
  JNZ oe3d
  CALL of18
oe3d:
  RET

oe3e:
  MOV B[pb4],0ff
  MOV B[pd3],1
  MOV B[pd4],1
  RET

oe4e:
  MOV B[pb4],0
  CMP B[pd3],1
  JNZ oe5d
  CALL of18
oe5d:
  RET

oe5e:
  MOV B[pb5],0ff
  MOV B[pd3],3
  MOV B[pd4],3
  RET

oe6e:
  MOV B[pb5],0
  CMP B[pd3],3
  JNZ oe7d
  CALL of18
oe7d:
  RET

oe7e:
  MOV B[pb6],0ff
  MOV B[pd3],7
  MOV B[pd4],7
  RET

oe8e:
  MOV B[pb6],0
  CMP B[pd3],7
  JNZ oe9d
  CALL of18
oe9d:
  RET

oe9e:
  MOV B[pb7],0ff
  MOV B[pd3],5
  MOV B[pd4],5
  RET

oeae:
  MOV B[pb7],0
  CMP B[pd3],5
  JNZ oebd
  CALL of18
oebd:
  RET

oebe:
  MOV B[pbb],0ff
  MOV B[pba],0ff
  RET

oec9:
  MOV B[pba],0
  RET

oecf:
  MOV B[pbc],0ff
  JMP ofa6

oed7:
  MOV B[pbc],0
  RET

oedd:
  MOV B[pbd],0ff
  JMP ofa6

oee5:
  MOV B[pbd],0
  RET

oeeb:
  MOV B[pbe],0ff
  JMP ofa6

oef3:
  MOV B[pbe],0
  RET

oef9:
  CMP B[pbf],0ff
  JZ ofo1
  RET
ofo1:
  XOR B[pco],0ff
  MOV B[pbf],0
  RET

ofoc:
  MOV B[pbf],0ff
  RET

of12:
  MOV B[pc1],0ff
  RET

of18:
  MOV B[pd3],063
  CMP B[pb2],0
  JZ of2e
  MOV B[pd3],2
  MOV B[pd4],2
of2e:
  CMP B[pb3],0
  JZ of3f
  MOV B[pd3],6
  MOV B[pd4],6
of3f:
  CMP B[pbo],0
  JZ of5o
  MOV B[pd3],4
  MOV B[pd4],4
of5o:
  CMP B[pb1],0
  JZ of61
  MOV B[pd3],0
  MOV B[pd4],0
of61:
  CMP B[pb4],0
  JZ of72
  MOV B[pd3],1
  MOV B[pd4],1
of72:
  CMP B[pb5],0
  JZ of83
  MOV B[pd3],3
  MOV B[pd4],3
of83:
  CMP B[pb6],0
  JZ of94
  MOV B[pd3],7
  MOV B[pd4],7
of94:
  CMP B[pb7],0
  JZ ofa5
  MOV B[pd3],5
  MOV B[pd4],5
ofa5:
  RET

ofa6:
  CMP B[pbc],0ff
  JZ ofae
  RET
ofae:
  CMP B[pbd],0ff
  JZ ofb6
  RET
ofb6:
  CMP B[pbe],0ff
  JZ ofbe
  RET
ofbe:
  IN AL,061
  AND AL,0fc
  OUT 061,AL
  MOV AL,020
  OUT 020,AL
  PUSH DS
  MOV AX,040
  MOV DS,AX
  CS: MOV AL,B[vgasave]
  MOV B[089],AL
  POP DS
  CALL restoreint8
  CALL restoreint9
  CALL pc1_disable_mode   ;Reset V6355D to text mode
  MOV AX,3
  INT 010
  MOV AX,04c00
  INT 021

ofce:
  CMP B[pbc],0ff
  JZ ofd6
  RET
ofd6:
  CMP B[pbo],0ff
  JNZ offe
  INC B[pc2]
  CMP B[pc2],05e
  JNZ ofed
  MOV B[pc2],05d
ofed:
;  PUSH DX
;  MOV DX,03d4
;  MOV AL,2
;  OUT DX,AL
  MOV AL,B[pc2]
;  INC DX
;  OUT DX,AL      ;Change horizontal synch position?  Make screen wobble???
  MOV B[p7b],AL
;  POP DX
  RET
offe:
  CMP B[pb1],0ff
  JNZ o1o26
  DEC B[pc2]
  CMP B[pc2],054
  JNZ o1o15
  MOV B[pc2],055
o1o15:
;  PUSH DX
;  MOV DX,03d4
;  MOV AL,2
;  OUT DX,AL
  MOV AL,B[pc2]
;  INC DX
;  OUT DX,AL      ;Change horizontal synch position?  Make screen wobble???
  MOV B[p7b],AL
;  POP DX
  RET
o1o26:
  RET

o1o5o:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV AH,0e
  MOV BX,W[BP+6]
  MOV BH,0
  INT 010        ;Output character
  POP BP
  RET

o1o61:
  PUSH BP
  MOV BP,SP
  MOV BX,0
  MOV AX,W[BP+4]
  MOV DH,AL
  MOV AX,W[BP+6]
  MOV DL,AL
  MOV AH,2
  INT 010        ;Set cursor position
  POP BP
  RET

filename:
  DB 'STYX.SCO',0

o1o9a:
  PUSH BP
  PUSH DS
  MOV DS,CS
  MOV AX,03d00
  MOV DX,offset filename
  INT 021
  POP DS
  JC readerror
  MOV BX,AX
  MOV AH,03f
  MOV CX,0200
  MOV DX,offset p215o
  INT 021
  MOV AH,03e
  INT 021
readerror:
  POP BP
  RET

o1oc3:
  PUSH BP
  PUSH DS
  MOV DS,CS
  MOV AH,03c
  MOV CX,020
  MOV DX,offset filename
  INT 021
  POP DS
  JC writeerror
  MOV BX,AX
  MOV AH,040
  MOV CX,0200
  MOV DX,offset p215o
  INT 021
  MOV AH,03e
  INT 021
writeerror:
  POP BP
  RET

o1142:
  PUSH ES
  PUSH BP
  MOV AX,0b800
  MOV ES,AX
  MOV DI,0
  MOV SI,offset p2354
o114f:
  MOV AL,B[SI]
  CMP AL,0fe
  JZ o1163
  ES: MOV B[DI],AL
  INC DI
  INC SI
  CMP DI,04000
  JNZ o114f
  JMP o117a
o1163:
  INC SI
  MOV BL,B[SI]
  INC SI
  MOV AL,B[SI]
  INC SI
o116a:
  ES: MOV B[DI],AL
  INC DI
  CMP DI,04000
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

o117f:
  MOV AX,DS
  CS: MOV W[o117d],AX
  PUSH DS
  MOV AX,0
  MOV DS,AX
  MOV DI,020
  MOV AX,W[DI]
  MOV BX,W[DI+2]
  MOV CX,offset o11dd
  MOV DX,CS
  CLI
  MOV W[DI],CX
  MOV W[DI+2],DX
  STI
  POP DS
  CS: MOV W[int8save],AX
  CS: MOV W[int8save+2],BX
  RET

restoreint8:
  CLI
  MOV AL,036
  OUT 043,AL
  XOR AL,AL
  OUT 040,AL
  OUT 040,AL
  CS: MOV AX,W[int8save]
  CS: MOV BX,W[int8save+2]
  MOV DI,020
  PUSH DS
  XOR CX,CX
  MOV DS,CX
  MOV W[DI],AX
  MOV W[DI+2],BX
  STI
  POP DS
  RET

o11dd:
  PUSHF
  STI
  PUSH AX
  PUSH CX
  PUSH DX
  PUSH DS
  CLD
  CS: MOV AX,W[o117d]
  MOV DS,AX
  CMP W[p38bc],0
  JZ o1211
  CMP W[p38bc],1
  JZ o12o1
  IN AL,061
  XOR AL,2
  OUT 061,AL       ;Toggle speaker position
  JMP o1211
o12o1:
  MOV CX,W[p38c3]
  IN AL,061
  OR AL,2
  OUT 061,AL       ;Turn speaker on
o12oc:
  LOOP o12oc
  AND AL,0fd
  OUT 061,AL       ;Turn speaker off
o1211:
  MOV AX,W[p38be]
  ADD W[p38co],AX
  JNB o121e
  INC B[p38c2]

o121e:
  CS: MOV AX,W[int8speed]
  CS: ADD W[int8count],AX
  JNC eoi

  POP DS
  POP DX
  POP CX
  POP AX
  POPF
  CS: JMP D[int8save]

eoi:
  MOV AL,020
  OUT 020,AL       ;End of interrupt
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

o1227:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  CALL o5891
  CMP AX,3
  JGE o123d
  MOV W[p38f6],1
  JMP o1243
o123d:
  MOV W[p38f6],2
o1243:
  MOV W[BP+4],0
o1248:
  MOV AX,W[BP+4]
  CMP AX,W[p38f6]
  JL o1254
  JMP o135a
o1254:
  SHL AX,1
  MOV SI,AX
  MOV W[SI+p38ca],050
  MOV W[SI+p38ce],01e
  XOR BX,BX
  MOV W[SI+p38de],BX
  MOV BX,0a
  MOV W[SI+p38e6],BX
  MOV W[SI+p38ea],BX
  MOV W[BP+6],0
o127a:
  MOV AX,W[BP+6]
  CMP AX,8
  JL o1285
  JMP o1339
o1285:
  MOV CL,5
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+4]
  SHL AX,CL
  SHL AX,1
  ADD SI,AX
  MOV AX,W[BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,W[DI+p38ca]
  MOV W[SI+p38f8],AX
  MOV CL,5
  MOV AX,W[BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+4]
  SHL AX,CL
  SHL AX,1
  INC AX
  INC AX
  ADD SI,AX
  MOV AX,W[BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,W[DI+p38ce]
  MOV W[SI+p38f8],AX
  MOV CL,5
  MOV AX,W[BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+4]
  SHL AX,CL
  SHL AX,1
  ADD AX,4
  ADD SI,AX
  MOV AX,W[BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,W[DI+p38ca]
  MOV W[SI+p38f8],AX
  MOV CL,5
  MOV AX,W[BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+4]
  SHL AX,CL
  SHL AX,1
  ADD AX,6
  ADD SI,AX
  MOV AX,W[BP+4]
  SHL AX,1
  MOV DI,AX
  MOV AX,W[DI+p38ce]
  MOV W[SI+p38f8],AX
  MOV CL,5
  MOV AX,W[BP+6]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+4]
  SHL AX,CL
  SHL AX,1
  ADD AX,8
  ADD SI,AX
  MOV W[SI+p38f8],0
  INC W[BP+6]
  JMP o127a
o1339:
  MOV AX,W[BP+4]
  SHL AX,1
  MOV SI,AX
  MOV W[SI+p38f2],0
  MOV W[SI+p38ee],9
  PUSH W[BP+4]
  CALL o17ae
  MOV SP,BP
  INC W[BP+4]
  JMP o1248
o135a:
  ADD SP,8
  POP BP
  RET

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
  MOV W[BP+2],0
o1378:
  MOV AX,W[BP+2]
  CMP AX,W[p38f6]
  JGE o138c
  PUSH AX
  CALL o1391
  MOV SP,BP
  INC W[BP+2]
  JMP o1378
o138c:
  ADD SP,4
  POP BP
  RET

o1391:
  PUSH BP
  SUB SP,02c
  MOV BP,SP
  MOV W[BP+024],3
o139c:
  CMP W[BP+024],0
  JNZ o13a5
  JMP o17a9
o13a5:
  CALL o5891
  ADD AX,01e
  PUSH AX
  CALL o227
  MOV SP,BP
  CMP AX,01c
  JLE o13be
  PUSH W[BP+030]
  CALL o17ae
  MOV SP,BP
o13be:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p38e2]
  ADD W[SI+p38de],BX
  CMP W[SI+p38de],0168
  MOV W[BP],AX
  JL o13de
  SUB W[SI+p38de],0168
o13de:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p38de]
  TEST BX,BX
  MOV W[BP],AX
  JNS o13f6
  ADD W[SI+p38de],0168
o13f6:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  PUSH W[SI+p38de]
  CALL o2c1
  MOV SP,BP
  MOV BX,W[BP+030]
  SHL BX,1
  CWD
  IDIV W[BX+p38e6]
  PUSH W[BX+p38de]
  MOV W[BP+01e],AX
  CALL o2e7
  MOV SP,BP
  MOV BX,W[BP+030]
  SHL BX,1
  CWD
  IDIV W[BX+p38e6]
  MOV CX,W[BX+p38ca]
  MOV DX,W[BX+p38ce]
  MOV W[BP+01a],CX
  MOV CX,W[BX+p38d2]
  ADD W[BX+p38ca],CX
  MOV CX,W[BX+p38d6]
  ADD W[BX+p38ce],CX
  MOV W[BP+01c],DX
  MOV W[BP+020],AX
  MOV AX,W[BP+01e]
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,W[BX+p38ca]
  SUB CX,AX
  MOV W[BP+8],AX
  MOV AX,W[BP+020]
  MOV W[BP+012],CX
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,W[BX+p38ce]
  SUB CX,AX
  MOV DX,W[BX+p38ca]
  ADD DX,W[BP+8]
  MOV BX,W[BX+p38ce]
  ADD BX,AX
  XOR AX,AX
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH W[BP+012]
  MOV W[BP+014],CX
  MOV W[BP+016],DX
  MOV W[BP+018],BX
  CALL ob18
  MOV SP,BP
  MOV W[BP+022],AX
  AND AX,07996
  JNZ o14do
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p38ca],3
  JL o14do
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p38ca],09c
  JG o14do
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p38ce],0b
  JL o14do
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p38ce],060
  JLE o15oc
o14do:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[BP+01a]
  MOV W[SI+p38ca],BX
  MOV AX,W[BP+01c]
  MOV W[SI+p38ce],AX
  PUSH W[BP+030]
  CALL o17ae
  MOV SP,BP
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p38e6],032
  MOV W[BP],AX
  JGE o15o6
  MOV AX,W[SI+p38e6]
  ADD W[SI+p38e6],AX
o15o6:
  DEC W[BP+024]
  JMP o139c
o15oc:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV BX,W[SI+p38f2]
  SHL BX,CL
  MOV CL,3
  MOV DX,W[BP+030]
  SHL DX,CL
  SHL DX,1
  ADD BX,DX
  MOV CL,5
  MOV W[BP+6],BX
  MOV BX,W[SI+p38f2]
  SHL BX,CL
  MOV W[BP+4],DX
  INC DX
  INC DX
  ADD BX,DX
  MOV CL,5
  MOV DX,W[SI+p38f2]
  SHL DX,CL
  MOV DI,DX
  MOV DX,W[BP+4]
  ADD DX,4
  MOV CX,DI
  ADD CX,DX
  MOV W[BP+0a],CX
  MOV CL,5
  MOV DX,W[SI+p38f2]
  SHL DX,CL
  MOV DI,DX
  MOV DX,W[BP+4]
  ADD DX,6
  MOV CX,DI
  ADD CX,DX
  MOV W[BP+0c],CX
  MOV CL,5
  MOV AX,W[SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV AX,W[BP+4]
  ADD AX,8
  MOV DX,SI
  ADD DX,AX
  MOV SI,DX
  PUSH W[SI+p38f8]
  MOV SI,W[BP+0c]
  PUSH W[SI+p38f8]
  MOV SI,W[BP+0a]
  PUSH W[SI+p38f8]
  PUSH W[BX+p38f8]
  MOV SI,W[BP+6]
  PUSH W[SI+p38f8]
  CALL oae7
  MOV SP,BP
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,W[SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+030]
  SHL AX,CL
  SHL AX,1
  ADD SI,AX
  MOV AX,W[BP+012]
  MOV W[SI+p38f8],AX
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,W[SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+030]
  SHL AX,CL
  SHL AX,1
  INC AX
  INC AX
  ADD SI,AX
  MOV AX,W[BP+014]
  MOV W[SI+p38f8],AX
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,W[SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+030]
  SHL AX,CL
  SHL AX,1
  ADD AX,4
  ADD SI,AX
  MOV AX,W[BP+016]
  MOV W[SI+p38f8],AX
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,W[SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+030]
  SHL AX,CL
  SHL AX,1
  ADD AX,6
  ADD SI,AX
  MOV AX,W[BP+018]
  MOV W[SI+p38f8],AX
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV BX,W[SI+p38f2]
  SHL BX,CL
  MOV CL,3
  MOV DX,W[BP+030]
  SHL DX,CL
  SHL DX,1
  ADD DX,8
  ADD BX,DX
  MOV AX,W[SI+p38ee]
  MOV W[BX+p38f8],AX
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV CL,5
  MOV AX,W[SI+p38f2]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV AX,W[BP+030]
  SHL AX,CL
  SHL AX,1
  ADD AX,8
  ADD SI,AX
  PUSH W[SI+p38f8]
  PUSH W[BP+018]
  PUSH W[BP+016]
  PUSH W[BP+014]
  PUSH W[BP+012]
  CALL oab6
  MOV SP,BP
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  INC W[SI+p38f2]
  CMP W[SI+p38f2],8
  MOV W[BP],AX
  JL o1714
  MOV W[SI+p38f2],0
  MOV AX,4
  PUSH AX
  CALL o227
  MOV SP,BP
  MOV SI,AX
  CMP SI,5
  JNB o1714
  SHL SI,1
  CS: MOV AX,W[SI+o16fc]
  PUSH AX
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  POP AX
  MOV W[SI+p38ee],AX
o1714:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p38e6],0a
  MOV W[BP],AX
  JLE o172b
  MOV W[SI+p38e6],0a
o172b:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p38e6]
  CMP BX,W[SI+p38ea]
  MOV W[BP],AX
  JLE o1743
  DEC W[SI+p38e6]
o1743:
  MOV AX,W[BP+030]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p38e6]
  CMP BX,W[SI+p38ea]
  MOV W[BP],AX
  JGE o175b
  INC W[SI+p38e6]
o175b:
  XOR AX,AX
  CMP W[BP+030],0
  MOV W[BP+024],AX
  JNZ o1792
  MOV AX,W[p38ca]
  SUB AX,W[p3cf8]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  MOV BX,W[p38ce]
  SUB BX,W[p3cfa]
  PUSH BX
  MOV W[BP+028],AX
  CALL o2a9
  MOV SP,BP
  ADD W[BP+028],AX
  PUSH W[BP+028]
  MOV W[BP+02a],AX
  CALL o45b8
  MOV SP,BP
o1792:
  MOV AX,W[BP+022]
  AND AX,08000
  JNZ o179d
  JMP o139c
o179d:
  MOV AX,1
  PUSH AX
  CALL o5858
  MOV SP,BP
  JMP o139c
o17a9:
  ADD SP,02c
  POP BP
  RET

o16fc:
  DW 3,5,6,9,0a

o17ae:
  PUSH BP
  SUB SP,0e
  MOV BP,SP
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV AX,059
  PUSH AX
  MOV W[BP],SI
  CALL o227
  MOV SP,BP
  SHL AX,1
  SHL AX,1
  MOV SI,W[BP]
  MOV W[SI+p38da],AX
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV AX,3
  PUSH AX
  MOV W[BP],SI
  CALL o227
  MOV SP,BP
  ADD AX,3
  MOV SI,W[BP]
  MOV W[SI+p38ea],AX
  CMP W[p38f6],2
  JNZ o18o2
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  ADD W[SI+p38ea],5
o18o2:
  CALL o5891
  CMP AX,5
  JLE o1811
  MOV W[BP+0c],5
  JMP o1817
o1811:
  CALL o5891
  MOV W[BP+0c],AX
o1817:
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  PUSH W[SI+p38da]
  MOV W[BP+2],SI
  CALL o2c1
  MOV SP,BP
  MOV BX,W[BP+0c]
  ADD BX,0c
  PUSH BX
  MOV W[BP+6],AX
  CALL o227
  MOV SP,BP
  MOV BX,019
  SUB BX,AX
  MOV AX,W[BP+6]
  CWD
  IDIV BX
  MOV SI,W[BP+2]
  MOV W[SI+p38d2],AX
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  PUSH W[SI+p38da]
  MOV W[BP+2],SI
  CALL o2e7
  MOV SP,BP
  MOV BX,W[BP+0c]
  ADD BX,0a
  PUSH BX
  MOV W[BP+6],AX
  CALL o227
  MOV SP,BP
  MOV BX,019
  SUB BX,AX
  MOV AX,W[BP+6]
  CWD
  IDIV BX
  MOV SI,W[BP+2]
  MOV W[SI+p38d6],AX
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV AX,0f
  PUSH AX
  MOV W[BP],SI
  CALL o227
  MOV SP,BP
  ADD AX,5
  MOV SI,W[BP]
  MOV W[SI+p38e2],AX
  MOV AX,1
  PUSH AX
  CALL o227
  MOV SP,BP
  TEST AX,AX
  JZ o18ba
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p38e2]
  NEG AX
  MOV W[SI+p38e2],AX
o18ba:
  ADD SP,0e
  POP BP
  RET

o18bf:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP W[p38f6],2
  JNZ o18e7
  XOR AX,AX
  PUSH AX
  PUSH W[p38do]
  PUSH W[p38cc]
  CALL o933
  MOV SP,BP
  AND AX,1
  JNZ o18e7
  MOV W[p38f6],1
o18e7:
  ADD SP,2
  POP BP
  RET

o18ec:
  PUSH BP
  SUB SP,01a
  MOV BP,SP
  MOV W[BP+016],0
o18f7:
  MOV AX,W[BP+016]
  CMP AX,W[p38f6]
  JL o19o3
  JMP o1aoc
o19o3:
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p38f2]
  MOV W[BP+014],0
  MOV W[BP+018],AX
o1913:
  CMP W[BP+014],8
  JL o191c
  JMP o1ao6
o191c:
  MOV CL,5
  MOV AX,W[BP+018]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV BX,W[BP+016]
  SHL BX,CL
  SHL BX,1
  MOV W[BP],SI
  ADD SI,BX
  MOV DI,AX
  MOV W[BP+4],BX
  INC BX
  INC BX
  MOV CX,DI
  ADD CX,BX
  MOV BX,W[BP+4]
  ADD BX,4
  MOV DX,DI
  ADD DX,BX
  MOV AX,W[BP+4]
  ADD AX,6
  MOV BX,DI
  ADD BX,AX
  XOR AX,AX
  PUSH AX
  PUSH W[BX+p38f8]
  MOV DI,DX
  PUSH W[DI+p38f8]
  MOV DI,CX
  PUSH W[DI+p38f8]
  PUSH W[SI+p38f8]
  CALL ob18
  MOV SP,BP
  MOV W[BP+012],AX
  AND AX,0f996
  JZ o197e
  MOV AX,W[BP+016]
  MOV W[BP+016],AX
  JMP o19ef
o197e:
  MOV CL,5
  MOV AX,W[BP+018]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV BX,W[BP+016]
  SHL BX,CL
  SHL BX,1
  MOV W[BP],SI
  ADD SI,BX
  MOV DI,AX
  MOV W[BP+4],BX
  INC BX
  INC BX
  MOV CX,DI
  ADD CX,BX
  MOV BX,W[BP+4]
  ADD BX,4
  MOV DX,DI
  ADD DX,BX
  MOV BX,W[BP+4]
  ADD BX,6
  MOV W[BP+0e],BX
  MOV BX,DI
  MOV AX,W[BP+0e]
  ADD BX,AX
  MOV AX,W[BP+4]
  ADD AX,8
  MOV W[BP+010],AX
  MOV AX,DI
  MOV W[BP+0c],BX
  MOV BX,W[BP+010]
  ADD AX,BX
  MOV DI,AX
  PUSH W[DI+p38f8]
  MOV DI,W[BP+0c]
  PUSH W[DI+p38f8]
  MOV DI,DX
  PUSH W[DI+p38f8]
  MOV DI,CX
  PUSH W[DI+p38f8]
  PUSH W[SI+p38f8]
  CALL oab6
  MOV SP,BP
o19ef:
  MOV AX,W[BP+018]
  INC AX
  CMP AX,8
  MOV W[BP+018],AX
  JL o1aoo
  MOV W[BP+018],0
o1aoo:
  INC W[BP+014]
  JMP o1913
o1ao6:
  INC W[BP+016]
  JMP o18f7
o1aoc:
  ADD SP,01a
  POP BP
  RET

o1a11:
  PUSH BP
  SUB SP,01a
  MOV BP,SP
  XOR AX,AX
  MOV W[BP+016],AX
  MOV W[pcb],AX
o1a1f:
  MOV AX,W[BP+016]
  CMP AX,W[p38f6]
  JL o1a2b
  JMP o1ad2
o1a2b:
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p38f2]
  MOV W[BP+014],0
  MOV W[BP+018],AX
o1a3b:
  CMP W[BP+014],8
  JL o1a44
  JMP o1acc
o1a44:
  MOV CL,5
  MOV AX,W[BP+018]
  SHL AX,CL
  MOV SI,AX
  MOV CL,3
  MOV BX,W[BP+016]
  SHL BX,CL
  SHL BX,1
  MOV W[BP],SI
  ADD SI,BX
  MOV DI,AX
  MOV W[BP+4],BX
  INC BX
  INC BX
  MOV CX,DI
  ADD CX,BX
  MOV BX,W[BP+4]
  ADD BX,4
  MOV DX,DI
  ADD DX,BX
  MOV BX,W[BP+4]
  ADD BX,6
  MOV W[BP+0e],BX
  MOV BX,DI
  MOV AX,W[BP+0e]
  ADD BX,AX
  MOV AX,W[BP+4]
  ADD AX,8
  MOV W[BP+010],AX
  MOV AX,DI
  MOV W[BP+0c],BX
  MOV BX,W[BP+010]
  ADD AX,BX
  MOV DI,AX
  PUSH W[DI+p38f8]
  MOV DI,W[BP+0c]
  PUSH W[DI+p38f8]
  MOV DI,DX
  PUSH W[DI+p38f8]
  MOV DI,CX
  PUSH W[DI+p38f8]
  PUSH W[SI+p38f8]
  CALL oae7
  MOV SP,BP
  MOV AX,W[BP+018]
  INC AX
  CMP AX,8
  MOV W[BP+018],AX
  JL o1ac6
  MOV W[BP+018],0
o1ac6:
  INC W[BP+014]
  JMP o1a3b
o1acc:
  INC W[BP+016]
  JMP o1a1f
o1ad2:
  MOV W[pcb],1
  ADD SP,01a
  POP BP
  RET

o1add:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p38f6]
  POP BP
  RET

o1ae5:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CALL o5891
  CMP AX,2
  JGE o1afb
  MOV W[p3cf6],1
  JMP o1bo1
o1afb:
  MOV W[p3cf6],2
o1bo1:
  CALL o1dcb
  ADD SP,2
  POP BP
  RET

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
  MOV W[BP+4],2
  JMP o1b29
o1b24:
  MOV W[BP+4],1
o1b29:
  MOV W[BP+2],0
o1b2e:
  MOV AX,W[BP+2]
  CMP AX,W[BP+4]
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
  MOV W[BP+6],AX
  MOV W[p3cf4],AX
o1b4c:
  MOV AX,W[BP+6]
  CMP AX,W[p3cf6]
  JGE o1b8e
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3ce8],0
  JZ o1b73
  PUSH W[BP+6]
  CALL o1e72
  MOV SP,BP
  MOV AX,2
  PUSH AX
  CALL o41c        ;Delay don't know
  MOV SP,BP
  JMP o1b7b
o1b73:
  PUSH W[BP+6]
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
  INC W[BP+6]
  JMP o1b4c
o1b8e:
  CMP W[p3cf6],1
;  JNZ o1b9e       ;Speed up on level 2. Removed.
  MOV AX,2
  PUSH AX
  CALL o41c        ;Main game delay loop
  MOV SP,BP
o1b9e:
  CALL o1f6f
  INC W[BP+2]
  JMP o1b2e
o1ba6:
  ADD SP,8
  POP BP
  RET

o1bab:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p39f8]
  MOV CX,W[SI+p39fc]
  CMP W[SI+p3aoo],1
  MOV W[p3cf2],CX
  MOV W[p3cfo],BX
  JNZ o1be9
  PUSH W[BP+0a]
  CALL o216o
  MOV SP,BP
  PUSH W[BP+0a]
  CALL o216o
  MOV SP,BP
  PUSH W[BP+0a]
  CALL o216o
  MOV SP,BP
  JMP o1co1
o1be9:
  PUSH W[BP+0a]
  CALL o2187
  MOV SP,BP
  PUSH W[BP+0a]
  CALL o2187
  MOV SP,BP
  PUSH W[BP+0a]
  CALL o2187
  MOV SP,BP
o1co1:
  MOV W[BP+4],9
o1co6:
  CMP W[BP+4],0
  JG o1cof
  JMP o1c8c
o1cof:
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p39f8]
  MOV CX,W[SI+p39fc]
  PUSH W[SI+p3ao4]
  MOV W[p3cf2],CX
  MOV W[p3cfo],BX
  CALL o2of4
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3cf2]
  PUSH W[p3cfo]
  CALL o933
  MOV SP,BP
  AND AX,01001
  JZ o1c53
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV W[SI+p3cec],0
  JMP o1c8c
o1c53:
  CMP W[BP+4],1
  JNZ o1c66
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  INC W[SI+p3cec]
  JMP o1c8c
o1c66:
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3aoo],1
  JNZ o1c7e
  PUSH W[BP+0a]
  CALL o2187
  MOV SP,BP
  JMP o1c86
o1c7e:
  PUSH W[BP+0a]
  CALL o216o
  MOV SP,BP
o1c86:
  DEC W[BP+4]
  JMP o1co6
o1c8c:
  MOV W[BP+4],8
o1c91:
  CMP W[BP+4],0
  JLE o1do7
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p39f8]
  MOV CX,W[SI+p39fc]
  PUSH W[SI+p3ao4]
  MOV W[p3cf2],CX
  MOV W[p3cfo],BX
  CALL o2of4
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3cf2]
  PUSH W[p3cfo]
  CALL o933
  MOV SP,BP
  AND AX,0980
  JNZ o1do7
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3aoo],1
  JNZ o1ce4
  PUSH W[BP+0a]
  CALL o2187
  MOV SP,BP
  JMP o1cec
o1ce4:
  PUSH W[BP+0a]
  CALL o216o
  MOV SP,BP
o1cec:
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p39f8]
  MOV AX,W[SI+p39fc]
  MOV W[p3cf2],AX
  MOV W[p3cfo],BX
  DEC W[BP+4]
  JMP o1c91
o1do7:
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[p3cfo]
  MOV W[SI+p39f8],BX
  MOV AX,W[p3cf2]
  MOV W[SI+p39fc],AX
  CALL o5891
  PUSH AX
  CALL o227
  MOV SP,BP
  CMP AX,3
  JLE o1d4a
  CALL o5891
  MOV BX,0c
  SUB BX,AX
  PUSH BX
  CALL o227
  MOV SP,BP
  DEC AX
  JNZ o1d4a
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3ao8],03a
  JL o1d58
o1d4a:
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3ao8],8
  JGE o1d65
o1d58:
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  INC W[SI+p3ao8]
  JMP o1d71
o1d65:
  PUSH W[BP+0a]
  CALL o2o75
  MOV SP,BP
  OR W[p3cf4],AX
o1d71:
  PUSH W[BP+0a]
  CALL o1fa8
  MOV SP,BP
  MOV BX,W[p3cf4]
  OR BX,AX
  MOV W[p3cf4],BX
  AND BX,0fe7f
  JNZ o1dbd
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV BX,AX
  MOV AX,W[BX+p39f8]
  SUB AX,W[p3cf8]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,3
  JGE o1dc6
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p39fc]
  SUB AX,W[p3cfa]
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
  MOV W[BP+2],0
o1dd6:
  MOV AX,W[BP+2]
  CMP AX,W[p3cf6]
  JGE o1dea
  PUSH AX
  CALL o1def
  MOV SP,BP
  INC W[BP+2]
  JMP o1dd6
o1dea:
  ADD SP,4
  POP BP
  RET

o1def:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,W[BP+8]
  SHL AX,1
  MOV SI,AX
  MOV W[SI+p3ce8],1
  XOR BX,BX
  MOV W[SI+p3cec],BX
  MOV BX,W[p38ca]
  MOV W[SI+p39f8],BX
  MOV AX,W[p38ce]
  MOV W[SI+p39fc],AX
  CMP W[BP+8],0
  JNZ o1e46
o1e1d:
  XOR AX,AX
  PUSH AX
  PUSH W[p39fc]
  PUSH W[p39f8]
  CALL o933
  MOV SP,BP
  AND AX,080
  JNZ o1e38
  DEC W[p39f8]
  JMP o1e1d
o1e38:
  MOV W[p3ao4],2
  MOV W[p3aoo],1
  JMP o1e6d
o1e46:
  XOR AX,AX
  PUSH AX
  PUSH W[p39fe]
  PUSH W[p39fa]
  CALL o933
  MOV SP,BP
  AND AX,080
  JNZ o1e61
  INC W[p39fa]
  JMP o1e46
o1e61:
  MOV W[p3ao6],6
  MOV W[p3ao2],2
o1e6d:
  ADD SP,4
  POP BP
  RET

o1e72:
  PUSH BP
  SUB SP,0a
  MOV BP,SP
  MOV AX,W[BP+0e]
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p39f8]
  SUB AX,W[p3cf8]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,014
  JG o1eac
  MOV AX,W[BP+0e]
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p39fc]
  SUB AX,W[p3cfa]
  PUSH AX
  CALL o2a9
  MOV SP,BP
  CMP AX,014
  JLE o1f2o
o1eac:
  MOV AX,W[BP+0e]
  SHL AX,1
  MOV SI,AX
  MOV BX,1
  MOV W[SI+p3ao8],BX
  XOR BX,BX
  MOV W[SI+p3cdc],BX
  MOV W[SI+p3ceo],BX
  MOV BX,1
  MOV W[SI+p3ce4],BX
  MOV W[BP],AX
  MOV AX,W[BP+0e]
  MOV BX,03c
  IMUL BX
  MOV BX,W[SI+p3cdc]
  ADD BX,AX
  MOV W[BP+4],AX
  MOV AX,BX
  MOV CX,6
  IMUL CX
  MOV BX,AX
  MOV AX,W[SI+p39f8]
  MOV W[BX+p3aoc],AX
  MOV AX,W[BP+4]
  MOV BX,W[SI+p3cdc]
  ADD BX,AX
  MOV AX,BX
  IMUL CX
  MOV BX,AX
  MOV AX,W[SI+p39fc]
  MOV W[BX+p3aoe],AX
  MOV AX,W[SI+p3cdc]
  ADD AX,W[BP+4]
  IMUL CX
  MOV BX,AX
  XOR AX,AX
  MOV W[BX+p3a1o],AX
  INC W[SI+p3cdc]
  MOV W[SI+p3ce8],AX
o1f2o:
  ADD SP,0a
  POP BP
  RET

o1f25:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV W[BP+2],0
o1f3o:
  MOV AX,W[BP+2]
  CMP AX,W[p3cf6]
  JGE o1f44
  PUSH AX
  CALL o1f49
  MOV SP,BP
  INC W[BP+2]
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
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  MOV AX,W[SI+p3cdc]
  CMP AX,W[SI+p3ceo]
  JZ o1f6a
  PUSH W[BP+0a]
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
  MOV W[BP+2],0
o1f7a:
  MOV AX,W[BP+2]
  CMP AX,W[p3cf6]
  JGE o1fa3
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3cec],064
  JLE o1f9e
  PUSH W[BP+2]
  CALL o1f49
  MOV SP,BP
  PUSH W[BP+2]
  CALL o1def
  MOV SP,BP
o1f9e:
  INC W[BP+2]
  JMP o1f7a
o1fa3:
  ADD SP,4
  POP BP
  RET

o1fa8:
  PUSH BP
  SUB SP,0e
  MOV BP,SP
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  CMP W[SI+p3ce4],0
  JZ o1fc3
  MOV W[BP+0c],0f
  JMP o1fc8
o1fc3:
  MOV W[BP+0c],0
o1fc8:
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV W[BP],AX
  MOV AX,W[BP+012]
  MOV BX,03c
  IMUL BX
  MOV BX,W[SI+p3cdc]
  ADD BX,AX
  MOV W[BP+4],AX
  MOV AX,BX
  MOV CX,6
  IMUL CX
  MOV BX,AX
  MOV AX,W[SI+p39f8]
  MOV W[BX+p3aoc],AX
  MOV AX,W[BP+4]
  MOV BX,W[SI+p3cdc]
  ADD BX,AX
  MOV AX,BX
  IMUL CX
  MOV BX,AX
  MOV AX,W[SI+p39fc]
  MOV W[BX+p3aoe],AX
  MOV AX,W[SI+p3cdc]
  ADD AX,W[BP+4]
  IMUL CX
  MOV BX,AX
  MOV AX,W[BP+0c]
  MOV W[BX+p3a1o],AX
  PUSH AX
  PUSH W[SI+p39fc]
  PUSH W[SI+p39f8]
  CALL o933
  MOV SP,BP
  MOV BX,W[BP+012]
  SHL BX,1
  INC W[BX+p3cdc]
  CMP W[BX+p3cdc],03c
  MOV W[BP+0a],AX
  MOV W[BP],BX
  JL o2o47
  MOV W[BX+p3cdc],0
o2o47:
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV W[BP],AX
  CMP W[SI+p3ce4],0
  JZ o2o6o
  MOV W[SI+p3ce4],0
  JMP o2o6d
o2o6o:
  MOV AX,W[BP+012]
  SHL AX,1
  MOV SI,AX
  MOV W[SI+p3ce4],1
o2o6d:
  MOV AX,W[BP+0a]
  ADD SP,0e
  POP BP
  RET
