; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

PUBLIC o2o75,o2of4,o216o,o2187,o21ad,o21do,o2325,o235f,o24be
PUBLIC o2868,o287b,o289b,o28bc,o28dd,o28fe,o297a,o2beb,o2df5,o2e61,o2e7b,o2e98
PUBLIC o2efe,o2ff4,o2fff,o3o23,o3o47,o3o68,o3o89,o3ofa,o3167,o3172,o319b,o31c8
PUBLIC o3229,o3296,o33oo,o3339,o3372,o33af,o33df,o33fb,o34o6,o3411,o3424,o3437
PUBLIC o34c3,o3575,o35ee,o364c,o37oo,o37a2,o37aa,o37cf,o38d8,o38ef,o3963
PUBLIC o3aof,o3a65,o3bd3,o3cc3,o3ce6,o3d8b,o3dc8,o3e6d,o3f24,o3fb8,o4o9a,o415b
PUBLIC o41f3,o42d1,o4356,o435e

_TEXT SEGMENT WORD PUBLIC 'CODE'

o2o75:
  PUSH BP
  SUB SP,010
  MOV BP,SP
  MOV AX,W[BP+014]
  SHL AX,1
  MOV SI,AX
  MOV W[BP],AX
  MOV AX,W[BP+014]
  MOV BX,03c
  IMUL BX
  MOV BX,W[SI+p3ceo]
  ADD BX,AX
  MOV W[BP+4],AX
  MOV AX,BX
  MOV CX,6
  IMUL CX
  MOV BX,AX
  MOV AX,W[BP+4]
  MOV CX,W[SI+p3ceo]
  ADD CX,AX
  MOV AX,CX
  MOV DX,6
  IMUL DX
  MOV DI,AX
  MOV AX,W[SI+p3ceo]
  ADD AX,W[BP+4]
  MOV CX,6
  IMUL CX
  MOV SI,AX
  PUSH W[SI+p3a1o]
  PUSH W[DI+p3aoe]
  PUSH W[BX+p3aoc]
  CALL o933
  MOV SP,BP
  MOV BX,W[BP+014]
  SHL BX,1
  INC W[BX+p3ceo]
  CMP W[BX+p3ceo],03c
  MOV W[BP+0e],AX
  MOV W[BP],BX
  JL o2oec
  MOV W[BX+p3ceo],0
o2oec:
  MOV AX,W[BP+0e]
  ADD SP,010
  POP BP
  RET

o2of4:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  JMP o214e
o2ofc:
  INC W[p3cfo]
  JMP o215e
o21o2:
  INC W[p3cfo]
  DEC W[p3cf2]
  JMP o215e
o21oc:
  DEC W[p3cf2]
  JMP o215e
o2112:
  DEC W[p3cfo]
  DEC W[p3cf2]
  JMP o215e
o211c:
  DEC W[p3cfo]
  JMP o215e
o2122:
  DEC W[p3cfo]
  INC W[p3cf2]
  JMP o215e
o212c:
  INC W[p3cf2]
  JMP o215e
o2132:
  INC W[p3cfo]
  INC W[p3cf2]
  JMP o215e

o213e:
  DW offset o2ofc,offset o21o2,offset o21oc,offset o2112,offset o211c
  DW offset o2122,offset o212c,offset o2132

o214e:
  MOV SI,AX
  CMP SI,8
  JNB o215e
  SHL SI,1
  CS: JMP W[SI+o213e]
o215e:
  POP BP
  RET

o216o:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,W[BP+8]
  SHL AX,1
  MOV SI,AX
  DEC W[SI+p3ao4]
  MOV BX,W[SI+p3ao4]
  TEST BX,BX
  MOV W[BP],AX
  JNS o2182
  MOV W[SI+p3ao4],7
o2182:
  ADD SP,4
  POP BP
  RET

o2187:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,W[BP+8]
  SHL AX,1
  MOV SI,AX
  INC W[SI+p3ao4]
  CMP W[SI+p3ao4],7
  MOV W[BP],AX
  JLE o21a8
  MOV W[SI+p3ao4],0
o21a8:
  ADD SP,4
  POP BP
  RET

o21ad:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV W[p3d1o],050
  MOV W[p3d12],061
  MOV AX,2
  MOV W[p3d16],AX
  MOV W[p3d14],AX
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
  CMP W[p3do4],1
  JZ o21f1
  JMP o2311
o21f1:
  CMP W[p3do2],0
  JZ o21fb
  JMP o2311
o21fb:
  CALL o37oo
  CMP AX,063
  MOV W[BP+4],AX
  JL o22o9
  JMP o2311
o22o9:
  MOV AX,W[p3doo]
  MOV W[p3doe],AX
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  MOV AX,W[p3doe]
  CMP AX,W[BP+4]
  JNZ o2226
  CALL o287b
o2226:
  CALL o37a2
  TEST AX,AX
  JNZ o223o
  JMP o2311
o223o:
  CMP W[p3d16],2
  JNZ o2275
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[p3doo]
  MOV W[p3doa],AX
  MOV W[p3doe],CX
  MOV W[p3doc],BX
  CALL o2e7b
  PUSH W[p3doe]
  CALL o2df5
  MOV SP,BP
  CALL o2e61
  PUSH W[p3doe]
  CALL o2df5
  MOV SP,BP
  MOV AX,W[p3doa]
  MOV BX,W[p3doc]
  MOV W[p3d1c],AX
  MOV W[p3d1e],BX
  JMP o22b1
o2275:
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[p3doo]
  MOV W[p3doa],AX
  MOV W[p3doe],CX
  MOV W[p3doc],BX
  CALL o2e61
  PUSH W[p3doe]
  CALL o2df5
  MOV SP,BP
  CALL o2e7b
  PUSH W[p3doe]
  CALL o2df5
  MOV SP,BP
  MOV AX,W[p3doa]
  MOV BX,W[p3doc]
  MOV W[p3d1c],AX
  MOV W[p3d1e],BX
