; Styx Remastered
; Copyright (c) Andrew Jenner 1998-2004

p      MOV AX,W[p]
p      MOV W[p],BX

p2     MOV W[p2],AX

p4     CMP W[p4],020
p4     INC W[p4]
p4     MOV AX,W[p4]
p4     PUSH W[p4]

p46    MOV AX,offset p46

p79    MOV SI,offset p79

p7b    MOV B[p7b],AL
p7b    MOV B[p7b],AL

p87    MOV SI,offset p87

p95    CMP W[p95],0
p95    CMP W[p95],AX
p95    MOV AX,W[p95]
p95    MOV AX,W[p95]
p95    MOV AX,W[p95]
p95    MOV AX,W[p95]
p95    MOV W[p95],AX
p95    MOV W[p95],AX
p95    NEG W[p95]
p95    PUSH W[p95]

p97    CMP W[p97],0
p97    MOV AX,W[p97]
p97    MOV AX,W[p97]
p97    MOV AX,W[p97]
p97    MOV W[p97],AX
p97    NEG W[p97]
p97    POP W[p97]

p99    ADD W[p99],AX
p99    CMP W[p99],AX
p99    MOV W[p99],AX
p99    SUB W[p99],AX

p9b    ADD BL,B[p9b]
p9b    MOV B[p9b],0
p9b    MOV B[p9b],AL

p9c    ADD BH,B[p9c]
p9c    MOV AL,B[p9c]
p9c    MOV B[p9c],0
p9c    MOV B[p9c],0ff
p9c    MOV B[p9c],1

p9d    ADD BL,B[p9d]
p9d    MOV AL,B[p9d]
p9d    MOV B[p9d],0
p9d    MOV B[p9d],0ff
p9d    MOV B[p9d],1

p9e    ADD BH,B[p9e]
p9e    MOV B[p9e],0
p9e    MOV B[p9e],AL

p9f    CMP W[p9f],AX
p9f    INC W[p9f]
p9f    MOV W[p9f],1

pa1    MOV AX,W[pa1]
pa1    MOV W[pa1],AX
pa1    MOV W[pa1],AX
pa1    MOV W[pa1],AX
pa1    SUB AX,W[pa1]

pa3    MOV AX,W[pa3]
pa3    MOV W[pa3],AX
pa3    MOV W[pa3],AX
pa3    MOV W[pa3],AX
pa3    SUB AX,W[pa3]

pa5    MOV AX,W[pa5]
pa5    MOV W[pa5],AX
pa5    MOV W[pa5],AX
pa5    MOV W[pa5],AX

pa7    MOV AX,W[pa7]
pa7    MOV W[pa7],AX
pa7    MOV W[pa7],AX
pa7    MOV W[pa7],AX

pa9    MOV CH,B[pa9]
pa9    MOV B[pa9],AL
pa9    MOV B[pa9],AL
pa9    MOV B[pa9],AL

paa    MOV BL,B[paa]
paa    MOV B[paa],AL
paa    MOV B[paa],AL
paa    MOV B[paa],AL

pab    MOV CL,B[pab]
pab    MOV B[pab],CL

pb0    CMP B[pbo],0
pb0    CMP B[pbo],0ff
pb0    CMP B[pbo],0ff
pb0    MOV B[pbo],0
pb0    MOV B[pbo],0ff

pb1    CMP B[pb1],0
pb1    CMP B[pb1],0ff
pb1    CMP B[pb1],0ff
pb1    MOV B[pb1],0
pb1    MOV B[pb1],0ff

pb2    CMP B[pb2],0
pb2    MOV B[pb2],0
pb2    MOV B[pb2],0ff

pb3    CMP B[pb3],0
pb3    MOV B[pb3],0
pb3    MOV B[pb3],0ff

pb4    CMP B[pb4],0
pb4    MOV B[pb4],0
pb4    MOV B[pb4],0ff

pb5    CMP B[pb5],0
pb5    MOV B[pb5],0
pb5    MOV B[pb5],0ff

pb6    CMP B[pb6],0
pb6    MOV B[pb6],0
pb6    MOV B[pb6],0ff

pb7    CMP B[pb7],0
pb7    MOV B[pb7],0
pb7    MOV B[pb7],0ff

pb8    CMP B[pb8],1
pb8    CMP B[pb8],2
pb8    MOV B[pb8],0
pb8    MOV B[pb8],0
pb8    MOV B[pb8],1
pb8    MOV B[pb8],1
pb8    MOV B[pb8],2
pb8    MOV B[pb8],2

pb9    MOV B[pb9],1
pb9    MOV B[pb9],2

pba    CMP B[pba],0
pba    MOV B[pba],0
pba    MOV B[pba],0ff

pbb    MOV B[pbb],0
pbb    MOV B[pbb],0
pbb    MOV B[pbb],0ff

pbc    CMP B[pbc],0ff
pbc    CMP B[pbc],0ff
pbc    MOV B[pbc],0
pbc    MOV B[pbc],0ff

pbd    CMP B[pbd],0ff
pbd    MOV B[pbd],0
pbd    MOV B[pbd],0ff

pbe    CMP B[pbe],0ff
pbe    MOV B[pbe],0
pbe    MOV B[pbe],0ff

pbf    CMP B[pbf],0ff
pbf    MOV B[pbf],0
pbf    MOV B[pbf],0ff

pc0    CMP B[pco],0
pc0    CMP B[pco],0
pc0    MOV W[pco],0
pc0    XOR B[pco],0ff

pc1    MOV B[pc1],0ff

pc2    CMP B[pc2],054
pc2    CMP B[pc2],05e
pc2    DEC B[pc2]
pc2    INC B[pc2]
pc2    MOV AL,B[pc2]
pc2    MOV AL,B[pc2]
pc2    MOV B[pc2],055
pc2    MOV B[pc2],05d

pc3    CMP B[pc3],0
pc3    CMP B[pc3],0
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV AL,B[pc3]
pc3    MOV B[pc3],0
pc3    MOV B[pc3],0
pc3    MOV B[pc3],0
pc3    MOV B[pc3],0
pc3    MOV B[pc3],0
pc3    MOV B[pc3],0
pc3    MOV B[pc3],0
pc3    MOV B[pc3],AL

pc6    ES: CMP B[pc6],CH
pc6    ES: CMP B[pc6],CH
pc6    ES: MOV B[pc6],AL
pc6    ES: MOV B[pc6],AL

pc7    ES: CMP W[pc7],04e
pc7    ES: INC W[pc7]
pc7    ES: MOV W[pc7],0

pc9    ES: CMP W[pc9],0
pc9    ES: CMP W[pc9],0
pc9    ES: CMP W[pc9],0

