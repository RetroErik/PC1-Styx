#!/usr/bin/env python3
"""Convert A86 assembler syntax to NASM syntax for the Styx game.

Handles:
- PUBLIC -> global (stripped since we merge into one file)
- SEGMENT directives -> NASM segment directives
- W[x] -> word [x], B[x] -> byte [x], D[x] -> dword [x]
- A86 hex numbers (leading 0 with >1 digit, or containing A-F) -> 0x prefix
- offset label -> label
- n DUP (v) -> times n db/dw v
- CS:/ES:/DS: segment override prefixes -> [seg:addr] syntax
- LES reg,W[x] -> les reg,[x]
- JMP/CALL D[x] -> jmp/call far [x]
"""

import re
import sys
import os

def is_a86_hex(num_str):
    """Check if a number string is hex in A86 convention.
    
    A86 rule: hex if starts with 0 and has >1 digit, or contains A-F.
    """
    if not num_str:
        return False
    # Contains hex letters -> always hex
    if re.search(r'[a-fA-F]', num_str):
        return True
    # Starts with 0 and has more than 1 digit -> hex
    if num_str[0] == '0' and len(num_str) > 1:
        return True
    return False

def convert_number(num_str):
    """Convert an A86 number to NASM format."""
    if not num_str:
        return num_str
    
    # If it's pure decimal (no hex letters, doesn't start with 0, or is just "0")
    if not is_a86_hex(num_str):
        return num_str
    
    # It's hex - convert to 0x format
    # Remove leading zeros but keep at least one digit
    hex_val = num_str.lstrip('0') or '0'
    return '0x' + hex_val

def convert_numbers_in_text(text):
    """Convert all A86-style numbers in a line of assembly to NASM format.
    
    Carefully avoids converting labels and strings.
    """
    # Don't touch comment-only lines or empty lines
    stripped = text.strip()
    if not stripped or stripped.startswith(';'):
        return text
    
    # Split line into code and comment parts
    # Be careful with semicolons inside strings
    in_string = False
    string_char = None
    comment_pos = -1
    for i, ch in enumerate(text):
        if in_string:
            if ch == string_char:
                in_string = False
        else:
            if ch in ('"', "'"):
                in_string = True
                string_char = ch
            elif ch == ';':
                comment_pos = i
                break
    
    if comment_pos >= 0:
        code_part = text[:comment_pos]
        comment_part = text[comment_pos:]
    else:
        code_part = text
        comment_part = ''
    
    # Convert numbers in the code part
    # A number is a sequence of hex digits (0-9, a-f, A-F) that starts with a digit
    # and is not part of a label (labels contain letters beyond hex range, or start with letter)
    # We need to be careful to not modify label references
    
    # Pattern: match standalone numbers (preceded by non-alphanumeric, followed by non-alphanumeric)
    # But NOT hex digits that are part of a label name
    def replace_num(m):
        num = m.group(0)
        return convert_number(num)
    
    # Match numbers: start with digit, contain only hex digits (0-9, a-f, A-F)
    # Must be at word boundary (not preceded/followed by alphanumeric or underscore)
    # BUT labels in this code can start with 'o' or 'p' followed by digits+hex
    # So we need context: numbers appear after operators/punctuation, not after label-start chars
    
    # Strategy: process token by token
    result = []
    i = 0
    while i < len(code_part):
        ch = code_part[i]
        
        # Skip strings
        if ch in ('"', "'"):
            end = code_part.find(ch, i + 1)
            if end == -1:
                result.append(code_part[i:])
                i = len(code_part)
            else:
                result.append(code_part[i:end+1])
                i = end + 1
            continue
        
        # Check for a number token (starts with digit 0-9)
        if ch.isdigit():
            # Collect the full token
            j = i
            while j < len(code_part) and (code_part[j].isalnum() or code_part[j] == '_'):
                j += 1
            token = code_part[i:j]
            
            # Check if preceded by an alphanumeric or underscore (part of a label)
            if i > 0 and (code_part[i-1].isalnum() or code_part[i-1] == '_'):
                # This is part of a larger identifier/label, don't convert
                result.append(token)
            else:
                # Check if token is purely hex digits (a valid number)
                if re.match(r'^[0-9a-fA-F]+$', token):
                    result.append(convert_number(token))
                else:
                    # Contains non-hex chars (like 'g'-'z'), it's a label
                    result.append(token)
            i = j
            continue
        
        result.append(ch)
        i += 1
    
    return ''.join(result) + comment_part