o22b1:
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[BP+4]
  PUSH CX
  MOV W[p3doa],AX
  MOV W[p3doe],CX
  MOV W[p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV W[BP+2],AX
  AND AX,01001
  JZ o2311
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[p3doo]
  XOR DX,DX
  MOV W[p3d1o],AX
  MOV AX,W[p3doe]
  MOV W[p3do8],AX
  MOV W[p3doo],AX
  MOV W[p3d14],CX
  MOV W[p3d1a],DX
  MOV W[p3do6],DX
  MOV W[p3do4],DX
  MOV W[p3d12],BX
o2311:
  CMP W[p3do4],1
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
  MOV CX,W[p3d1o]
  MOV DX,W[p3d12]
  MOV W[p3do4],AX
  MOV W[p3do2],AX
  MOV AX,W[p3d14]
  MOV B[pbb],0
  MOV W[p3doo],AX
  MOV W[p3cf8],CX
  MOV W[p3cfa],DX
  MOV W[p3d22],BX
  MOV W[p3d18],BX
  MOV W[p3do6],BX
  POP BP
  RET

o235f:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o45d7
  MOV W[p3d18],0
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[p3doo]
  CMP W[p3d16],2
  MOV W[p3cfc],AX
  MOV W[p3doa],AX
  MOV W[p3doe],CX
  MOV W[p3cfe],BX
  MOV W[p3doc],BX
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
  MOV W[BP+2],8
o23ab:
  CMP W[BP+2],0
  JLE o23f4
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  PUSH W[p3doe]
  MOV W[p3doa],AX
  MOV W[p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV W[BP+4],AX
  AND AX,01001
  JNZ o23f4
  CMP W[p3d16],2
  JNZ o23ec
  CALL o2e61
  JMP o23ef
o23ec:
  CALL o2e7b
o23ef:
  DEC W[BP+2]
  JMP o23ab
o23f4:
  MOV W[BP+2],8
o23f9:
  CMP W[BP+2],0
  JLE o245o
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  PUSH W[p3doe]
  MOV W[p3doa],AX
  MOV W[p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV W[BP+4],AX
  AND AX,0880
  JNZ o245o
  CMP W[p3d16],2
  JNZ o243a
  CALL o2e61
  JMP o243d
o243a:
  CALL o2e7b
o243d:
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV W[p3doa],AX
  MOV W[p3doc],BX
  DEC W[BP+2]
  JMP o23f9
o245o:
  CMP W[p3do2],0
  JZ o245c
  CALL o2beb
  JMP o2475
o245c:
  MOV AX,W[p3doa]
  MOV BX,W[p3doc]
  MOV CX,W[p3doe]
  MOV W[p3cf8],AX
  MOV W[p3doo],CX
  MOV W[p3cfa],BX
  CALL o28dd
o2475:
  CALL o28bc
  MOV W[BP+4],AX
  AND AX,0668
  JZ o2483
  CALL o28fe
o2483:
  MOV AX,W[BP+4]
  AND AX,0100
  JZ o2496
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
  JMP o24ac
o2496:
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[p3doo]
  MOV W[p3d1o],AX
  MOV W[p3d14],CX
  MOV W[p3d12],BX
o24ac:
  CMP W[p3do2],0
  JZ o24b9
  MOV W[p3do2],0
o24b9:
  ADD SP,6
  POP BP
  RET

o24be:
  PUSH BP
  SUB SP,0e
  MOV BP,SP
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV CX,W[p3doo]
  MOV W[p3cfc],AX
  MOV W[p3doa],AX
  MOV W[p3doe],CX
  MOV W[p3cfe],BX
  MOV W[p3doc],BX
  CALL o37a2
  TEST AX,AX
  JZ o24fo
  CALL o37oo
  MOV W[BP+0a],AX
  JMP o24f5
o24fo:
  MOV W[BP+0a],063
o24f5:
  MOV AX,W[BP+0a]
  CMP AX,063
  JGE o251a
  MOV W[p3doe],AX
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  MOV AX,W[p3doe]
  CMP AX,W[p3do8]
  JNZ o251a
  MOV W[BP+0a],063
o251a:
  MOV AX,W[BP+0a]
  CMP AX,063
  JGE o2561
  MOV W[p3doe],AX
  CALL o2e7b
  CALL o2e7b
  CALL o2e7b
  MOV AX,W[p3doe]
  CMP AX,W[p3do8]
  JNZ o254o
  CALL o2e61
  MOV AX,W[p3doe]
  MOV W[BP+0a],AX
o254o:
  MOV AX,W[BP+0a]
  MOV W[p3doe],AX
  CALL o2e61
  CALL o2e61
  CALL o2e61
  MOV AX,W[p3doe]
  CMP AX,W[p3do8]
  JNZ o2561
  CALL o2e7b
  MOV AX,W[p3doe]
  MOV W[BP+0a],AX
o2561:
  MOV AX,W[p3doo]
  CMP W[p3do6],0
  MOV W[p3doe],AX
  JNZ o257a
  CMP W[BP+0a],063
  JGE o257a
  MOV AX,W[BP+0a]
  MOV W[p3doe],AX
o257a:
  CMP W[BP+0a],063
  JNZ o258c
  CMP W[p3do6],0
  JNZ o258c
  CALL o2868
  JMP o25d2
o258c:
  PUSH W[p3doe]
  CALL o2df5
  MOV SP,BP
  MOV AX,W[p3doa]
  MOV BX,W[p3doc]
  XOR CX,CX
  PUSH CX
  PUSH BX
  PUSH AX
  MOV W[BP+6],AX
  MOV W[BP+8],BX
  CALL o933
  MOV SP,BP
  AND AX,0880
  JZ o25bd
  MOV W[p3do4],1
  MOV W[p3do6],0
o25bd:
  MOV AX,W[BP+6]
  MOV BX,W[BP+8]
  MOV CX,W[p3doe]
  MOV W[p3cf8],AX
  MOV W[p3doo],CX
  MOV W[p3cfa],BX
o25d2:
  MOV AX,W[p3doo]
  MOV W[p3doe],AX
  MOV W[BP+0a],AX
  CALL o2e61
  MOV W[BP+0c],0
o25e3:
  CMP W[BP+0c],3
  JGE o264e
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  PUSH W[p3doe]
  MOV W[p3doa],AX
  MOV W[p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  PUSH W[p3doe]
  MOV W[BP+4],AX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV BX,W[BP+4]
  OR BX,AX
  MOV W[BP+4],BX
  AND BX,0880
  JZ o2646
  MOV AX,W[p3doe]
  MOV W[p3do6],1
  MOV W[BP+0a],AX
o2646:
  CALL o2e7b
  INC W[BP+0c]
  JMP o25e3
o264e:
  MOV AX,W[p3doo]
  MOV BX,W[p3cf8]
  MOV CX,W[p3cfa]
  PUSH AX
  MOV W[p3doe],AX
  MOV W[p3doc],CX
  MOV W[p3doa],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  PUSH W[p3doe]
  MOV W[BP+4],AX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV BX,W[BP+4]
  OR BX,AX
  MOV W[BP+4],BX
  AND BX,0880
  JZ o26bo
  MOV AX,W[p3doe]
  MOV W[p3do6],1
  MOV W[BP+0a],AX
o26bo:
  MOV AX,W[p3doo]
  MOV W[p3doe],AX
  CALL o2e61
  MOV W[BP+0c],0
o26be:
  CMP W[BP+0c],3
  JGE o27o7
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  PUSH W[p3doe]
  MOV W[p3doa],AX
  MOV W[p3doc],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV W[BP+4],AX
  AND AX,0880
  JZ o26ff
  MOV AX,W[p3doe]
  MOV W[p3do6],1
  MOV W[BP+0a],AX
o26ff:
  CALL o2e7b
  INC W[BP+0c]
  JMP o26be
o27o7:
  MOV AX,W[p3doo]
  MOV BX,W[p3cf8]
  MOV CX,W[p3cfa]
  PUSH AX
  MOV W[p3doe],AX
  MOV W[p3doc],CX
  MOV W[p3doa],BX
  CALL o2df5
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[p3doc]
  PUSH W[p3doa]
  CALL o933
  MOV SP,BP
  MOV W[BP+4],AX
  AND AX,0880
  JZ o2747
  MOV AX,W[p3doe]
  MOV W[p3do6],1
  MOV W[BP+0a],AX
o2747:
  MOV AX,W[BP+0a]
  MOV W[p3doo],AX
  CALL o289b
  AND AX,08000
  JZ o276d
  CMP W[p3do6],0
  JNZ o276d
  MOV AX,W[p3cfc]
  MOV BX,W[p3cfe]
  MOV W[p3cf8],AX
  MOV W[p3cfa],BX
  CALL o2868
o276d:
  CALL o28dd
  CMP W[p3do4],0
  JNZ o27e1
  MOV AX,W[p3doo]
  XOR BX,BX
  PUSH BX
  PUSH W[p3cfa]
  PUSH W[p3cf8]
  MOV W[p3do8],AX
  CALL o933
  MOV SP,BP
  AND AX,1
  JNZ o2795
  JMP o283f
o2795:
  MOV AX,0f
  PUSH AX
  PUSH W[p3cfa]
  PUSH W[p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,W[p3d1a]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[p3cf8]
  MOV W[SI+p3d24],BX
  MOV AX,W[p3cfa]
  MOV W[SI+p4cc4],AX
  MOV AX,W[p3d1a]
  INC AX
  CMP AX,2000
  MOV W[p3d1a],AX
  JL o27d1
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
o27d1:
  MOV AX,W[p3d18]
  TEST AX,AX
  JZ o27dc
  DEC W[p3d18]
o27dc:
  CALL o45d7
  JMP o283f
o27e1:
  CMP W[p3d1a],1
  JLE o2824
  MOV AX,W[p3cfc]
  MOV BX,W[p3cfe]
  MOV B[pbb],0
  MOV W[p3d18],0
  MOV W[p3cf8],AX
  MOV W[p3cfa],BX
  CALL o2efe
  XOR AX,AX
  PUSH AX
  PUSH W[p3d1e]
  PUSH W[p3d1c]
  CALL o933
  MOV SP,BP
  AND AX,096
  JNZ o281c
  CALL o287b
o281c:
  MOV W[p3d22],0
  JMP o283f
o2824:
  CALL o2e98
  CMP W[p3d22],0
  JZ o2839
  CALL o287b
  MOV W[p3d22],0
  JMP o283f
o2839:
  MOV W[p3d22],1
o283f:
  CMP W[p3d18],064
  JLE o284f
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
o284f:
  CALL o28bc
  MOV W[BP+4],AX
  AND AX,0768
  JZ o2863
  MOV AX,3
  PUSH AX
  CALL o5858
  MOV SP,BP
o2863:
  ADD SP,0e
  POP BP
  RET

o2868:
  PUSH BP
  MOV BP,SP
  ADD W[p3d18],5
  PUSH W[p3d18]
  CALL o462o
  MOV SP,BP
  POP BP
  RET

o287b:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP W[p3d16],2
  JNZ o289o
  MOV W[p3d16],1
  JMP o2896
o289o:
  MOV W[p3d16],2
o2896:
  ADD SP,2
  POP BP
  RET

o289b:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,W[p3cf8]
  DEC AX
  DEC AX
  MOV BX,W[p3cfa]
  DEC BX
  DEC BX
  MOV CX,offset p5c7f
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
  MOV AX,W[p3cf8]
  DEC AX
  DEC AX
  MOV BX,W[p3cfa]
  DEC BX
  DEC BX
  MOV CX,offset p5c64
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
  MOV AX,W[p3cfc]
  DEC AX
  DEC AX
  MOV BX,W[p3cfe]
  DEC BX
  DEC BX
  MOV CX,offset p5c64
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
  MOV BX,W[p3cfa]
  DEC BX
  DEC BX
  MOV W[BP+6],AX
  MOV W[BP+4],BX
o2916:
  MOV AX,W[p3cfa]
  ADD AX,3
  MOV BX,W[BP+4]
  CMP BX,AX
  JGE o2972
  MOV AX,W[p3cf8]
  DEC AX
  DEC AX
  MOV W[BP+2],AX
o292b:
  MOV AX,W[p3cf8]
  ADD AX,3
  MOV BX,W[BP+2]
  CMP BX,AX
  JGE o296d
  XOR AX,AX
  PUSH AX
  PUSH W[BP+4]
  PUSH BX
  CALL o933
  MOV SP,BP
  AND AX,0668
  JZ o2965
  MOV SI,W[BP+6]
  MOV AL,B[SI+p5c64]
  XOR AH,AH
  CMP AX,0c
  JNZ o2965
  XOR AX,AX
  PUSH AX
  PUSH W[BP+4]
  PUSH W[BP+2]
  CALL o9ob
  MOV SP,BP
o2965:
  INC W[BP+6]
  INC W[BP+2]
  JMP o292b
o296d:
  INC W[BP+4]
  JMP o2916
o2972:
  CALL o3o68
  ADD SP,8
  POP BP
  RET

o297a:
  PUSH BP
  SUB SP,034
  MOV BP,SP
  CALL o48bd
  CMP W[p3do2],0
  JZ o298d
  JMP o2be6
o298d:
  CALL o28bc
  MOV AX,2
  MOV W[BP+0e],AX
  MOV BX,2
  CWD
  IDIV BX
  MOV W[BP+0c],AX
  MOV AX,BX
  MOV W[BP+012],AX
  CWD
  IDIV BX
  MOV BX,W[p3cf8]
  MOV CX,W[p3cfa]
  XOR DX,DX
  MOV W[BP+010],AX
  MOV W[BP+032],CX
  MOV W[BP+02e],CX
  MOV W[BP+02a],CX
  MOV W[BP+026],CX
  MOV W[BP+022],CX
  MOV W[BP+01e],CX
  MOV W[BP+01a],CX
  MOV W[BP+016],CX
  MOV W[BP+8],DX
  MOV W[BP+0a],DX
  MOV W[BP+030],BX
  MOV W[BP+02c],BX
  MOV W[BP+028],BX
  MOV W[BP+024],BX
  MOV W[BP+020],BX
  MOV W[BP+01c],BX
  MOV W[BP+018],BX
  MOV W[BP+014],BX
o29ea:
  CMP W[BP+0a],02d
  JL o29f3
  JMP o2beo
o29f3:
  CMP W[BP+8],02d
  JL o29fc
  JMP o2ae8
o29fc:
  MOV AX,W[BP+014]
  INC AX
  INC AX
  MOV BX,W[BP+016]
  INC BX
  INC BX
  ADD W[BP+018],2
  SUB W[BP+01a],2
  SUB W[BP+01c],2
  SUB W[BP+01e],2
  SUB W[BP+020],2
  ADD W[BP+022],2
  MOV W[BP+014],AX
  MOV AX,W[BP+0e]
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,W[BP+014]
  MOV W[BP+0c],AX
  ADD AX,CX
  MOV DX,W[BP+0c]
  MOV W[BP+016],BX
  SUB BX,DX
  SUB CX,DX
  MOV W[BP],AX
  MOV AX,W[BP+016]
  ADD AX,DX
  MOV DX,0c
  PUSH DX
  PUSH AX
  PUSH CX
  PUSH BX
  PUSH W[BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+0c]
  MOV BX,W[BP+018]
  SUB BX,AX
  MOV CX,W[BP+01a]
  SUB CX,AX
  MOV DX,W[BP+018]
  ADD DX,AX
  MOV W[BP],BX
  MOV BX,W[BP+01a]
  ADD BX,AX
  MOV AX,0c
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH W[BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+01c]
  MOV BX,W[BP+0c]
  ADD BX,AX
  MOV CX,W[BP+0c]
  MOV DX,W[BP+01e]
  SUB DX,CX
  SUB AX,CX
  MOV W[BP+4],AX
  MOV AX,W[BP+01e]
  ADD AX,CX
  MOV CX,0c
  PUSH CX
  PUSH AX
  PUSH W[BP+4]
  PUSH DX
  PUSH BX
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+0c]
  MOV BX,W[BP+020]
  SUB BX,AX
  MOV CX,W[BP+022]
  SUB CX,AX
  MOV DX,W[BP+020]
  ADD DX,AX
  MOV W[BP],BX
  MOV BX,W[BP+022]
  ADD BX,AX
  MOV AX,0c
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH W[BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+0e]
  CMP AX,01e
  JGE o2ae5
  INC W[BP+0e]
o2ae5:
  INC W[BP+8]
o2ae8:
  CMP W[BP+8],010
  JG o2af1
  JMP o29ea
o2af1:
  MOV AX,W[BP+024]
  INC AX
  INC AX
  MOV BX,W[BP+026]
  INC BX
  INC BX
  ADD W[BP+028],2
  SUB W[BP+02a],2
  SUB W[BP+02c],2
  SUB W[BP+02e],2
  SUB W[BP+030],2
  ADD W[BP+032],2
  MOV W[BP+024],AX
  MOV AX,W[BP+012]
  MOV CX,2
  CWD
  IDIV CX
  MOV CX,W[BP+024]
  MOV W[BP+010],AX
  ADD AX,CX
  MOV DX,W[BP+010]
  MOV W[BP+026],BX
  SUB BX,DX
  SUB CX,DX
  MOV W[BP],AX
  MOV AX,W[BP+026]
  ADD AX,DX
  MOV DX,0c
  PUSH DX
  PUSH AX
  PUSH CX
  PUSH BX
  PUSH W[BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+010]
  MOV BX,W[BP+028]
  SUB BX,AX
  MOV CX,W[BP+02a]
  SUB CX,AX
  MOV DX,W[BP+028]
  ADD DX,AX
  MOV W[BP],BX
  MOV BX,W[BP+02a]
  ADD BX,AX
  MOV AX,0c
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH W[BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+02c]
  MOV BX,W[BP+010]
  ADD BX,AX
  MOV CX,W[BP+010]
  MOV DX,W[BP+02e]
  SUB DX,CX
  SUB AX,CX
  MOV W[BP+4],AX
  MOV AX,W[BP+02e]
  ADD AX,CX
  MOV CX,0c
  PUSH CX
  PUSH AX
  PUSH W[BP+4]
  PUSH DX
  PUSH BX
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+010]
  MOV BX,W[BP+030]
  SUB BX,AX
  MOV CX,W[BP+032]
  SUB CX,AX
  MOV DX,W[BP+030]
  ADD DX,AX
  MOV W[BP],BX
  MOV BX,W[BP+032]
  ADD BX,AX
  MOV AX,0c
  PUSH AX
  PUSH BX
  PUSH DX
  PUSH CX
  PUSH W[BP]
  CALL ob18
  MOV SP,BP
  CALL o48d7
  MOV AX,W[BP+012]
  CMP AX,01e
  JGE o2bda
  INC W[BP+012]
o2bda:
  INC W[BP+0a]
  JMP o29ea
o2beo:
  CALL o2325
  CALL o2e98
o2be6:
  ADD SP,034
  POP BP
  RET

o2beb:
  PUSH BP
  SUB SP,02a
  MOV BP,SP
  CALL o49oa
  CMP W[p3do2],0
  JNZ o2bfe
  JMP o2dfo
o2bfe:
  MOV AX,W[p3cf8]
  MOV BX,W[p3cfa]
  MOV W[BP+2],0
  MOV W[BP+026],AX
  MOV W[BP+022],AX
  MOV W[BP+01e],AX
  MOV W[BP+01a],AX
  MOV W[BP+016],AX
  MOV W[BP+012],AX
  MOV W[BP+0e],AX
  MOV W[BP+0a],AX
  MOV W[BP+028],BX
  MOV W[BP+024],BX
  MOV W[BP+020],BX
  MOV W[BP+01c],BX
  MOV W[BP+018],BX
  MOV W[BP+014],BX
  MOV W[BP+010],BX
  MOV W[BP+0c],BX
o2c3a:
  CMP W[BP+2],028
  JGE o2c85
  ADD W[BP+0a],2
  ADD W[BP+0c],2
  ADD W[BP+0e],2
  SUB W[BP+010],2
  SUB W[BP+012],2
  SUB W[BP+014],2
  SUB W[BP+016],2
  ADD W[BP+018],2
  ADD W[BP+01a],2
  ADD W[BP+01c],2
  ADD W[BP+01e],2
  SUB W[BP+020],2
  SUB W[BP+022],2
  SUB W[BP+024],2
  SUB W[BP+026],2
  ADD W[BP+028],2
  INC W[BP+2]
  JMP o2c3a
o2c85:
  MOV AX,028
  MOV W[BP+2],AX
  MOV W[BP+4],AX
o2c8e:
  CMP W[BP+4],0
  JNZ o2c97
  JMP o2dfo
o2c97:
  CMP W[BP+2],0
  JNZ o2cao
  JMP o2d42
o2cao:
  SUB W[BP+0a],2
  SUB W[BP+0c],2
  SUB W[BP+0e],2
  ADD W[BP+010],2
  ADD W[BP+012],2
  ADD W[BP+014],2
  ADD W[BP+016],2
  SUB W[BP+018],2
  MOV AX,0c
  PUSH AX
  PUSH W[BP+0c]
  PUSH W[BP+0a]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[p3cfa]
  PUSH W[BP+0a]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+010]
  PUSH W[BP+0e]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+010]
  PUSH W[p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+014]
  PUSH W[BP+012]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[p3cfa]
  PUSH W[BP+012]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+018]
  PUSH W[p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+018]
  PUSH W[BP+016]
  CALL o933
  MOV SP,BP
  CALL o492a
  DEC W[BP+2]