pcb    ES: CMP W[pcb],0
pcb    ES: CMP W[pcb],0
pcb    MOV W[pcb],0
pcb    MOV W[pcb],0
pcb    MOV W[pcb],0
pcb    MOV W[pcb],1
pcb    MOV W[pcb],1
pcb    MOV W[pcb],1
pcb    MOV W[pcb],1
pcb    MOV W[pcb],1
pcb    MOV W[pcb],AX
pcb    MOV W[pcb],AX

pcd    ES: CMP W[pcd],0
pcd    ES: CMP W[pcd],0
pcd    ES: CMP W[pcd],0a0
pcd    ES: CMP W[pcd],0a0
pcd    ES: CMP W[pcd],AX
pcd    ES: CMP W[pcd],AX
pcd    ES: CMP W[pcd],AX
pcd    ES: CMP W[pcd],AX
pcd    ES: DEC W[pcd]
pcd    ES: DEC W[pcd]
pcd    ES: INC W[pcd]
pcd    ES: INC W[pcd]
pcd    ES: INC W[pcd]
pcd    ES: INC W[pcd]
pcd    ES: INC W[pcd]
pcd    ES: INC W[pcd]
pcd    ES: MOV AX,W[pcd]
pcd    ES: MOV AX,W[pcd]
pcd    ES: MOV AX,W[pcd]
pcd    ES: MOV AX,W[pcd]
pcd    MOV W[pcd],AX
pcd    MOV W[pcd],AX
pcd    MOV W[pcd],AX
pcd    MOV W[pcd],AX

pcf    ES: MOV AX,W[pcf]
pcf    ES: MOV AX,W[pcf]
pcf    ES: MOV AX,W[pcf]
pcf    ES: MOV AX,W[pcf]
pcf    MOV W[pcf],AX
pcf    MOV W[pcf],AX

pd1    ES: INC W[pd1]
pd1    ES: INC W[pd1]
pd1    ES: INC W[pd1]
pd1    ES: INC W[pd1]
pd1    MOV AX,W[pd1]
pd1    MOV W[pd1],0
pd1    MOV W[pd1],AX

pd3    CMP B[pd3],0
pd3    CMP B[pd3],1
pd3    CMP B[pd3],2
pd3    CMP B[pd3],3
pd3    CMP B[pd3],4
pd3    CMP B[pd3],5
pd3    CMP B[pd3],6
pd3    CMP B[pd3],7
pd3    MOV BL,B[pd3]
pd3    MOV B[pd3],0
pd3    MOV B[pd3],0
pd3    MOV B[pd3],063
pd3    MOV B[pd3],1
pd3    MOV B[pd3],1
pd3    MOV B[pd3],2
pd3    MOV B[pd3],2
pd3    MOV B[pd3],3
pd3    MOV B[pd3],3
pd3    MOV B[pd3],4
pd3    MOV B[pd3],4
pd3    MOV B[pd3],5
pd3    MOV B[pd3],5
pd3    MOV B[pd3],6
pd3    MOV B[pd3],6
pd3    MOV B[pd3],7
pd3    MOV B[pd3],7
pd3    MOV B[pd3],AL

pd4    MOV AL,B[pd4]
pd4    MOV B[pd4],0
pd4    MOV B[pd4],0
pd4    MOV B[pd4],063
pd4    MOV B[pd4],1
pd4    MOV B[pd4],1
pd4    MOV B[pd4],2
pd4    MOV B[pd4],2
pd4    MOV B[pd4],3
pd4    MOV B[pd4],3
pd4    MOV B[pd4],4
pd4    MOV B[pd4],4
pd4    MOV B[pd4],5
pd4    MOV B[pd4],5
pd4    MOV B[pd4],6
pd4    MOV B[pd4],6
pd4    MOV B[pd4],7
pd4    MOV B[pd4],7
pd4    MOV B[pd4],AL

pd5    ES: MOV W[pd5],BX
pd5    MOV AX,W[pd5]
pd5    MOV AX,W[pd5]
pd5    MOV AX,W[pd5]
pd5    MOV AX,W[pd5]
pd5    MOV AX,W[pd5]

pd7    ES: MOV W[pd7],CX
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]
pd7    MOV AX,W[pd7]

pd9    CMP W[pd9],0
pd9    CMP W[pd9],0
pd9    ES: MOV W[pd9],0
pd9    ES: MOV W[pd9],0ff

pdb    ES: MOV W[pdb],0
pdb    ES: MOV W[pdb],0ff

p12e   ADD DI,offset p12e
p12e   MOV SI,offset p12e

p2150  MOV AL,B[SI+p215o]
p2150  MOV AL,B[p215o]
p2150  MOV AX,offset p215o
p2150  MOV DX,offset p215o

p2354  MOV SI,offset p2354

p38bc  CMP W[p38bc],0
p38bc  CMP W[p38bc],1
p38bc  MOV W[p38bc],AX
p38bc  MOV W[p38bc],AX
p38bc  MOV W[p38bc],BX

p38be  MOV AX,W[p38be]
p38be  MOV W[p38be],AX

p38c0  ADD W[p38co],AX

p38c2  INC B[p38c2]
p38c2  MOV AL,B[p38c2]
p38c2  MOV AL,B[p38c2]
p38c2  MOV AL,B[p38c2]

p38c3  MOV CX,W[p38c3]
p38c3  MOV W[p38c3],AX

p38ca  ADD W[BX+p38ca],CX
p38ca  CMP W[SI+p38ca],09c
p38ca  CMP W[SI+p38ca],3
p38ca  MOV AX,W[DI+p38ca]
p38ca  MOV AX,W[DI+p38ca]
p38ca  MOV AX,W[p38ca]
p38ca  MOV BX,W[p38ca]
p38ca  MOV CX,W[BX+p38ca]
p38ca  MOV CX,W[BX+p38ca]
p38ca  MOV DX,W[BX+p38ca]
p38ca  MOV W[SI+p38ca],050
p38ca  MOV W[SI+p38ca],BX
p38ca  PUSH W[p38ca]
p38ca  PUSH W[p38ca]

p38cc  PUSH W[p38cc]

p38ce  ADD W[BX+p38ce],CX
p38ce  CMP W[SI+p38ce],060
p38ce  CMP W[SI+p38ce],0b
p38ce  MOV AX,W[DI+p38ce]
p38ce  MOV AX,W[DI+p38ce]
p38ce  MOV AX,W[p38ce]
p38ce  MOV BX,W[BX+p38ce]
p38ce  MOV BX,W[p38ce]
p38ce  MOV CX,W[BX+p38ce]
p38ce  MOV DX,W[BX+p38ce]
p38ce  MOV W[SI+p38ce],01e
p38ce  MOV W[SI+p38ce],AX
p38ce  PUSH W[p38ce]
p38ce  PUSH W[p38ce]

p38d0  PUSH W[p38do]

p38d2  MOV CX,W[BX+p38d2]
p38d2  MOV W[SI+p38d2],AX

p38d6  MOV CX,W[BX+p38d6]
p38d6  MOV W[SI+p38d6],AX

