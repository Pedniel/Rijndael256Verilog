#!/usr/bin/env python3
from py3rijndael import Rijndael

def hexbytes(h):
    h2 = h.strip().replace(" ", "").replace("\n","")
    if any(c not in "0123456789abcdefABCDEF" for c in h2):
        raise ValueError(f"Non-hexadecimal character found in hex string: {h!r}")
    return bytes.fromhex(h2)

key_hex  = "FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210"
key = hexbytes(key_hex)
block_size = 32 
plaintext_hex_list = [
    "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    "00112233445566778899AABBCCDDEEFF000102030405060708090A0B0C0D0E0F",
    "6BC1BEE22E409F96E93D7E117393172AAE2D8A571E03AC9C9EB76FAC45AF8E51"
]

cipher = Rijndael(key, block_size=block_size)

print("Key =", key_hex)
for pt_hex in plaintext_hex_list:
    if len(pt_hex.replace(" ", "").replace("\n","")) != block_size*2:
        raise ValueError(f"Plaintext hex length {len(pt_hex)} chars != expected {block_size*2}. Value: {pt_hex!r}")
    pt = hexbytes(pt_hex)
    ct = cipher.encrypt(pt)
    print("PT =", pt_hex)
    print("CT =", ct.hex().upper())
    print()