o2d42:
  CMP W[BP+2],014
  JL o2d4b
  JMP o2c8e
o2d4b:
  SUB W[BP+01a],2
  SUB W[BP+01c],2
  SUB W[BP+01e],2
  ADD W[BP+020],2
  ADD W[BP+022],2
  ADD W[BP+024],2
  ADD W[BP+026],2
  SUB W[BP+028],2
  MOV AX,0c
  PUSH AX
  PUSH W[BP+01c]
  PUSH W[BP+01a]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[p3cfa]
  PUSH W[BP+01a]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+020]
  PUSH W[BP+01e]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+020]
  PUSH W[p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+024]
  PUSH W[BP+022]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[p3cfa]
  PUSH W[BP+022]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+028]
  PUSH W[p3cf8]
  CALL o933
  MOV SP,BP
  MOV AX,0c
  PUSH AX
  PUSH W[BP+028]
  PUSH W[BP+026]
  CALL o933
  MOV SP,BP
  CALL o492a
  DEC W[BP+4]
  JMP o2c8e
o2dfo:
  ADD SP,02a
  POP BP
  RET

o2df5:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  JMP o2e4f
o2dfd:
  INC W[p3doa]
  JMP o2e5f
o2eo3:
  INC W[p3doa]
  DEC W[p3doc]
  JMP o2e5f