p38da  MOV W[SI+p38da],AX
p38da  PUSH W[SI+p38da]
p38da  PUSH W[SI+p38da]

p38de  ADD W[SI+p38de],0168
p38de  ADD W[SI+p38de],BX
p38de  CMP W[SI+p38de],0168
p38de  MOV BX,W[SI+p38de]
p38de  MOV W[SI+p38de],BX
p38de  PUSH W[BX+p38de]
p38de  PUSH W[SI+p38de]
p38de  SUB W[SI+p38de],0168

p38e2  MOV AX,W[SI+p38e2]
p38e2  MOV BX,W[SI+p38e2]
p38e2  MOV W[SI+p38e2],AX
p38e2  MOV W[SI+p38e2],AX

p38e6  ADD W[SI+p38e6],AX
p38e6  CMP W[SI+p38e6],032
p38e6  CMP W[SI+p38e6],0a
p38e6  DEC W[SI+p38e6]
p38e6  IDIV W[BX+p38e6]
p38e6  IDIV W[BX+p38e6]
p38e6  INC W[SI+p38e6]
p38e6  MOV AX,W[SI+p38e6]
p38e6  MOV BX,W[SI+p38e6]
p38e6  MOV BX,W[SI+p38e6]
p38e6  MOV W[SI+p38e6],0a
p38e6  MOV W[SI+p38e6],BX

p38ea  ADD W[SI+p38ea],5
p38ea  CMP BX,W[SI+p38ea]
p38ea  CMP BX,W[SI+p38ea]
p38ea  MOV W[SI+p38ea],AX
p38ea  MOV W[SI+p38ea],BX

p38ee  MOV AX,W[SI+p38ee]
p38ee  MOV W[SI+p38ee],9
p38ee  MOV W[SI+p38ee],AX

p38f2  CMP W[SI+p38f2],8
p38f2  INC W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV AX,W[SI+p38f2]
p38f2  MOV BX,W[SI+p38f2]
p38f2  MOV BX,W[SI+p38f2]
p38f2  MOV BX,W[SI+p38f2]
p38f2  MOV DX,W[SI+p38f2]
p38f2  MOV DX,W[SI+p38f2]
p38f2  MOV W[SI+p38f2],0
p38f2  MOV W[SI+p38f2],0

p38f6  CMP AX,W[p38f6]
p38f6  CMP AX,W[p38f6]
p38f6  CMP AX,W[p38f6]
p38f6  CMP AX,W[p38f6]
p38f6  CMP W[p38f6],2
p38f6  CMP W[p38f6],2
p38f6  MOV AX,W[p38f6]
p38f6  MOV W[p38f6],1
p38f6  MOV W[p38f6],1
p38f6  MOV W[p38f6],2

