#!/usr/bin/env python3
"""Create an MZ EXE from a raw binary (code+data) produced by NASM.

Usage: python make_exe.py styx.bin styx.exe
"""

import struct
import sys
import os

def make_exe(bin_path, exe_path):
    with open(bin_path, 'rb') as f:
        load_image = f.read()
    
    # MZ header is 28 bytes, padded to 32 bytes (2 paragraphs)
    header_size = 32  # 2 paragraphs
    
    total_size = header_size + len(load_image)
    
    # MZ header fields
    e_magic = 0x5A4D       # 'MZ'
    e_cblp = total_size % 512  # bytes on last page (0 means full page)
    e_cp = (total_size + 511) // 512  # total 512-byte pages
    e_crlc = 0             # no relocations
    e_cparhdr = header_size // 16  # header size in paragraphs
    e_minalloc = 0x1000    # min extra paragraphs (64KB for stack)
    e_maxalloc = 0xFFFF    # max extra paragraphs
    e_ss = 0               # initial SS (will be overridden by code)
    e_sp = 0xFFF0          # initial SP (will be overridden by code)
    e_csum = 0             # checksum (not checked by DOS)
    e_ip = 0               # initial IP (MAIN at start of code)
    e_cs = 0               # initial CS (code is first segment)
    e_lfarlc = 0x1C        # relocation table offset
    e_ovno = 0             # overlay number
    
    header = struct.pack('<14H',
        e_magic, e_cblp, e_cp, e_crlc, e_cparhdr,
        e_minalloc, e_maxalloc, e_ss, e_sp, e_csum,
        e_ip, e_cs, e_lfarlc, e_ovno
    )
    
    # Pad header to 32 bytes
    header += b'\x00' * (header_size - len(header))
    
    with open(exe_path, 'wb') as f:
        f.write(header)
        f.write(load_image)
    
    print(f'Created {exe_path}: {total_size} bytes')
    print(f'  Load image: {len(load_image)} bytes')
    print(f'  Header: {header_size} bytes ({e_cparhdr} paragraphs)')
    print(f'  Pages: {e_cp} ({e_cp * 512} bytes, last page: {e_cblp} bytes)')

if __name__ == '__main__':
    base_dir = os.path.dirname(os.path.abspath(__file__))
    bin_path = os.path.join(base_dir, 'STYX.BIN')
    exe_path = os.path.join(base_dir, 'STYX.EXE')
    
    if len(sys.argv) >= 3:
        bin_path = sys.argv[1]
        exe_path = sys.argv[2]
    elif len(sys.argv) == 2:
        bin_path = sys.argv[1]
    
    make_exe(bin_path, exe_path)