o2eod:
  DEC W[p3doc]
  JMP o2e5f
o2e13:
  DEC W[p3doa]
  DEC W[p3doc]
  JMP o2e5f
o2e1d:
  DEC W[p3doa]
  JMP o2e5f
o2e23:
  DEC W[p3doa]
  INC W[p3doc]
  JMP o2e5f
o2e2d:
  INC W[p3doc]
  JMP o2e5f
o2e33:
  INC W[p3doa]
  INC W[p3doc]
  JMP o2e5f

o2e3f:
  DW offset o2dfd,offset o2eo3,offset o2eod,offset o2e13,offset o2e1d
  DW offset o2e23,offset o2e2d,offset o2e33

o2e4f:
  MOV SI,AX
  CMP SI,8
  JNB o2e5f
  SHL SI,1
  CS: JMP W[SI+o2e3f]
o2e5f:
  POP BP
  RET

o2e61:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,W[p3doe]
  DEC AX
  MOV W[p3doe],AX
  JGE o2e76
  MOV W[p3doe],7
o2e76:
  ADD SP,2
  POP BP
  RET

o2e7b:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,W[p3doe]
  INC AX
  CMP AX,7
  MOV W[p3doe],AX
  JLE o2e93
  MOV W[p3doe],0
o2e93:
  ADD SP,2
  POP BP
  RET

o2e98:
  PUSH BP
  SUB SP,0e
  MOV BP,SP
  MOV W[BP+0a],0
o2ea3:
  MOV AX,W[p3d1a]
  MOV BX,W[BP+0a]
  CMP BX,AX
  JGE o2ef9
  TEST AX,AX
  JLE o2ef9
  SHL BX,1
  XOR AX,AX
  PUSH AX
  PUSH W[BX+p4cc4]
  PUSH W[BX+p3d24]
  CALL o9ob
  MOV SP,BP
  MOV W[BP+0c],AX
  AND AX,08080
  JNZ o2ef4
  MOV AX,W[BP+0a]
  SHL AX,1
  MOV SI,AX
  PUSH W[BP+0c]
  MOV W[BP+4],SI
  MOV W[BP+2],SI
  CALL o34c3
  MOV SP,BP
  PUSH AX
  MOV SI,W[BP+4]
  PUSH W[SI+p4cc4]
  MOV SI,W[BP+2]
  PUSH W[SI+p3d24]
  CALL o9ob
  MOV SP,BP
o2ef4:
  INC W[BP+0a]
  JMP o2ea3
o2ef9:
  ADD SP,0e
  POP BP
  RET

o2efe:
  PUSH BP
  SUB SP,0c
  MOV BP,SP
  CALL o4631
  MOV W[BP+8],0
o2foc:
  MOV AX,W[BP+8]
  CMP AX,W[p3d1a]
  JGE o2f2f
  SHL AX,1
  MOV SI,AX
  MOV AX,7
  PUSH AX
  PUSH W[SI+p4cc4]
  PUSH W[SI+p3d24]
  CALL o9ob
  MOV SP,BP
  INC W[BP+8]
  JMP o2foc
o2f2f:
  MOV W[pd1],0
  CALL o18ec
  CALL o1a11
  PUSH W[p3d2o]
  CALL o64o
  MOV SP,BP
  MOV W[pcb],0
  PUSH W[p3d2o]
  PUSH W[p38ce]
  PUSH W[p38ca]
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
  PUSH W[p38ce]
  PUSH W[p38ca]
  CALL o3o89
  MOV SP,BP
  CALL o47o7
  CALL o47o7
  CALL o47o7
  CALL o47o7
  CALL o18bf
  CALL o18ec
  MOV W[pcb],1
  CALL o5c3
  MOV AX,W[pd1]
  ADD AX,W[p3d1a]
  MOV W[pd1],AX
  CALL o5d66
  MOV SI,offset p5c9a
  PUSH SI
  CALL o5ca2
  MOV SI,offset p5ca2
  PUSH SI
  CALL o5993
  LEA SI,W[BP]
  MOV W[SI+6],AX
  MOV W[SI+4],BX
  MOV W[SI+2],CX
  MOV W[SI],DX
  MOV SI,offset p5caa
  MOV AX,W[SI+6]
  MOV BX,W[SI+4]
  MOV CX,W[SI+2]
  MOV DX,W[SI]
  LEA SI,W[BP]
  PUSH SI
  CALL o5f1b
  CALL o5dce
  PUSH AX
  MOV W[BP+8],AX
  CALL o3963
  MOV SP,BP
  MOV W[p3d1a],0
  ADD SP,0c
  POP BP
  RET

o2ff4:
  PUSH BP
  MOV BP,SP
  MOV AX,W[BP+4]
  MOV W[p3d2o],AX
  POP BP
  RET

o2fff:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,W[BP+6]
  MOV BX,7
  IMUL BX
  ADD AX,01e
  MOV BX,offset p5c7f
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
  MOV AX,W[BP+6]
  MOV BX,7
  IMUL BX
  ADD AX,01e
  MOV BX,offset p5c64
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
  MOV AX,W[p3cf8]
  DEC AX
  DEC AX
  MOV BX,W[p3cfa]
  DEC BX
  DEC BX
  MOV CX,offset p5c64
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
  MOV AX,W[p3cf8]
  DEC AX
  DEC AX
  MOV BX,W[p3cfa]
  DEC BX
  DEC BX
  MOV CX,offset p5c64
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
  MOV BX,W[BP+6]
  MOV CX,W[BP+8]
  PUSH W[BP+0c]
  MOV W[p5cd6],AX
  MOV W[p5cd4],AX
  MOV W[p5cb4],CX
  MOV W[p5cb2],BX
  CALL o3437
  MOV SP,BP
  MOV BX,W[BP+0a]
  PUSH BX
  MOV W[p5cca],AX
  MOV W[p5cc2],BX
  CALL o3437
  MOV SP,BP
  XOR BX,BX
  PUSH BX
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  MOV W[p5cc6],AX
  CALL o933
  MOV SP,BP
  PUSH AX
  MOV W[p5cc8],AX
  CALL o34c3
  MOV SP,BP
  MOV W[p5ccc],0
  MOV BX,W[p5cc8]
  CMP BX,W[p5cc6]
  MOV W[p5cc4],AX
  JZ o3of2
  AND BX,08080
  JZ o3ofa
o3of2:
  MOV AX,1
  ADD SP,2
  POP BP
  RET

o3ofa:
  MOV AX,W[p5cb4]
  MOV W[p5cbc],AX
  CALL o3372
o31o3:
  CALL o33df
  TEST AX,AX
  JZ o315f
  CALL o33af
  XOR AX,AX
  PUSH AX
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o933
  MOV SP,BP
  CMP AX,W[p5cc6]
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
  MOV AX,W[p5cb4]
  MOV BX,W[p5cb6]
  MOV CX,W[p5cb8]
  MOV W[p5cbc],AX
  MOV W[p5cco],CX
  MOV W[p5cbe],BX
  JMP o31o3
o315f:
  MOV AX,W[p5ccc]
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
  PUSH W[p5cc2]
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o793
  MOV SP,BP
  MOV W[p5cb2],AX
  DEC AX
  MOV W[p5cb8],AX
  CALL o34o6
  ADD SP,6
  POP BP
  RET

o319b:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o33fb
  DEC W[p5cb2]
  PUSH W[p5cc2]
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o82b
  MOV SP,BP
  MOV W[p5cb2],AX
  INC AX
  MOV W[p5cb6],AX
  CALL o34o6
  ADD SP,6
  POP BP
  RET

o31c8:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CALL o3411
  MOV AX,W[p5cb6]
  INC W[p5cb4]
  CMP AX,W[p5cb8]
  MOV W[p5cb2],AX
  JNZ o31fa
  XOR AX,AX
  PUSH AX
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o933
  MOV SP,BP
  CMP AX,W[p5cc8]
  JNZ o31fa
  CALL o3372
o31fa:
  SUB W[p5cb4],2
  MOV AX,W[p5cb2]
  CMP AX,W[p5cb8]
  JNZ o3221
  XOR AX,AX
  PUSH AX
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o933
  MOV SP,BP
  CMP AX,W[p5cc8]
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
  MOV AX,W[p5cb4]
  INC AX
  CMP AX,063
  JLE o324o
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o324o:
  CALL o3411
  MOV AX,W[p5cb6]
  INC W[p5cb4]
  MOV W[p5cb2],AX