p38f8  MOV W[BX+p38f8],AX
p38f8  MOV W[SI+p38f8],0
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  MOV W[SI+p38f8],AX
p38f8  PUSH W[BX+p38f8]
p38f8  PUSH W[BX+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[DI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]
p38f8  PUSH W[SI+p38f8]

p39f8  DEC W[p39f8]
p39f8  MOV AX,W[BX+p39f8]
p39f8  MOV AX,W[SI+p39f8]
p39f8  MOV AX,W[SI+p39f8]
p39f8  MOV AX,W[SI+p39f8]
p39f8  MOV BX,W[SI+p39f8]
p39f8  MOV BX,W[SI+p39f8]
p39f8  MOV BX,W[SI+p39f8]
p39f8  MOV BX,W[SI+p39f8]
p39f8  MOV W[SI+p39f8],BX
p39f8  MOV W[SI+p39f8],BX
p39f8  PUSH W[SI+p39f8]
p39f8  PUSH W[p39f8]

p39fa  INC W[p39fa]
p39fa  PUSH W[p39fa]

p39fc  MOV AX,W[SI+p39fc]
p39fc  MOV AX,W[SI+p39fc]
p39fc  MOV AX,W[SI+p39fc]
p39fc  MOV AX,W[SI+p39fc]
p39fc  MOV AX,W[SI+p39fc]
p39fc  MOV CX,W[SI+p39fc]
p39fc  MOV CX,W[SI+p39fc]
p39fc  MOV CX,W[SI+p39fc]
p39fc  MOV W[SI+p39fc],AX
p39fc  MOV W[SI+p39fc],AX
p39fc  PUSH W[SI+p39fc]
p39fc  PUSH W[p39fc]

p39fe  PUSH W[p39fe]

p3a00  CMP W[SI+p3aoo],1
p3a00  CMP W[SI+p3aoo],1
p3a00  CMP W[SI+p3aoo],1
p3a00  MOV W[p3aoo],1

p3a02  MOV W[p3ao2],2

p3a04  CMP W[SI+p3ao4],7
p3a04  DEC W[SI+p3ao4]
p3a04  INC W[SI+p3ao4]
p3a04  MOV BX,W[SI+p3ao4]
p3a04  MOV W[SI+p3ao4],0
p3a04  MOV W[SI+p3ao4],7
p3a04  MOV W[p3ao4],2
p3a04  PUSH W[SI+p3ao4]
p3a04  PUSH W[SI+p3ao4]

p3a06  MOV W[p3ao6],6

p3a08  CMP W[SI+p3ao8],03a
p3a08  CMP W[SI+p3ao8],8
p3a08  INC W[SI+p3ao8]
p3a08  MOV W[SI+p3ao8],BX

p3a0c  MOV W[BX+p3aoc],AX
p3a0c  MOV W[BX+p3aoc],AX
p3a0c  PUSH W[BX+p3aoc]

p3a0e  MOV W[BX+p3aoe],AX
p3a0e  MOV W[BX+p3aoe],AX
p3a0e  PUSH W[DI+p3aoe]

p3a10  MOV W[BX+p3a1o],AX
p3a10  MOV W[BX+p3a1o],AX
p3a10  PUSH W[SI+p3a1o]

p3cdc  CMP W[BX+p3cdc],03c
p3cdc  INC W[BX+p3cdc]
p3cdc  INC W[SI+p3cdc]
p3cdc  MOV AX,W[SI+p3cdc]
p3cdc  MOV AX,W[SI+p3cdc]
p3cdc  MOV AX,W[SI+p3cdc]
p3cdc  MOV BX,W[SI+p3cdc]
p3cdc  MOV BX,W[SI+p3cdc]
p3cdc  MOV BX,W[SI+p3cdc]
p3cdc  MOV BX,W[SI+p3cdc]
p3cdc  MOV W[BX+p3cdc],0
p3cdc  MOV W[SI+p3cdc],BX

p3ce0  CMP AX,W[SI+p3ceo]
p3ce0  CMP W[BX+p3ceo],03c
p3ce0  INC W[BX+p3ceo]
p3ce0  MOV AX,W[SI+p3ceo]
p3ce0  MOV BX,W[SI+p3ceo]
p3ce0  MOV CX,W[SI+p3ceo]
p3ce0  MOV W[BX+p3ceo],0
p3ce0  MOV W[SI+p3ceo],BX

p3ce4  CMP W[SI+p3ce4],0
p3ce4  CMP W[SI+p3ce4],0
p3ce4  MOV W[SI+p3ce4],0
p3ce4  MOV W[SI+p3ce4],1
p3ce4  MOV W[SI+p3ce4],BX

p3ce8  CMP W[SI+p3ce8],0
p3ce8  MOV W[SI+p3ce8],1
p3ce8  MOV W[SI+p3ce8],AX

p3cec  CMP W[SI+p3cec],064
p3cec  INC W[SI+p3cec]
p3cec  MOV W[SI+p3cec],0
p3cec  MOV W[SI+p3cec],BX

p3cf0  DEC W[p3cfo]
p3cf0  DEC W[p3cfo]
p3cf0  DEC W[p3cfo]
p3cf0  INC W[p3cfo]
p3cf0  INC W[p3cfo]
p3cf0  INC W[p3cfo]
p3cf0  MOV BX,W[p3cfo]
p3cf0  MOV W[p3cfo],BX
p3cf0  MOV W[p3cfo],BX
p3cf0  MOV W[p3cfo],BX
p3cf0  MOV W[p3cfo],BX
p3cf0  PUSH W[p3cfo]
p3cf0  PUSH W[p3cfo]

p3cf2  DEC W[p3cf2]
p3cf2  DEC W[p3cf2]
p3cf2  DEC W[p3cf2]
p3cf2  INC W[p3cf2]
p3cf2  INC W[p3cf2]
p3cf2  INC W[p3cf2]
p3cf2  MOV AX,W[p3cf2]
p3cf2  MOV W[p3cf2],AX
p3cf2  MOV W[p3cf2],CX
p3cf2  MOV W[p3cf2],CX
p3cf2  MOV W[p3cf2],CX
p3cf2  PUSH W[p3cf2]
p3cf2  PUSH W[p3cf2]

p3cf4  MOV BX,W[p3cf4]
p3cf4  MOV W[p3cf4],AX
p3cf4  MOV W[p3cf4],BX
p3cf4  OR W[p3cf4],AX

p3cf6  CMP AX,W[p3cf6]
p3cf6  CMP AX,W[p3cf6]
p3cf6  CMP AX,W[p3cf6]
p3cf6  CMP AX,W[p3cf6]
p3cf6  CMP W[p3cf6],1
p3cf6  MOV W[p3cf6],1
p3cf6  MOV W[p3cf6],2

p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV AX,W[p3cf8]
p3cf8  MOV BX,W[p3cf8]
p3cf8  MOV BX,W[p3cf8]
p3cf8  MOV BX,W[p3cf8]
p3cf8  MOV BX,W[p3cf8]
p3cf8  MOV W[p3cf8],AX
p3cf8  MOV W[p3cf8],AX
p3cf8  MOV W[p3cf8],AX
p3cf8  MOV W[p3cf8],AX
p3cf8  MOV W[p3cf8],CX
p3cf8  PUSH W[p3cf8]
p3cf8  PUSH W[p3cf8]
p3cf8  PUSH W[p3cf8]
p3cf8  PUSH W[p3cf8]
p3cf8  PUSH W[p3cf8]
p3cf8  PUSH W[p3cf8]
p3cf8  SUB AX,W[p3cf8]
p3cf8  SUB AX,W[p3cf8]
p3cf8  SUB AX,W[p3cf8]

p3cfa  MOV AX,W[p3cfa]
p3cfa  MOV AX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV BX,W[p3cfa]
p3cfa  MOV CX,W[p3cfa]
p3cfa  MOV CX,W[p3cfa]
p3cfa  MOV CX,W[p3cfa]
p3cfa  MOV W[p3cfa],BX
p3cfa  MOV W[p3cfa],BX
p3cfa  MOV W[p3cfa],BX
p3cfa  MOV W[p3cfa],BX
p3cfa  MOV W[p3cfa],DX
p3cfa  PUSH W[p3cfa]
p3cfa  PUSH W[p3cfa]
p3cfa  PUSH W[p3cfa]
p3cfa  PUSH W[p3cfa]
p3cfa  PUSH W[p3cfa]
p3cfa  PUSH W[p3cfa]
p3cfa  SUB AX,W[p3cfa]
p3cfa  SUB AX,W[p3cfa]
p3cfa  SUB BX,W[p3cfa]

p3cfc  MOV AX,W[p3cfc]
p3cfc  MOV AX,W[p3cfc]
p3cfc  MOV AX,W[p3cfc]
p3cfc  MOV W[p3cfc],AX
p3cfc  MOV W[p3cfc],AX

p3cfe  MOV BX,W[p3cfe]
p3cfe  MOV BX,W[p3cfe]
p3cfe  MOV BX,W[p3cfe]
p3cfe  MOV W[p3cfe],BX
p3cfe  MOV W[p3cfe],BX

p3d00  MOV AX,W[p3doo]
p3d00  MOV AX,W[p3doo]
p3d00  MOV AX,W[p3doo]
p3d00  MOV AX,W[p3doo]
p3d00  MOV AX,W[p3doo]
p3d00  MOV AX,W[p3doo]
p3d00  MOV AX,W[p3doo]
p3d00  MOV CX,W[p3doo]
p3d00  MOV CX,W[p3doo]
p3d00  MOV CX,W[p3doo]
p3d00  MOV CX,W[p3doo]
p3d00  MOV CX,W[p3doo]
p3d00  MOV CX,W[p3doo]
p3d00  MOV W[p3doo],AX
p3d00  MOV W[p3doo],AX
p3d00  MOV W[p3doo],AX
p3d00  MOV W[p3doo],CX
p3d00  MOV W[p3doo],CX

p3d02  CMP W[p3do2],0
p3d02  CMP W[p3do2],0
p3d02  CMP W[p3do2],0
p3d02  CMP W[p3do2],0
p3d02  CMP W[p3do2],0
p3d02  MOV W[p3do2],0
p3d02  MOV W[p3do2],AX

p3d04  CMP W[p3do4],0
p3d04  CMP W[p3do4],1
p3d04  CMP W[p3do4],1
p3d04  MOV W[p3do4],1
p3d04  MOV W[p3do4],AX
p3d04  MOV W[p3do4],DX

p3d06  CMP W[p3do6],0
p3d06  CMP W[p3do6],0
p3d06  CMP W[p3do6],0
p3d06  MOV W[p3do6],0
p3d06  MOV W[p3do6],1
p3d06  MOV W[p3do6],1
p3d06  MOV W[p3do6],1
p3d06  MOV W[p3do6],1
p3d06  MOV W[p3do6],BX
p3d06  MOV W[p3do6],DX

p3d08  CMP AX,W[p3do8]
p3d08  CMP AX,W[p3do8]
p3d08  CMP AX,W[p3do8]
p3d08  MOV W[p3do8],AX
p3d08  MOV W[p3do8],AX

p3d0a  DEC W[p3doa]
p3d0a  DEC W[p3doa]
p3d0a  DEC W[p3doa]
p3d0a  INC W[p3doa]
p3d0a  INC W[p3doa]
p3d0a  INC W[p3doa]
p3d0a  MOV AX,W[p3doa]
p3d0a  MOV AX,W[p3doa]
p3d0a  MOV AX,W[p3doa]
p3d0a  MOV AX,W[p3doa]
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],AX
p3d0a  MOV W[p3doa],BX
p3d0a  MOV W[p3doa],BX
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]
p3d0a  PUSH W[p3doa]