def convert_seg_override(line):
    """Convert A86 segment override prefix syntax to NASM inline syntax.
    
    A86: CS: MOV W[addr],AX  ->  NASM: MOV word [cs:addr],AX
    A86: ES: CMP B[BX],0     ->  NASM: CMP byte [es:BX],0
    """
    # Match segment override prefix at start of instruction
    # Pattern: optional whitespace, segment register colon, space, then instruction
    m = re.match(r'^(\s*)(CS|ES|DS|SS):\s+(.+)$', line, re.IGNORECASE)
    if not m:
        return line
    
    indent = m.group(1)
    seg = m.group(2).lower()
    rest = m.group(3)
    
    # Find memory reference in the instruction and add segment override inside brackets
    # Memory references look like: word [addr], byte [addr], [addr], dword [addr]
    # Or in A86 style: W[addr], B[addr], D[addr]
    # After other conversions, they should be: word [addr], byte [addr], etc.
    
    # Insert segment override inside the first [...] found
    def add_seg_to_brackets(text, seg):
        # Find first '[' that's not inside a string
        bracket_pos = text.find('[')
        if bracket_pos >= 0:
            return text[:bracket_pos+1] + seg + ':' + text[bracket_pos+1:]
        return text
    
    new_rest = add_seg_to_brackets(rest, seg)
    return indent + new_rest

def convert_memory_refs(line):
    """Convert A86 memory reference syntax to NASM.
    
    W[x] -> word [x]
    B[x] -> byte [x]  
    D[x] -> dword [x]
    """
    # Handle W[, B[, D[ but NOT when preceded by alphanumeric (part of label)
    # Must handle nested cases like MOV W[BP+4],AX
    
    def replace_size_prefix(m):
        prefix_char = m.group(1)
        before = m.group(0)[0] if m.start() > 0 else ''
        
        size_map = {'W': 'word ', 'w': 'word ', 'B': 'byte ', 'b': 'byte ', 
                     'D': 'dword ', 'd': 'dword '}
        return size_map.get(prefix_char, prefix_char) + '['
    
    # Replace W[, B[, D[ when not preceded by alphanumeric/underscore
    # Use lookbehind to ensure it's not part of a label
    result = re.sub(r'(?<![a-zA-Z0-9_])([WBDwbd])\[', replace_size_prefix, line)
    
    return result

def convert_dup(line):
    """Convert A86 DUP syntax to NASM times syntax.
    
    DB n DUP (v) -> times n db v
    DW n DUP (v) -> times n dw v
    """
    # Match: (optional label:) (whitespace) DB/DW n DUP (v)
    m = re.match(r'^(\s*(?:\w+:\s*)?)(DB|DW|DD)\s+(.+?)\s+DUP\s*\((.+?)\)\s*(;.*)?$', line, re.IGNORECASE)
    if m:
        prefix = m.group(1)
        directive = m.group(2)
        count = m.group(3)
        value = m.group(4)
        comment = m.group(5) or ''
        return f'{prefix}times {count} {directive} {value} {comment}'.rstrip()
    return line

def convert_offset(line):
    """Convert A86 'offset label' to just 'label' for NASM."""
    # Replace 'offset label' with just 'label'
    # Be careful not to match inside strings or comments
    
    # Split into code and comment
    in_string = False
    string_char = None
    comment_pos = -1
    for i, ch in enumerate(line):
        if in_string:
            if ch == string_char:
                in_string = False
        else:
            if ch in ('"', "'"):
                in_string = True
                string_char = ch
            elif ch == ';':
                comment_pos = i
                break
    
    if comment_pos >= 0:
        code_part = line[:comment_pos]
        comment_part = line[comment_pos:]
    else:
        code_part = line
        comment_part = ''
    
    # Replace 'offset' keyword (case insensitive)
    code_part = re.sub(r'\boffset\s+', '', code_part, flags=re.IGNORECASE)
    
    return code_part + comment_part

def convert_les_lds(line):
    """Convert LES/LDS with W[] to just [] (LES/LDS inherently load dword)."""
    # LES BX,W[BP+4] -> LES BX,[BP+4]
    # After memory ref conversion, this would be LES BX,word [BP+4]
    # We need to remove the 'word' for LES/LDS since they load a dword
    line = re.sub(r'(LES|LDS)\s+(\w+)\s*,\s*word\s+\[', r'\1 \2,[', line, flags=re.IGNORECASE)
    return line

def convert_jmp_call_far(line):
    """Convert JMP/CALL D[x] (far indirect) to NASM syntax.
    
    After conversion, D[x] becomes dword [x].
    JMP dword [x] -> jmp far [x]
    """
    # Match JMP/CALL with dword memory operand (far indirect)
    line = re.sub(r'(JMP|CALL)\s+dword\s+\[', r'\1 far [', line, flags=re.IGNORECASE)
    return line