o324d:
  MOV AX,W[p5cb2]
  CMP AX,W[p5cb8]
  JGE o328e
  PUSH W[p5cb8]
  PUSH W[p5cc4]
  PUSH W[p5cb4]
  PUSH AX
  CALL o71d
  MOV SP,BP
  CMP AX,W[p5cb8]
  MOV W[p5cb2],AX
  JG o328e
  CALL o3372
  PUSH W[p5cb8]
  PUSH W[p5cc4]
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o6a7
  MOV SP,BP
  MOV W[p5cb2],AX
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
  MOV AX,W[p5cb4]
  DEC AX
  JGE o32aa
  MOV AX,1
  ADD SP,2
  POP BP
  RET
o32aa:
  CALL o3411
  MOV AX,W[p5cb6]
  DEC W[p5cb4]
  MOV W[p5cb2],AX
o32b7:
  MOV AX,W[p5cb2]
  CMP AX,W[p5cb8]
  JGE o32f8
  PUSH W[p5cb8]
  PUSH W[p5cc4]
  PUSH W[p5cb4]
  PUSH AX
  CALL o71d
  MOV SP,BP
  CMP AX,W[p5cb8]
  MOV W[p5cb2],AX
  JG o32f8
  CALL o3372
  PUSH W[p5cb8]
  PUSH W[p5cc4]
  PUSH W[p5cb4]
  PUSH W[p5cb2]
  CALL o6a7
  MOV SP,BP
  MOV W[p5cb2],AX
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
  MOV AX,W[p5cbc]
  INC AX
  MOV BX,W[p5cb4]
  CMP BX,AX
  JNZ o3332
  MOV AX,W[p5cbe]
  DEC AX
  MOV BX,W[p5cb6]
  CMP BX,AX
  JLE o3332
  MOV AX,W[p5cco]
  INC AX
  MOV BX,W[p5cb8]
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
  MOV AX,W[p5cbc]
  DEC AX
  MOV BX,W[p5cb4]
  CMP BX,AX
  JNZ o336b
  MOV AX,W[p5cbe]
  DEC AX
  MOV BX,W[p5cb6]
  CMP BX,AX
  JLE o336b
  MOV AX,W[p5cco]
  INC AX
  MOV BX,W[p5cb8]
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
  MOV AX,W[p5cd4]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[p5cb2]
  MOV W[SI+p5cd8],BX
  MOV AX,W[p5cb4]
  MOV W[SI+p64a8],AX
  MOV AX,W[p5cd4]
  INC AX
  CMP AX,W[p5cd6]
  MOV W[p5cd4],AX
  JLE o339e
  MOV W[p5cd6],AX
o339e:
  MOV AX,W[p5cd4]
  CMP AX,03e8
  JL o33aa
  DEC W[p5cd4]
o33aa:
  ADD SP,4
  POP BP
  RET

o33af:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,W[p5cd4]
  DEC AX
  MOV W[p5cd4],AX
  JGE o33c4
  MOV W[p5cd4],0
o33c4:
  MOV AX,W[p5cd4]
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p5cd8]
  MOV AX,W[SI+p64a8]
  MOV W[p5cb4],AX
  MOV W[p5cb2],BX
  ADD SP,4
  POP BP
  RET

o33df:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP W[p5cd4],0
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
  MOV AX,W[p5cb2]
  MOV W[p5cce],AX
  POP BP
  RET

o34o6:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p5cce]
  MOV W[p5cb2],AX
  POP BP
  RET

o3411:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p5cb2]
  MOV BX,W[p5cb4]
  MOV W[p5cdo],AX
  MOV W[p5cd2],BX
  POP BP
  RET

o3424:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p5cdo]
  MOV BX,W[p5cd2]
  MOV W[p5cb2],AX
  MOV W[p5cb4],BX
  POP BP
  RET

o3437:
  PUSH BP
  MOV BP,SP
  PUSH CX
  MOV CX,W[BP+4]
  MOV AX,CX
  CMP CX,010
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
  MOV AX,W[BP+4]
  MOV CX,1
  XOR BX,BX
l1:
  CMP AX,CX
  JZ l2
  SHL CX,1
  INC BX
  CMP BX,010
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
  MOV AL,063
  XOR BX,BX
  MOV W[p6c82],1
  MOV B[pd4],AL
  MOV B[pd3],AL
  MOV W[BP+4],BX
  MOV W[p6c84],BX
o3592:
  CMP W[BP+4],0a
  JGE o35e9
  MOV DX,0201
  XOR AL,AL
  OUT DX,AL
  IN AL,DX
  AND AX,3
  JNZ o35b8
  MOV W[p6c82],0
o35b8:
  MOV W[BP+2],0
o35bd:
  IN AL,DX
  AND AX,3
  JZ o35d7
  CMP W[BP+2],0ff
  JGE o35d7
  INC W[BP+2]
  JMP o35bd
o35d7:
  CMP W[BP+2],0fa
  JLE o35e4
  MOV W[p6c82],0
o35e4:
  INC W[BP+4]
  JMP o3592
o35e9:
  ADD SP,6
  POP BP
  RET

o35ee:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AL,B[pd4]
  XOR AH,AH
  MOV BL,B[pd3]
  XOR BH,BH
  CMP BX,063
  MOV W[p6c78],AX
  MOV W[BP],BX
  JGE o36oe
  MOV W[p6c78],BX
o36oe:
  MOV B[pd4],063
  CMP B[pba],0
  JZ o3622
  MOV W[p6c84],1
  JMP o3628
o3622:
  MOV W[p6c84],0
o3628:
  CMP W[p6c82],0
  JZ o3647
  CALL o4f2
  CMP W[pd9],0
  JZ o3641
  MOV W[p6c84],1
  JMP o3647
o3641:
  MOV W[p6c84],0
o3647:
  ADD SP,4
  POP BP
  RET

o364c:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV W[BP+4],1
o3657:
  CMP W[BP+4],0
  JZ o3693
  CMP W[p6c82],0
  JZ o3673
  CALL o4f2
  CMP W[pd9],0
  JZ o3673
  MOV W[BP+4],0
o3673:
  MOV AL,B[pc3]
  XOR AH,AH
  TEST AX,AX
  MOV W[BP],AX
  JZ o3657
  AND AX,080
  JNZ o3657
  XOR AX,AX
  MOV B[pc3],0
  MOV W[p6c82],AX
  MOV W[BP+4],AX
  JMP o3657
o3693:
  CMP W[p6c82],0
  JZ o36fb
  CALL o4f2
  MOV AX,W[pd5]
  SUB AX,01e
  MOV W[p6c7a],AX
  JGE o36ae
  MOV W[p6c7a],0
o36ae:
  ADD W[p6c7a],5
  MOV AX,W[pd7]
  SUB AX,01e
  MOV W[p6c7c],AX
  JGE o36c4
  MOV W[p6c7c],0
o36c4:
  ADD W[p6c7c],5
  MOV AX,W[pd5]
  ADD AX,01e
  CMP AX,0ff
  MOV W[p6c7e],AX
  JLE o36dd
  MOV W[p6c7e],0ff
o36dd:
  SUB W[p6c7e],5
  MOV AX,W[pd7]
  ADD AX,01e
  CMP AX,0ff
  MOV W[p6c8o],AX
  JLE o36f6
  MOV W[p6c8o],0ff
o36f6:
  SUB W[p6c8o],5
o36fb:
  ADD SP,6
  POP BP
  RET

o37oo:
  PUSH BP
  SUB SP,4
  MOV BP,SP
  MOV AX,W[p6c78]
  MOV W[BP+2],AX
  CMP W[p6c82],0
  JNZ o3716
  JMP o379a
o3716:
  MOV W[BP+2],063
  MOV AX,W[pd5]
  CMP AX,W[p6c7a]
  JGE o3745
  MOV W[BP+2],4
  MOV AX,W[pd7]
  CMP AX,W[p6c7c]
  JGE o3737
  MOV W[BP+2],3
o3737:
  MOV AX,W[pd7]
  CMP AX,W[p6c8o]
  JLE o3745
  MOV W[BP+2],5
o3745:
  MOV AX,W[pd5]
  CMP AX,W[p6c7e]
  JLE o376f
  MOV W[BP+2],0
  MOV AX,W[pd7]
  CMP AX,W[p6c7c]
  JGE o3761
  MOV W[BP+2],1
o3761:
  MOV AX,W[pd7]
  CMP AX,W[p6c8o]
  JLE o376f
  MOV W[BP+2],7
o376f:
  MOV AX,W[pd5]
  CMP AX,W[p6c7a]
  JL o379a
  CMP AX,W[p6c7e]
  JG o379a
  MOV AX,W[pd7]
  CMP AX,W[p6c7c]
  JGE o378c
  MOV W[BP+2],2
o378c:
  MOV AX,W[pd7]
  CMP AX,W[p6c8o]
  JLE o379a
  MOV W[BP+2],6
o379a:
  MOV AX,W[BP+2]
  ADD SP,4
  POP BP
  RET

o37a2:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p6c84]
  POP BP
  RET

o37aa:
  PUSH BP
  MOV BP,SP
  XOR AX,AX
  MOV W[p6c96],2
  MOV W[p6c98],0f
  MOV BX,1
  PUSH BX
  MOV W[p6c92],AX
  MOV W[p6c94],AX
  CALL o2ff4
  MOV SP,BP
  CALL o3cc3
  POP BP
  RET