p3d0c  DEC W[p3doc]
p3d0c  DEC W[p3doc]
p3d0c  DEC W[p3doc]
p3d0c  INC W[p3doc]
p3d0c  INC W[p3doc]
p3d0c  INC W[p3doc]
p3d0c  MOV BX,W[p3doc]
p3d0c  MOV BX,W[p3doc]
p3d0c  MOV BX,W[p3doc]
p3d0c  MOV BX,W[p3doc]
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],BX
p3d0c  MOV W[p3doc],CX
p3d0c  MOV W[p3doc],CX
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]
p3d0c  PUSH W[p3doc]

p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV AX,W[p3doe]
p3d0e  MOV CX,W[p3doe]
p3d0e  MOV CX,W[p3doe]
p3d0e  MOV W[p3doe],0
p3d0e  MOV W[p3doe],7
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],AX
p3d0e  MOV W[p3doe],CX
p3d0e  MOV W[p3doe],CX
p3d0e  MOV W[p3doe],CX
p3d0e  MOV W[p3doe],CX
p3d0e  MOV W[p3doe],CX
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]
p3d0e  PUSH W[p3doe]

p3d10  MOV CX,W[p3d1o]
p3d10  MOV W[p3d1o],050
p3d10  MOV W[p3d1o],AX
p3d10  MOV W[p3d1o],AX

p3d12  MOV DX,W[p3d12]
p3d12  MOV W[p3d12],061
p3d12  MOV W[p3d12],BX
p3d12  MOV W[p3d12],BX

p3d14  MOV AX,W[p3d14]
p3d14  MOV W[p3d14],AX
p3d14  MOV W[p3d14],CX
p3d14  MOV W[p3d14],CX

p3d16  CMP W[p3d16],2
p3d16  CMP W[p3d16],2
p3d16  CMP W[p3d16],2
p3d16  CMP W[p3d16],2
p3d16  CMP W[p3d16],2
p3d16  MOV W[p3d16],1
p3d16  MOV W[p3d16],2
p3d16  MOV W[p3d16],AX

p3d18  ADD W[p3d18],5
p3d18  CMP W[p3d18],064
p3d18  DEC W[p3d18]
p3d18  MOV AX,W[p3d18]
p3d18  MOV W[p3d18],0
p3d18  MOV W[p3d18],0
p3d18  MOV W[p3d18],BX
p3d18  PUSH W[p3d18]

p3d1a  ADD AX,W[p3d1a]
p3d1a  CMP AX,W[p3d1a]
p3d1a  CMP W[p3d1a],1
p3d1a  MOV AX,W[p3d1a]
p3d1a  MOV AX,W[p3d1a]
p3d1a  MOV AX,W[p3d1a]
p3d1a  MOV W[p3d1a],0
p3d1a  MOV W[p3d1a],AX
p3d1a  MOV W[p3d1a],DX

p3d1c  MOV W[p3d1c],AX
p3d1c  MOV W[p3d1c],AX
p3d1c  PUSH W[p3d1c]

p3d1e  MOV W[p3d1e],BX
p3d1e  MOV W[p3d1e],BX
p3d1e  PUSH W[p3d1e]

p3d20  MOV W[p3d2o],AX
p3d20  PUSH W[p3d2o]
p3d20  PUSH W[p3d2o]

p3d22  CMP W[p3d22],0
p3d22  MOV W[p3d22],0
p3d22  MOV W[p3d22],0
p3d22  MOV W[p3d22],1
p3d22  MOV W[p3d22],BX

p3d24  MOV W[SI+p3d24],BX
p3d24  PUSH W[BX+p3d24]
p3d24  PUSH W[SI+p3d24]
p3d24  PUSH W[SI+p3d24]

p4cc4  MOV W[SI+p4cc4],AX
p4cc4  PUSH W[BX+p4cc4]
p4cc4  PUSH W[SI+p4cc4]
p4cc4  PUSH W[SI+p4cc4]

p5c64  MOV AL,B[SI+p5c64]
p5c64  MOV BX,offset p5c64
p5c64  MOV CX,offset p5c64
p5c64  MOV CX,offset p5c64
p5c64  MOV CX,offset p5c64
p5c64  MOV CX,offset p5c64

p5c7f  MOV BX,offset p5c7f
p5c7f  MOV CX,offset p5c7f

p5c9a  MOV SI,offset p5c9a

p5ca2  MOV SI,offset p5ca2

p5caa  MOV SI,offset p5caa

p5cb2  DEC W[p5cb2]
p5cb2  MOV AX,W[p5cb2]
p5cb2  MOV AX,W[p5cb2]
p5cb2  MOV AX,W[p5cb2]
p5cb2  MOV AX,W[p5cb2]
p5cb2  MOV AX,W[p5cb2]
p5cb2  MOV BX,W[p5cb2]
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],AX
p5cb2  MOV W[p5cb2],BX
p5cb2  MOV W[p5cb2],BX
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]
p5cb2  PUSH W[p5cb2]

p5cb4  DEC W[p5cb4]
p5cb4  INC W[p5cb4]
p5cb4  INC W[p5cb4]
p5cb4  MOV AX,W[p5cb4]
p5cb4  MOV AX,W[p5cb4]
p5cb4  MOV AX,W[p5cb4]
p5cb4  MOV AX,W[p5cb4]
p5cb4  MOV AX,W[p5cb4]
p5cb4  MOV BX,W[p5cb4]
p5cb4  MOV BX,W[p5cb4]
p5cb4  MOV BX,W[p5cb4]
p5cb4  MOV W[p5cb4],AX
p5cb4  MOV W[p5cb4],BX
p5cb4  MOV W[p5cb4],CX
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  PUSH W[p5cb4]
p5cb4  SUB W[p5cb4],2

p5cb6  MOV AX,W[p5cb6]
p5cb6  MOV AX,W[p5cb6]
p5cb6  MOV AX,W[p5cb6]
p5cb6  MOV BX,W[p5cb6]
p5cb6  MOV BX,W[p5cb6]
p5cb6  MOV BX,W[p5cb6]
p5cb6  MOV W[p5cb6],AX

