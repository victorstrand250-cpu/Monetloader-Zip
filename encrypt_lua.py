#!/usr/bin/env python3
"""
XOR-encrypts a Lua script and produces a self-decrypting Lua loader.
Usage: python3 encrypt_lua.py <input.lua> <output_xor.lua> [key]
"""
import sys
import os

def xor_encrypt(data: bytes, key: str) -> bytes:
    key_bytes = key.encode('utf-8')
    kl = len(key_bytes)
    return bytes(b ^ key_bytes[i % kl] for i, b in enumerate(data))

def bytes_to_lua_string(data: bytes) -> str:
    parts = []
    for b in data:
        if b == 0:
            parts.append(r'\0')
        elif b == ord('\\'):
            parts.append(r'\\')
        elif b == ord('"'):
            parts.append(r'\"')
        elif b == ord('\n'):
            parts.append(r'\n')
        elif b == ord('\r'):
            parts.append(r'\r')
        else:
            parts.append(chr(b) if 32 <= b <= 126 else f'\\{b}')
    return '"' + ''.join(parts) + '"'

LOADER_TEMPLATE = '''\
-- StrandFerma (XOR protected)
local bit = require("bit")
local function xor_decrypt(data, key)
    local res = {{}}
    local kl = #key
    for i = 1, #data do
        res[i] = string.char(bit.bxor(data:byte(i), key:byte(((i-1) % kl) + 1)))
    end
    return table.concat(res)
end

local _k = {key}
local _d = {data}
local _f, _e = load(xor_decrypt(_d, _k))
if _f then _f() else error("decrypt error: " .. tostring(_e)) end
'''

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} input.lua output_xor.lua [key]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]
    key = sys.argv[3] if len(sys.argv) > 3 else "StrandFerma2025!"

    with open(input_path, 'rb') as f:
        source = f.read()

    encrypted = xor_encrypt(source, key)
    lua_str = bytes_to_lua_string(encrypted)

    result = LOADER_TEMPLATE.format(
        key=f'"{key}"',
        data=lua_str,
    )

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(result)

    print(f"Done: {input_path} ({len(source)} bytes) -> {output_path} ({os.path.getsize(output_path)} bytes)")
    print(f"Key: {key}")

if __name__ == "__main__":
    main()