o37cf:
  PUSH BP
  SUB SP,0c
  MOV BP,SP
  MOV W[p6c9o],0
  MOV W[p6c8e],0
  CALL o1o9a
  MOV AX,1
  MOV W[BP+8],AX
  MOV W[BP+6],AX
o37fo:
  CMP W[BP+8],0b
  JGE o385f
  MOV W[BP+0a],0
o37fb:
  MOV AX,W[BP+0a]
  CMP AX,3
  JGE o381f
  MOV BX,W[BP+8]
  SHL BX,1
  SHL BX,1
  ADD BX,AX
  MOV SI,W[BP+6]
  MOV AL,B[SI+p215o]
  MOV B[BX+p6cfa],AL
  INC W[BP+6]
  INC W[BP+0a]
  JMP o37fb
o381f:
  ADD W[BP+6],2
  MOV W[BP+0a],0
o3828:
  MOV AX,W[BP+0a]
  CMP AX,6
  JGE o3846
  MOV SI,W[BP+6]
  MOV AL,B[SI+p215o]
  MOV DI,W[BP+0a]
  MOV B[DI+p6c9c],AL
  INC W[BP+6]
  INC W[BP+0a]
  JMP o3828
o3846:
  MOV AX,W[BP+8]
  SHL AX,1
  SHL AX,1
  ADD AX,offset p6cce
  PUSH AX
  MOV AX,offset p6c9c
  PUSH AX
  CALL o42d1
  MOV SP,BP
  INC W[BP+8]
  JMP o37fo
o385f:
  MOV AL,B[p215o]
  XOR AH,AH
  CMP AX,073
  JZ o389a
  MOV W[BP+4],0
o386e:
  MOV AX,W[BP+4]
  CMP AX,0b
  JGE o389a
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV W[SI+p6cdo],0
  MOV W[SI+p6cce],0
  ADD AX,offset p6cfa
  MOV BX,offset p6dfa
  PUSH BX
  PUSH AX
  CALL o5bab
  MOV SP,BP
  INC W[BP+4]
  JMP o386e
o389a:
  ADD SP,0c
  POP BP
  RET

o38d8:
  PUSH BP
  MOV BP,SP
  XOR AX,AX
  XOR BX,BX
  MOV W[p6c8c],AX
  MOV W[p6c88],AX
  MOV W[p6c8a],BX
  MOV W[p6c86],BX
  POP BP
  RET

o38ef:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  MOV AX,W[p6c98]
  DEC AX
  MOV W[p6c98],AX
  JNZ o395e
  MOV AX,W[p6c96]
  JMP o394a
o39o3:
  MOV W[p6c98],0c
  MOV W[p6c96],3
  MOV AX,4
  PUSH AX
  CALL o2ff4
  MOV SP,BP
  JMP o395b
o391a:
  MOV W[p6c98],8
  MOV W[p6c96],5
  MOV AX,2
  PUSH AX
  CALL o2ff4
  MOV SP,BP
  JMP o395b
o3931:
  MOV W[p6c98],012
  MOV W[p6c96],2
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
  MOV AX,W[BP+8]
  MOV W[p6c94],AX
  MOV AX,W[p6c96]
  JMP o39c6
o3974:
  MOV AX,W[p6c94]
  SUB AX,W[p6c92]
  XOR BX,BX
  TEST AX,AX
  JNS o3982
  DEC BX
o3982:
  ADD W[p6c86],AX
  ADC W[p6c88],BX
  JMP o39d5
o398c:
  MOV AX,W[p6c94]
  SUB AX,W[p6c92]
  MOV BX,5
  IMUL BX
  XOR BX,BX
  TEST AX,AX
  JNS o399f
  DEC BX
o399f:
  ADD W[p6c86],AX
  ADC W[p6c88],BX
  JMP o39d5
o39a9:
  MOV AX,W[p6c94]
  SUB AX,W[p6c92]
  MOV BX,0a
  IMUL BX
  XOR BX,BX
  TEST AX,AX
  JNS o39bc
  DEC BX
o39bc:
  ADD W[p6c86],AX
  ADC W[p6c88],BX
  JMP o39d5
o39c6:
  CMP AX,5
  JZ o39a9
  CMP AX,3
  JZ o398c
  CMP AX,2
  JZ o3974
o39d5:
  MOV AX,W[p6c88]
  MOV BX,W[p6c86]
  MOV CX,0f
  MOV DX,0423f
  CALL o6of2
  JLE o39f3
  MOV W[p6c88],0
  MOV W[p6c86],0
o39f3:
  MOV AX,W[p6c94]
  CMP AX,0320
  MOV W[p6c92],AX
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

o3aof:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p6c96]
  JMP o3a52
o3a17:
  MOV AX,offset p6d26
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,08a
  PUSH AX
  CALL oc83
  MOV SP,BP
  JMP o3a63
o3a2a:
  MOV AX,offset p6d67
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,08a
  PUSH AX
  CALL oc83
  MOV SP,BP
  JMP o3a63
o3a3d:
  MOV AX,offset p6da8
  PUSH AX
  MOV AX,1
  PUSH AX
  MOV AX,08a
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

o3a65:
  PUSH BP
  SUB SP,8
  MOV BP,SP
  CALL o3cc3
  MOV AX,W[p6c88]
  MOV BX,W[p6c86]
  MOV CX,W[p6cf8]
  MOV DX,W[p6cf6]
  CALL o6of2
  JLE o3aef
  MOV AX,0b
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,014
  PUSH AX
  MOV AX,0a
  PUSH AX
  MOV AX,offset p6dfe
  PUSH AX
  CALL o4feb
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  MOV AX,013
  PUSH AX
  MOV AX,095
  PUSH AX
  MOV AX,013
  PUSH AX
  MOV AX,0a
  PUSH AX
  CALL oab6
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  MOV AX,01b
  PUSH AX
  MOV AX,095
  PUSH AX
  MOV AX,01b
  PUSH AX
  MOV AX,0a
  PUSH AX
  CALL oab6
  MOV SP,BP
  CALL o57d5
  MOV AX,014
  PUSH AX
  MOV AX,0a
  PUSH AX
  MOV AX,offset p6dfe
  PUSH AX
  CALL o4feb
  MOV SP,BP
  CALL o5c3
  CALL o3fb8
  CALL o415b
  CALL o3f24
  JMP o3bce
o3aef:
  MOV W[BP+2],02b
o3af4:
  CMP W[BP+2],036
  JGE o3b15
  XOR AX,AX
  PUSH AX
  PUSH W[BP+2]
  MOV AX,07f
  PUSH AX
  PUSH W[BP+2]
  MOV AX,01e
  PUSH AX
  CALL oab6
  MOV SP,BP
  INC W[BP+2]
  JMP o3af4
o3b15:
  MOV AX,7
  PUSH AX
  MOV AX,02a
  PUSH AX
  MOV AX,07f
  PUSH AX
  MOV AX,02a
  PUSH AX
  MOV AX,01e
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,036
  PUSH AX
  MOV AX,07f
  PUSH AX
  MOV AX,02a
  PUSH AX
  MOV AX,07f
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,036
  PUSH AX
  MOV AX,01e
  PUSH AX
  MOV AX,036
  PUSH AX
  MOV AX,07f
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  MOV AX,02a
  PUSH AX
  MOV AX,01e
  PUSH AX
  MOV AX,036
  PUSH AX
  MOV AX,01e
  PUSH AX
  CALL oab6
  MOV SP,BP
  MOV AX,7
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV W[BP+2],1
o3b87:
  CMP W[BP+2],01e
  JGE o3bab
  PUSH W[BP+2]
  CALL o5o29
  MOV SP,BP
  MOV AX,02d
  PUSH AX
  MOV AX,022
  PUSH AX
  MOV AX,offset p6eod
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,8
  PUSH AX
  CALL o41c    ;Delay don't know
  POP AX
  INC W[BP+2]
  JMP o3b87
o3bab:
  MOV AX,0b
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,02d
  PUSH AX
  MOV AX,022
  PUSH AX
  MOV AX,offset p6eod
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

o3bd3:
  PUSH BP
  SUB SP,0c
  MOV BP,SP
  MOV AX,W[p6c94]
  MOV BX,0a
  CWD
  IDIV BX
  SUB AX,050
  CMP AX,1
  MOV W[BP+8],AX
  JGE o3bf2
  MOV W[BP+8],0
o3bf2:
  MOV AX,1000
  IMUL W[BP+8]
  XOR BX,BX
  TEST AX,AX
  JNS o3bff
  DEC BX
o3bff:
  ADD W[p6c86],AX
  ADC W[p6c88],BX
  MOV W[BP],AX
  MOV W[BP+8],AX
  MOV W[BP+2],BX
  TEST AX,AX
  JNZ o3c17
  JMP o3cbe