p5cb8  CMP AX,W[p5cb8]
p5cb8  CMP AX,W[p5cb8]
p5cb8  CMP AX,W[p5cb8]
p5cb8  CMP AX,W[p5cb8]
p5cb8  CMP AX,W[p5cb8]
p5cb8  CMP AX,W[p5cb8]
p5cb8  MOV BX,W[p5cb8]
p5cb8  MOV BX,W[p5cb8]
p5cb8  MOV CX,W[p5cb8]
p5cb8  MOV W[p5cb8],AX
p5cb8  PUSH W[p5cb8]
p5cb8  PUSH W[p5cb8]
p5cb8  PUSH W[p5cb8]
p5cb8  PUSH W[p5cb8]

p5cbc  MOV AX,W[p5cbc]
p5cbc  MOV AX,W[p5cbc]
p5cbc  MOV W[p5cbc],AX
p5cbc  MOV W[p5cbc],AX

p5cbe  MOV AX,W[p5cbe]
p5cbe  MOV AX,W[p5cbe]
p5cbe  MOV W[p5cbe],BX

p5cc0  MOV AX,W[p5cco]
p5cc0  MOV AX,W[p5cco]
p5cc0  MOV W[p5cco],CX

p5cc2  MOV W[p5cc2],BX
p5cc2  PUSH W[p5cc2]
p5cc2  PUSH W[p5cc2]

p5cc4  MOV W[p5cc4],AX
p5cc4  PUSH W[p5cc4]
p5cc4  PUSH W[p5cc4]
p5cc4  PUSH W[p5cc4]
p5cc4  PUSH W[p5cc4]

p5cc6  CMP AX,W[p5cc6]
p5cc6  CMP BX,W[p5cc6]
p5cc6  MOV W[p5cc6],AX

p5cc8  CMP AX,W[p5cc8]
p5cc8  CMP AX,W[p5cc8]
p5cc8  MOV BX,W[p5cc8]
p5cc8  MOV W[p5cc8],AX

p5cca  MOV W[p5cca],AX

p5ccc  MOV AX,W[p5ccc]
p5ccc  MOV W[p5ccc],0

p5cce  MOV AX,W[p5cce]
p5cce  MOV W[p5cce],AX

p5cd0  MOV AX,W[p5cdo]
p5cd0  MOV W[p5cdo],AX

p5cd2  MOV BX,W[p5cd2]
p5cd2  MOV W[p5cd2],BX

p5cd4  CMP W[p5cd4],0
p5cd4  DEC W[p5cd4]
p5cd4  MOV AX,W[p5cd4]
p5cd4  MOV AX,W[p5cd4]
p5cd4  MOV AX,W[p5cd4]
p5cd4  MOV AX,W[p5cd4]
p5cd4  MOV AX,W[p5cd4]
p5cd4  MOV W[p5cd4],0
p5cd4  MOV W[p5cd4],AX
p5cd4  MOV W[p5cd4],AX
p5cd4  MOV W[p5cd4],AX

p5cd6  CMP AX,W[p5cd6]
p5cd6  MOV W[p5cd6],AX
p5cd6  MOV W[p5cd6],AX

p5cd8  MOV BX,W[SI+p5cd8]
p5cd8  MOV W[SI+p5cd8],BX

p64a8  MOV AX,W[SI+p64a8]
p64a8  MOV W[SI+p64a8],AX

p6c78  MOV AX,W[p6c78]
p6c78  MOV W[p6c78],AX
p6c78  MOV W[p6c78],BX

p6c7a  ADD W[p6c7a],5
p6c7a  CMP AX,W[p6c7a]
p6c7a  CMP AX,W[p6c7a]
p6c7a  MOV W[p6c7a],0
p6c7a  MOV W[p6c7a],AX

p6c7c  ADD W[p6c7c],5
p6c7c  CMP AX,W[p6c7c]
p6c7c  CMP AX,W[p6c7c]
p6c7c  CMP AX,W[p6c7c]
p6c7c  MOV W[p6c7c],0
p6c7c  MOV W[p6c7c],AX

p6c7e  CMP AX,W[p6c7e]
p6c7e  CMP AX,W[p6c7e]
p6c7e  MOV W[p6c7e],0ff
p6c7e  MOV W[p6c7e],AX
p6c7e  SUB W[p6c7e],5

p6c80  CMP AX,W[p6c8o]
p6c80  CMP AX,W[p6c8o]
p6c80  CMP AX,W[p6c8o]
p6c80  MOV W[p6c8o],0ff
p6c80  MOV W[p6c8o],AX
p6c80  SUB W[p6c8o],5

p6c82  CMP W[p6c82],0
p6c82  CMP W[p6c82],0
p6c82  CMP W[p6c82],0
p6c82  CMP W[p6c82],0
p6c82  MOV W[p6c82],0
p6c82  MOV W[p6c82],0
p6c82  MOV W[p6c82],1
p6c82  MOV W[p6c82],AX

p6c84  MOV AX,W[p6c84]
p6c84  MOV W[p6c84],0
p6c84  MOV W[p6c84],0
p6c84  MOV W[p6c84],1
p6c84  MOV W[p6c84],1
p6c84  MOV W[p6c84],BX

p6c86  ADD W[p6c86],AX
p6c86  ADD W[p6c86],AX
p6c86  ADD W[p6c86],AX
p6c86  ADD W[p6c86],AX
p6c86  MOV BX,W[p6c86]
p6c86  MOV BX,W[p6c86]
p6c86  MOV BX,W[p6c86]
p6c86  MOV CX,W[p6c86]
p6c86  MOV W[p6c86],0
p6c86  MOV W[p6c86],BX
p6c86  PUSH W[p6c86]

p6c88  ADC W[p6c88],BX
p6c88  ADC W[p6c88],BX
p6c88  ADC W[p6c88],BX
p6c88  ADC W[p6c88],BX
p6c88  MOV AX,W[p6c88]
p6c88  MOV AX,W[p6c88]
p6c88  MOV AX,W[p6c88]
p6c88  MOV BX,W[p6c88]
p6c88  MOV W[p6c88],0
p6c88  MOV W[p6c88],AX
p6c88  PUSH W[p6c88]

p6c8a  MOV W[p6c8a],BX

p6c8c  MOV W[p6c8c],AX

p6c8e  MOV W[p6c8e],0

p6c90  MOV W[p6c9o],0

p6c92  MOV W[p6c92],AX
p6c92  MOV W[p6c92],AX
p6c92  SUB AX,W[p6c92]
p6c92  SUB AX,W[p6c92]
p6c92  SUB AX,W[p6c92]

p6c94  MOV AX,W[p6c94]
p6c94  MOV AX,W[p6c94]
p6c94  MOV AX,W[p6c94]
p6c94  MOV AX,W[p6c94]
p6c94  MOV AX,W[p6c94]
p6c94  MOV AX,W[p6c94]
p6c94  MOV W[p6c94],AX
p6c94  MOV W[p6c94],AX

