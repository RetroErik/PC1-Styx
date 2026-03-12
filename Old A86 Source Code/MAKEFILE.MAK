styx.exe: styx1.obj parse.obj styx2.obj styx3.obj data.obj response.rsp
  tlink @response.rsp

.asm.obj:
  a86 +o $<

.c.obj:
  tcc -c -f- -Z $<

styx1.obj: styx1.asm

styx2.obj: styx2.asm

styx3.obj: styx3.asm

data.obj: data.asm

parse.obj: parse.asm

parsecmd.obj: parsecmd.c