o3c17:
  MOV CX,offset p6e17
  PUSH CX
  MOV CX,offset p6c9c
  PUSH CX
  MOV W[BP+4],AX
  MOV W[BP+6],BX
  CALL o5bab
  MOV SP,BP
  XOR AX,AX
  PUSH AX
  PUSH W[BP+6]
  PUSH W[BP+4]
  MOV AX,offset p6c9c
  PUSH AX
  CALL o41f3
  MOV SP,BP
  MOV AX,offset p6c9c
  PUSH AX
  CALL o5ad5
  MOV SP,BP
  MOV BX,0b
  PUSH BX
  MOV W[BP+8],AX
  CALL o5odd
  MOV SP,BP
  MOV AX,026
  PUSH AX
  MOV AX,02d
  PUSH AX
  MOV AX,offset p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,02d
  PUSH AX
  PUSH AX
  MOV AX,offset p6e2o
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,034
  PUSH AX
  MOV AX,02d
  PUSH AX
  MOV AX,offset p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,03b
  PUSH AX
  MOV AX,02d
  PUSH AX
  MOV AX,offset p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,W[BP+8]
  MOV BX,5
  IMUL BX
  MOV BX,050
  SUB BX,AX
  MOV AX,03b
  PUSH AX
  PUSH BX
  MOV AX,offset p6c9c
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,042
  PUSH AX
  MOV AX,02d
  PUSH AX
  MOV AX,offset p6e18
  PUSH AX
  CALL o4feb
  MOV SP,BP
o3cbe:
  ADD SP,0c
  POP BP
  RET

o3cc3:
  PUSH BP
  MOV BP,SP
  MOV AX,2
  PUSH AX
  MOV AX,1
  PUSH AX
  PUSH W[p6c88]
  PUSH W[p6c86]
  CALL o3ce6
  MOV SP,BP
  CALL o3d8b
  CALL o3aof
  CALL o3dc8
  POP BP
  RET

o3ce6:
  PUSH BP
  SUB SP,0c
  MOV BP,SP
  MOV W[BP+6],0
  MOV W[BP+0a],1
  MOV W[BP+8],086a0
o3cfb:
  MOV AX,W[BP+0a]
  MOV BX,W[BP+8]
  XOR CX,CX
  MOV DX,1
  CALL o6of2
  JLE o3d7o
  MOV AX,W[BP+012]
  MOV BX,W[BP+010]
  MOV CX,W[BP+0a]
  MOV DX,W[BP+8]
  CALL o5afb
  MOV AX,W[BP+012]
  MOV W[BP+4],BX
  MOV BX,W[BP+010]
  MOV CX,W[BP+0a]
  MOV DX,W[BP+8]
  CALL o5afb
  MOV W[BP+012],CX
  MOV W[BP+010],DX
  CMP W[BP+4],0
  JNZ o3d45
  CMP W[BP+8],086a0
  JNZ o3d43
  CMP W[BP+0a],1
o3d43:
  JZ o3d57
o3d45:
  MOV AX,W[BP+014]
  ADD AX,W[BP+6]
  PUSH W[BP+016]
  PUSH AX
  PUSH W[BP+4]
  CALL o4b72
  MOV SP,BP
o3d57:
  MOV AX,W[BP+0a]
  MOV BX,W[BP+8]
  XOR CX,CX
  MOV DX,0a
  CALL o5afb
  INC W[BP+6]
  MOV W[BP+0a],AX
  MOV W[BP+8],BX
  JMP o3cfb
o3d7o:
  MOV AX,W[BP+010]
  MOV BX,W[BP+014]
  ADD BX,5
  PUSH W[BP+016]
  PUSH BX
  PUSH AX
  MOV W[BP+4],AX
  CALL o4b72
  MOV SP,BP
  ADD SP,0c
  POP BP
  RET

o3d8b:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  CALL o58a4
  DEC AX
  MOV W[BP+2],1
  MOV W[BP+4],AX
o3d9d:
  CMP W[BP+2],5
  JGE o3dc3
  CMP W[BP+4],0
  JLE o3db3
  PUSH W[BP+2]
  CALL o3o23
  MOV SP,BP
  JMP o3dbb
o3db3:
  PUSH W[BP+2]
  CALL o2fff
  MOV SP,BP
o3dbb:
  DEC W[BP+4]
  INC W[BP+2]
  JMP o3d9d
o3dc3:
  ADD SP,6
  POP BP
  RET

o3dc8:
  PUSH BP
  SUB SP,0c
  MOV BP,SP
  MOV W[BP+2],01a
  MOV AX,W[p6c94]
  MOV W[BP+6],0
  MOV W[BP+8],064
  MOV W[BP+0a],AX
o3de3:
  MOV AX,W[BP+8]
  CMP AX,1
  JLE o3e2f
  MOV AX,W[BP+0a]
  CWD
  IDIV W[BP+8]
  MOV W[BP+4],AX
  MOV AX,W[BP+0a]
  CWD
  IDIV W[BP+8]
  MOV W[BP+0a],DX
  CMP W[BP+4],0
  JNZ o3eob
  CMP W[BP+8],0a
  JNZ o3e1e
o3eob:
  MOV AX,W[BP+2]
  ADD AX,W[BP+6]
  MOV BX,2
  PUSH BX
  PUSH AX
  PUSH W[BP+4]
  CALL o4b72
  MOV SP,BP
o3e1e:
  MOV AX,W[BP+8]
  MOV BX,0a
  CWD
  IDIV BX
  INC W[BP+6]
  MOV W[BP+8],AX
  JMP o3de3
o3e2f:
  MOV AX,W[BP+0a]
  MOV BX,W[BP+2]
  ADD BX,3
  MOV CX,2
  PUSH CX
  PUSH BX
  PUSH AX
  MOV W[BP+4],AX
  CALL o4b72
  MOV SP,BP
  MOV AX,0f
  PUSH AX
  MOV AX,6
  PUSH AX
  MOV AX,072
  PUSH AX
  CALL o9ob
  MOV SP,BP
  MOV AX,offset p6de9
  PUSH AX
  MOV AX,2
  PUSH AX
  MOV AX,07b
  PUSH AX
  CALL oc83
  MOV SP,BP
  ADD SP,0c
  POP BP
  RET

o3e6d:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,01a
  PUSH AX
  MOV AX,1
  PUSH AX
  CALL o1o61
  MOV SP,BP
  MOV AX,3
  PUSH AX
  MOV AX,offset p6e28
  PUSH AX
  CALL o5535
  MOV SP,BP
  MOV W[BP+4],2
  MOV W[BP+2],1
o3e97:
  CMP W[BP+2],0b
  JL o3eao
  JMP o3f1f
o3eao:
  MOV AX,offset p6e17
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5bab
  MOV SP,BP
  MOV AX,W[BP+2]
  SHL AX,1
  SHL AX,1
  ADD AX,offset p6cfa
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,offset p6e34
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,W[BP+2]
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV AX,1
  PUSH AX
  PUSH W[SI+p6cdo]
  PUSH W[SI+p6cce]
  MOV AX,offset p6c9c
  PUSH AX
  CALL o41f3
  MOV SP,BP
  MOV AX,offset p6c9c
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,W[BP+2]
  INC AX
  INC AX
  MOV BX,01a
  PUSH BX
  PUSH AX
  CALL o1o61
  MOV SP,BP
  PUSH W[BP+4]
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5535
  MOV SP,BP
  MOV W[BP+4],1
  INC W[BP+2]
  JMP o3e97
o3f1f:
  ADD SP,6
  POP BP
  RET

o3f24:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV AX,offset p6e37
  PUSH AX
  MOV AX,offset p215o
  PUSH AX
  CALL o5bab
  MOV SP,BP
  MOV W[BP+2],1
o3f3c:
  CMP W[BP+2],0b
  JGE o3fad
  MOV AX,offset p6e17
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5bab
  MOV SP,BP
  MOV AX,W[BP+2]
  SHL AX,1
  SHL AX,1
  ADD AX,offset p6cfa
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,offset p6e34
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,W[BP+2]
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV AX,1
  PUSH AX
  PUSH W[SI+p6cdo]
  PUSH W[SI+p6cce]
  MOV AX,offset p6c9c
  PUSH AX
  CALL o41f3
  MOV SP,BP
  MOV AX,offset p6c9c
  PUSH AX
  MOV AX,offset p6ca6
  PUSH AX
  CALL o5ede
  MOV SP,BP
  MOV AX,offset p6ca6
  PUSH AX
  MOV AX,offset p215o
  PUSH AX
  CALL o5ede
  MOV SP,BP
  INC W[BP+2]
  JMP o3f3c
o3fad:
  CALL o1oc3
  ADD SP,6
  POP BP
  RET

o3fb8:
  PUSH BP
  SUB SP,0a
  MOV BP,SP
  MOV AX,7
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,032
  PUSH AX
  MOV AX,01e
  PUSH AX
  MOV AX,offset p6e39
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,03c
  PUSH AX
  MOV AX,028
  PUSH AX
  MOV AX,offset p6e44
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,0f
  PUSH AX
  CALL o5odd
  MOV SP,BP
  MOV AX,050
  PUSH AX
  MOV AX,037
  PUSH AX
  MOV AX,offset p6e4d
  PUSH AX
  CALL o4feb
  MOV SP,BP
  MOV AX,offset p6dfa
  PUSH AX
  MOV AX,offset p6cfa
  PUSH AX
  CALL o5bab
  MOV SP,BP
  XOR AX,AX
  MOV W[BP+8],AX
  MOV W[p6c9a],AX
o4o18:
  CMP W[BP+8],3
  JGE o4o9o
  MOV W[BP+6],0
o4o23:
  CMP W[BP+6],0
  JNZ o4o63
  CMP W[p6c9a],0
  JNZ o4o63
  MOV AX,W[BP+8]
  MOV BX,014
  IMUL BX
  ADD AX,037
  MOV BX,050
  PUSH BX
  PUSH AX
  CALL o4o9a
  MOV SP,BP
  MOV W[BP+6],AX
  CMP W[BP+8],0
  JZ o4o56
  CMP AX,0e
  JNZ o4o56
  DEC W[BP+8]