p6c96  MOV AX,W[p6c96]
p6c96  MOV AX,W[p6c96]
p6c96  MOV AX,W[p6c96]
p6c96  MOV AX,W[p6c96]
p6c96  MOV W[p6c96],2
p6c96  MOV W[p6c96],2
p6c96  MOV W[p6c96],3
p6c96  MOV W[p6c96],5

p6c98  MOV AX,W[p6c98]
p6c98  MOV W[p6c98],012
p6c98  MOV W[p6c98],0c
p6c98  MOV W[p6c98],0f
p6c98  MOV W[p6c98],8
p6c98  MOV W[p6c98],AX

p6c9a  CMP W[p6c9a],0
p6c9a  MOV W[p6c9a],1
p6c9a  MOV W[p6c9a],AX

p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV AX,offset p6c9c
p6c9c  MOV CX,offset p6c9c
p6c9c  MOV B[DI+p6c9c],AL

p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6
p6ca6  MOV AX,offset p6ca6

p6cca  MOV CX,W[SI+p6cca]
p6cca  MOV DX,W[SI+p6cca]

p6ccc  MOV BX,W[SI+p6ccc]
p6ccc  MOV CX,W[SI+p6ccc]

p6cce  ADD AX,offset p6cce
p6cce  MOV W[SI+p6cce],0
p6cce  MOV W[SI+p6cce],CX
p6cce  MOV W[SI+p6cce],CX
p6cce  PUSH W[SI+p6cce]
p6cce  PUSH W[SI+p6cce]

p6cd0  MOV W[SI+p6cdo],0
p6cd0  MOV W[SI+p6cdo],BX
p6cd0  MOV W[SI+p6cdo],BX
p6cd0  PUSH W[SI+p6cdo]
p6cd0  PUSH W[SI+p6cdo]

p6cf6  ADD BX,offset p6cf6
p6cf6  MOV DX,W[p6cf6]

p6cf8  MOV CX,W[p6cf8]

p6cfa  ADD AX,offset p6cfa
p6cfa  ADD AX,offset p6cfa
p6cfa  ADD AX,offset p6cfa
p6cfa  ADD AX,offset p6cfa
p6cfa  ADD AX,offset p6cfa
p6cfa  MOV AX,offset p6cfa
p6cfa  MOV BX,offset p6cfa
p6cfa  MOV B[BX+p6cfa],AL
p6cfa  MOV B[SI+p6cfa],AL

p6d26  MOV AX,offset p6d26
p6d67  MOV AX,offset p6d67
p6da8  MOV AX,offset p6da8
p6de9  MOV AX,offset p6de9
p6dfa  MOV AX,offset p6dfa
p6dfa  MOV BX,offset p6dfa
p6dfe  MOV AX,offset p6dfe
p6dfe  MOV AX,offset p6dfe
p6e0d  MOV AX,offset p6eod
p6e0d  MOV AX,offset p6eod
p6e17  MOV AX,offset p6e17
p6e17  MOV AX,offset p6e17
p6e17  MOV BX,offset p6e17
p6e17  MOV CX,offset p6e17
p6e18  MOV AX,offset p6e18
p6e18  MOV AX,offset p6e18
p6e18  MOV AX,offset p6e18
p6e18  MOV AX,offset p6e18
p6e20  MOV AX,offset p6e2o
p6e28  MOV AX,offset p6e28
p6e34  MOV AX,offset p6e34
p6e34  MOV AX,offset p6e34
p6e37  MOV AX,offset p6e37
p6e39  MOV AX,offset p6e39
p6e44  MOV AX,offset p6e44
p6e4d  MOV AX,offset p6e4d
p6e53  MOV AX,offset p6e53

p6e56  CMP AX,W[p6e56]
p6e56  MOV W[p6e56],AX
p6e56  MOV W[p6e56],AX

p6e5a  CMP W[p6e5a],0
p6e5a  CMP W[p6e5a],0
p6e5a  CMP W[p6e5a],0
p6e5a  CMP W[p6e5a],0
p6e5a  CMP W[p6e5a],0
p6e5a  CMP W[p6e5a],0
p6e5a  MOV W[p6e5a],0
p6e5a  MOV W[p6e5a],1
p6e5a  MOV W[p6e5a],AX

p6e5c  CMP W[p6e5c],0
p6e5c  MOV W[p6e5c],1
p6e5c  MOV W[p6e5c],BX

p6e5e  CMP W[p6e5e],0
p6e5e  CMP W[p6e5e],1
p6e5e  MOV W[p6e5e],1
p6e5e  MOV W[p6e5e],AX
p6e5e  MOV W[p6e5e],AX

p6e60  CMP W[p6e6o],1
p6e60  CMP W[p6e6o],2
p6e60  MOV AX,W[p6e6o]
p6e60  MOV W[p6e6o],1
p6e60  MOV W[p6e6o],1
p6e60  MOV W[p6e6o],2
p6e60  MOV W[p6e6o],2
p6e60  MOV W[p6e6o],2
p6e60  MOV W[p6e6o],AX

p6e62  ADD W[p6e62],5
p6e62  MOV AX,W[p6e62]
p6e62  MOV AX,W[p6e62]
p6e62  MOV AX,W[p6e62]
p6e62  MOV W[p6e62],AX
p6e62  SUB W[p6e62],5

p6e64  MOV BX,W[p6e64]
p6e64  MOV BX,W[p6e64]
p6e64  MOV W[p6e64],AX
p6e64  MOV W[p6e64],AX

p6e66  ADD AX,W[p6e66]
p6e66  MOV W[p6e66],-1
p6e66  MOV W[p6e66],1
p6e66  MOV W[p6e66],1
p6e66  MOV W[p6e66],AX

p6e68  MOV AX,W[p6e68]
p6e68  MOV W[p6e68],5
p6e68  MOV W[p6e68],AX
p6e68  MOV W[p6e68],AX
p6e68  NEG W[p6e68]

p6e6a  CMP W[p6e6a],0
p6e6a  MOV W[p6e6a],0
p6e6a  MOV W[p6e6a],0
p6e6a  MOV W[p6e6a],0
p6e6a  MOV W[p6e6a],1
p6e6a  MOV W[p6e6a],AX
p6e6a  MOV W[p6e6a],AX

p6e6c  IMUL W[p6e6c]
p6e6c  IMUL W[p6e6c]
p6e6c  MOV AX,W[p6e6c]
p6e6c  MOV W[p6e6c],AX

p6e6e  CMP W[p6e6e],0
p6e6e  MOV W[p6e6e],0
p6e6e  MOV W[p6e6e],0
p6e6e  MOV W[p6e6e],0
p6e6e  MOV W[p6e6e],1
p6e6e  MOV W[p6e6e],AX
p6e6e  MOV W[p6e6e],AX