def convert_seg_to_seg_mov(line):
    """Convert MOV segreg,segreg which A86 accepts but isn't valid x86.
    
    MOV DS,CS -> push cs / pop ds
    MOV ES,CS -> push cs / pop es
    etc.
    """
    seg_regs = {'CS', 'DS', 'ES', 'SS', 'cs', 'ds', 'es', 'ss'}
    m = re.match(r'^(\s*)MOV\s+(CS|DS|ES|SS)\s*,\s*(CS|DS|ES|SS)\s*(;.*)?$', line, re.IGNORECASE)
    if m:
        indent = m.group(1)
        dest = m.group(2).upper()
        src = m.group(3).upper()
        comment = m.group(4) or ''
        return f'{indent}PUSH {src}\n{indent}POP {dest} {comment}'.rstrip()
    return line

def convert_line(line):
    """Apply all A86-to-NASM conversions to a single line."""
    
    # Skip empty lines
    if not line.strip():
        return line
    
    # Skip pure comment lines  
    if line.strip().startswith(';'):
        # Still convert numbers in comments? No, leave comments alone
        return line
    
    # Check for PUBLIC directive - remove it (we merge into one file)
    if re.match(r'^\s*PUBLIC\s+', line, re.IGNORECASE):
        return '; ' + line  # Comment it out
    
    # Check for SEGMENT directive
    if re.match(r'^\s*_TEXT\s+SEGMENT\s+', line, re.IGNORECASE):
        return None  # Will be handled at file level
    if re.match(r'^\s*_DATA\s+SEGMENT\s+', line, re.IGNORECASE):
        return None  # Will be handled at file level
    
    # Convert MOV segreg,segreg (must be before other conversions)
    line = convert_seg_to_seg_mov(line)
    
    # Convert DUP syntax (before number conversion)
    line = convert_dup(line)
    
    # Convert memory references: W[ -> word [, B[ -> byte [, D[ -> dword [
    line = convert_memory_refs(line)
    
    # Convert offset keyword
    line = convert_offset(line)
    
    # Convert LES/LDS (must be after memory ref conversion)
    line = convert_les_lds(line)
    
    # Convert JMP/CALL far (must be after memory ref conversion)
    line = convert_jmp_call_far(line)
    
    # Convert segment override prefixes
    line = convert_seg_override(line)
    
    # Convert A86 hex numbers to NASM 0x format
    line = convert_numbers_in_text(line)
    
    return line

def process_file(filepath):
    """Process a single A86 assembly file and return converted lines."""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    
    result = []
    for line in lines:
        line = line.rstrip('\n').rstrip('\r')
        converted = convert_line(line)
        if converted is not None:
            result.append(converted)
    
    return result

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Output file
    output_file = os.path.join(base_dir, 'STYX.ASM')
    
    # Files to process in order (code segment files first, then data)
    code_files = ['STYX1.ASM', 'PARSE.ASM', 'STYX2.ASM', 'STYX3.ASM']
    data_files = ['DATA.ASM']
    
    output_lines = []
    
    # NASM header for flat binary output
    output_lines.append('; Styx Remastered - NASM conversion')
    output_lines.append('; Copyright (c) Andrew Jenner 1998-2004')
    output_lines.append('; Converted from A86 to NASM syntax')
    output_lines.append('')
    output_lines.append('bits 16')
    output_lines.append('cpu 8086')
    output_lines.append('')
    
    # Code segment - vstart=0 so CS-relative addresses work
    output_lines.append('section .text start=0 vstart=0')
    output_lines.append('')
    
    # Add ..start label before MAIN for NASM OBJ entry point
    for code_file in code_files:
        filepath = os.path.join(base_dir, code_file)
        output_lines.append(f'; === {code_file} ===')
        output_lines.append('')
        
        lines = process_file(filepath)
        
        for line in lines:
            output_lines.append(line)
        
        output_lines.append('')
    
    # Data segment - vstart=0 so DS-relative addresses work
    # align=16 for paragraph alignment (matches A86 PARA attribute)
    output_lines.append('section .data vstart=0 align=16 follows=.text')
    output_lines.append('')
    
    for data_file in data_files:
        filepath = os.path.join(base_dir, data_file)
        output_lines.append(f'; === {data_file} ===')
        output_lines.append('')
        
        lines = process_file(filepath)
        for line in lines:
            output_lines.append(line)
        
        output_lines.append('')
    
    # Write output
    with open(output_file, 'w', encoding='utf-8') as f:
        for line in output_lines:
            f.write(line + '\n')
    
    print(f'Converted output written to {output_file}')
    print(f'Total lines: {len(output_lines)}')

if __name__ == '__main__':
    main()