o4o56:
  PUSH W[BP+6]
  CALL o53cd
  MOV SP,BP
  MOV W[BP+6],AX
  JMP o4o23
o4o63:
  CMP W[BP+6],0
  JZ o4o8b
  MOV AX,W[BP+8]
  MOV BX,014
  IMUL BX
  ADD AX,037
  MOV BX,050
  PUSH BX
  PUSH AX
  PUSH W[BP+6]
  CALL o4c8a
  MOV SP,BP
  MOV AX,W[BP+6]
  MOV SI,W[BP+8]
  MOV B[SI+p6cfa],AL
o4o8b:
  INC W[BP+8]
  JMP o4o18
o4o9o:
  MOV B[pc3],0
  ADD SP,0a
  POP BP
  RET

o4o9a:
  PUSH BP
  SUB SP,6
  MOV BP,SP
  MOV B[pc3],0
  MOV W[BP+4],0
o4oaa:
  CMP W[BP+4],032
  JL o4ob3
  JMP o414e
o4ob3:
  PUSH W[BP+0c]
  PUSH W[BP+0a]
  MOV AX,05f
  PUSH AX
  CALL o4c8a
  MOV SP,BP
  MOV W[BP+2],0
o4oc7:
  CMP W[BP+2],01e
  JGE o4of6
  MOV AL,B[pc3]
  XOR AH,AH
  AND AX,080
  JNZ o4oe8
  CMP B[pc3],0
  JZ o4oe8
  MOV AL,B[pc3]
  XOR AH,AH
  ADD SP,6
  POP BP
  RET
o4oe8:
  MOV AX,5
  PUSH AX
  CALL o41c       ;Delay don't know
  MOV SP,BP
  INC W[BP+2]
  JMP o4oc7
o4of6:
  PUSH W[BP+0c]
  PUSH W[BP+0a]
  MOV AX,020
  PUSH AX
  CALL o4c8a
  MOV SP,BP
  MOV W[BP+2],0
o41oa:
  CMP W[BP+2],032
  JGE o4148
  MOV AL,B[pc3]
  XOR AH,AH
  AND AX,080
  JNZ o413a
  CMP B[pc3],0
  JZ o413a
  PUSH W[BP+0c]
  PUSH W[BP+0a]
  MOV AX,05f
  PUSH AX
  CALL o4c8a
  MOV SP,BP
  MOV AL,B[pc3]
  XOR AH,AH
  ADD SP,6
  POP BP
  RET
o413a:
  MOV AX,5
  PUSH AX
  CALL o41c
  MOV SP,BP     ;Delay don't know
  INC W[BP+2]
  JMP o41oa
o4148:
  INC W[BP+4]
  JMP o4oaa
o414e:
  MOV W[p6c9a],1
  XOR AX,AX
  ADD SP,6
  POP BP
  RET

o415b:
  PUSH BP
  SUB SP,0a
  MOV BP,SP
  MOV W[BP+8],0a
o4166:
  MOV AX,W[BP+8]
  CMP AX,1
  JLE o418d
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV AX,W[p6c88]
  MOV BX,W[p6c86]
  MOV CX,W[SI+p6ccc]
  MOV DX,W[SI+p6cca]
  CALL o6of2
  JL o418d
  DEC W[BP+8]
  JMP o4166
o418d:
  MOV W[BP+6],0a
o4192:
  MOV AX,W[BP+6]
  CMP AX,W[BP+8]
  JLE o41c8
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV BX,W[SI+p6ccc]
  MOV CX,W[SI+p6cca]
  MOV W[SI+p6cdo],BX
  MOV W[SI+p6cce],CX
  MOV W[BP],AX
  ADD AX,offset p6cfa
  MOV BX,SI
  ADD BX,offset p6cf6
  PUSH BX
  PUSH AX
  CALL o5bab
  MOV SP,BP
  DEC W[BP+6]
  JMP o4192
o41c8:
  MOV AX,W[BP+8]
  SHL AX,1
  SHL AX,1
  MOV SI,AX
  MOV BX,W[p6c88]
  MOV CX,W[p6c86]
  MOV W[SI+p6cdo],BX
  MOV W[SI+p6cce],CX
  ADD AX,offset p6cfa
  MOV BX,offset p6cfa
  PUSH BX
  PUSH AX
  CALL o5bab
  MOV SP,BP
  ADD SP,0a
  POP BP
  RET

o41f3:
  PUSH BP
  SUB SP,01c
  MOV BP,SP
  XOR AX,AX
  MOV W[BP+0c],1
  MOV W[BP+0a],086a0
  MOV BX,offset p6e17
  PUSH BX
  PUSH W[BP+020]
  MOV W[BP+8],AX
  MOV W[BP+6],AX
  CALL o5bab
  MOV SP,BP
o4217:
  MOV AX,W[BP+0c]
  MOV BX,W[BP+0a]
  XOR CX,CX
  MOV DX,1
  CALL o6of2
  JG o422a
  JMP o42ac
o422a:
  MOV AX,W[BP+024]
  MOV BX,W[BP+022]
  MOV CX,W[BP+0c]
  MOV DX,W[BP+0a]
  CALL o5afb
  MOV AX,W[BP+024]
  MOV W[BP+4],BX
  MOV BX,W[BP+022]
  MOV CX,W[BP+0c]
  MOV DX,W[BP+0a]
  CALL o5afb
  MOV AX,0a
  PUSH AX
  PUSH W[BP+4]
  LEA AX,W[BP+012]
  PUSH AX
  MOV W[BP+024],CX
  MOV W[BP+022],DX
  CALL o5bca
  MOV SP,BP
  CMP W[BP+4],0
  JNZ o426d
  CMP W[BP+8],0
  JZ o428o
o426d:
  LEA AX,W[BP+012]
  PUSH AX
  PUSH W[BP+020]
  CALL o5ede
  MOV SP,BP
  MOV W[BP+8],1
  JMP o4292
o428o:
  CMP W[BP+026],0
  JZ o4292
  MOV AX,offset p6e53
  PUSH AX
  PUSH W[BP+020]
  CALL o5ede
  MOV SP,BP
o4292:
  MOV AX,W[BP+0c]
  MOV BX,W[BP+0a]
  XOR CX,CX
  MOV DX,0a
  CALL o5afb
  INC W[BP+6]
  MOV W[BP+0c],AX
  MOV W[BP+0a],BX
  JMP o4217
o42ac:
  MOV AX,W[BP+022]
  MOV BX,0a
  PUSH BX
  PUSH AX
  LEA BX,W[BP+012]
  PUSH BX
  MOV W[BP+4],AX
  CALL o5bca
  MOV SP,BP
  LEA AX,W[BP+012]
  PUSH AX
  PUSH W[BP+020]
  CALL o5ede
  MOV SP,BP
  ADD SP,01c
  POP BP
  RET

o42d1:
  PUSH BP
  SUB SP,0e
  MOV BP,SP
  MOV W[BP+6],0
  MOV W[BP+0c],1
  MOV W[BP+0a],086a0
  MOV SI,W[BP+014]
  MOV W[SI+2],0
  MOV W[SI],0
o42f2:
  MOV AX,W[BP+0c]
  MOV BX,W[BP+0a]
  XOR CX,CX
  XOR DX,DX
  CALL o6of2
  JLE o4351
  MOV BX,W[BP+012]
  ADD BX,W[BP+6]
  MOV AL,B[BX]
  XOR AH,AH
  PUSH AX
  CALL o536d
  MOV SP,BP
  XOR BX,BX
  TEST AX,AX
  JNS o4318
  DEC BX
o4318:
  MOV W[BP],AX
  MOV W[BP+4],AX
  MOV AX,W[BP+0c]
  MOV W[BP+2],BX
  MOV BX,W[BP+0a]
  MOV CX,W[BP+2]
  MOV DX,W[BP]
  CALL o5a54
  MOV SI,W[BP+014]
  ADD W[SI],BX
  ADC W[SI+2],AX
  MOV AX,W[BP+0c]
  MOV BX,W[BP+0a]
  XOR CX,CX
  MOV DX,0a
  CALL o5afb
  INC W[BP+6]
  MOV W[BP+0c],AX
  MOV W[BP+0a],BX
  JMP o42f2
o4351:
  ADD SP,0e
  POP BP
  RET

o4356:
  PUSH BP
  MOV BP,SP
  MOV AX,W[p6c96]
  POP BP
  RET

o435e:
  PUSH BP
  SUB SP,2
  MOV BP,SP
  CMP B[pco],0
  JZ o4378
  CMP W[p6e5a],0
  JNZ o4378
  MOV W[p6e5a],1
o4378:
  CMP B[pco],0
  JNZ o4398
  CMP W[p6e5a],0
  JZ o4398
  MOV W[p6e5a],0
  MOV AX,028
  PUSH AX
  CALL o4b46
  MOV SP,BP
  CALL o49f7
o4398:
  MOV AL,B[p38c2]
  XOR AH,AH
  CMP AX,W[p6e56]
  JZ o43c2
  CMP W[p6e5a],0
  JZ o43c2
  CALL o586e
  TEST AX,AX
  JNZ o43c2
  MOV AL,B[p38c2]
  XOR AH,AH
  MOV W[p6e56],AX
  CALL o44f4
  CALL o45e2
  CALL o4964
o43c2:
  ADD SP,2
  POP BP
  RET