p6e70  ADD W[p6e7o],AX
p6e70  MOV AX,W[p6e7o]
p6e70  MOV W[p6e7o],012c
p6e70  PUSH W[p6e7o]

p6e72  MOV AX,W[p6e72]
p6e72  MOV W[p6e72],2000
p6e72  SUB W[p6e72],AX

p6e74  ADD W[p6e74],AX
p6e74  MOV AX,W[p6e74]
p6e74  MOV W[p6e74],1000

p6e80  INC W[p6e8o]
p6e80  MOV AX,W[p6e8o]
p6e80  MOV W[p6e8o],0

p6e82  ADD W[p6e82],AX
p6e82  MOV AX,W[p6e82]
p6e82  MOV AX,W[p6e82]
p6e82  MOV AX,W[p6e82]
p6e82  MOV W[p6e82],028
p6e82  MOV W[p6e82],0a
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],AX
p6e82  MOV W[p6e82],CX
p6e82  PUSH W[p6e82]

p6e84  CMP W[p6e84],1000
p6e84  CMP W[p6e84],500
p6e84  MOV AX,W[p6e84]
p6e84  MOV AX,W[p6e84]
p6e84  MOV AX,W[p6e84]
p6e84  MOV W[p6e84],1000
p6e84  MOV W[p6e84],12000
p6e84  MOV W[p6e84],500
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],AX
p6e84  MOV W[p6e84],BX
p6e84  MOV W[p6e84],BX

p6e86  ADD W[p6e86],AX
p6e86  CMP W[p6e86],032
p6e86  CMP W[p6e86],1
p6e86  MOV AX,W[p6e86]
p6e86  MOV AX,W[p6e86]
p6e86  MOV W[p6e86],0
p6e86  MOV W[p6e86],032
p6e86  MOV W[p6e86],0f
p6e86  MOV W[p6e86],AX
p6e86  MOV W[p6e86],AX
p6e86  MOV W[p6e86],AX

p6e88  MOV SI,offset p6e88
p6e88  MOV SI,offset p6e88
p6e90  MOV SI,offset p6e9o
p6e90  MOV SI,offset p6e9o
p6e98  MOV SI,offset p6e98
p6e98  MOV SI,offset p6e98
p6ea0  MOV SI,offset p6eao
p6ea0  MOV SI,offset p6eao
p6eb4  DW offset p6eb4
p6ec0  DW offset p6eco
p6ecc  DW offset p6ecc
p6ed8  DW offset p6ed8
p6ee4  DW offset p6ee4
p6ef0  DW offset p6efo
p6efc  DW offset p6efc
p6f08  DW offset p6fo8
p6f14  DW offset p6f14
p6f20  DW offset p6f2o
p6f2c  DW offset p6f2c
p6f2c  MOV AX,offset p6f2c
p6f2c  MOV BX,offset p6f2c
p6f51  DW offset p6f51
p6f51  MOV AX,offset p6f51
p6f76  DW offset p6f76
p6f76  MOV AX,offset p6f76
p6f9b  DW offset p6f9b
p6f9b  MOV AX,offset p6f9b
p6fc0  DW offset p6fco
p6fc0  MOV AX,offset p6fco
p6fc0  MOV BX,offset p6fco
p6fe5  DW offset p6fe5
p6fe5  MOV AX,offset p6fe5
p700a  DW offset p7ooa
p700a  MOV AX,offset p7ooa
p700a  MOV BX,offset p7ooa
p702f  DW offset p7o2f
p702f  MOV AX,offset p7o2f
p7054  DW offset p7o54
p7054  MOV AX,offset p7o54
p7079  DW offset p7o79
p7079  MOV AX,offset p7o79
p709e  DW offset p7o9e
p709e  MOV AX,offset p7o9e
p70c3  DW offset p7oc3
p70c3  MOV AX,offset p7oc3
p70e8  DW offset p7oe8
p70e8  MOV AX,offset p7oe8
p70e8  MOV BX,offset p7oe8
p710d  DW offset p71od
p710d  MOV AX,offset p71od
p7132  DW offset p7132
p7132  MOV AX,offset p7132
p7132  MOV BX,offset p7132
p7157  DW offset p7157
p7157  MOV AX,offset p7157
p717c  DW offset p717c
p717c  MOV AX,offset p717c
p71a1  DW offset p71a1
p71a1  MOV AX,offset p71a1
p71a1  MOV BX,offset p71a1
p71c6  DW offset p71c6
p71c6  MOV AX,offset p71c6
p71eb  DW offset p71eb
p71eb  MOV AX,offset p71eb
p7210  DW offset p721o
p7210  MOV AX,offset p721o
p7235  DW offset p7235
p7235  MOV AX,offset p7235
p7235  MOV BX,offset p7235
p725a  DW offset p725a
p725a  MOV AX,offset p725a
p727f  DW offset p727f
p727f  MOV AX,offset p727f
p72a4  DW offset p72a4
p72a4  MOV AX,offset p72a4
p72c9  DW offset p72c9
p72c9  MOV AX,offset p72c9
p72ee  DW offset p72ee
p7313  DW offset p7313
p7338  DW offset p7338
p735d  DW offset p735d
p7382  DW offset p7382
p73a7  DW offset p73a7
p73cc  DW offset p73cc
p73f1  DW offset p73f1
p7416  DW offset p7416
p7416  DW offset p7416
p743b  DW offset p743b
p7460  DW offset p746o
p7485  DW offset p7485
p74aa  DW offset p74aa

p74d0  CMP W[p74do],0
p74d0  CMP W[p74do],0
p74d0  CMP W[p74do],0
p74d0  MOV W[p74do],0
p74d0  MOV W[p74do],AX

p74d2  CMP W[p74d2],0
p74d2  DEC W[p74d2]
p74d2  MOV AX,W[p74d2]
p74d2  MOV W[p74d2],3

p74d4  MOV AX,W[p74d4]
p74d4  MOV AX,W[p74d4]
p74d4  MOV W[p74d4],1
p74d4  MOV W[p74d4],9
p74d4  MOV W[p74d4],AX

p74d6  CMP W[p74d6],0
p74d6  CMP W[p74d6],0
p74d6  CMP W[p74d6],0
p74d6  MOV W[p74d6],0
p74d6  MOV W[p74d6],AX

p74d8  MOV W[p74d8],0af

p74da  MOV AX,offset p74da
p74eb  MOV AX,offset p74eb
p751c  MOV AL,B[DI+p751c]
p751c  MOV AL,B[DI+p751c]
p751c  MOV AL,B[DI+p751c]
p751c  MOV AL,B[DI+p751c]
p751c  MOV AL,B[DI+p751c]
p751c  MOV AL,B[SI+p751c]
p761e  MOV CL,B[BX+p761e]
p7630  MOV AX,offset p763o

