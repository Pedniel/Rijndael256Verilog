#!/usr/bin/env python3
from py3rijndael import Rijndael
import os
import struct

##############
# !CTR MODE! #
##############

def hexbytes(h):
    h2 = h.strip().replace(" ", "").replace("\n", "")
    if any(c not in "0123456789abcdefABCDEF" for c in h2):
        raise ValueError(f"Non-hexadecimal character found in hex string: {h!r}")
    return bytes.fromhex(h2)

block_size = 32  # bytes for 256-bit block

# These testcases are hardcoded to match the verilog testbench
# It would be cleaner to use a common input file for both, but this works for now 
test_cases = [
    {
        "name": "Test 1: All zeros with 192-bit key",
        "key": "000000000000000000000000000000000000000000000000",
        "nonce": "0000000000000000000000000000000000000000000000000000000000000000",
        "plaintext": "0000000000000000000000000000000000000000000000000000000000000000"
    },
    {
        "name": "Test 2: Pattern with 192-bit key",
        "key": "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",
        "nonce": "1000000000000000000000000000000000000000000000000000000000000000",
        "plaintext": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    }
]

def encrypt_ctr(pt: bytes, iv: bytes, cipher_obj: Rijndael) -> bytes:
    if len(iv) != len(pt):
        raise ValueError("IV length must equal block size")
    keystream = cipher_obj.encrypt(iv)
    ct = bytes(a ^ b for (a, b) in zip(pt, keystream))
    return ct

print("Rijndael-256 CTR Mode Test Vector Generation")
print("=" * 60)
print()

for test in test_cases:
    print(test["name"])
    print("-" * 60)
    
    key = hexbytes(test["key"])
    nonce = hexbytes(test["nonce"])
    pt = hexbytes(test["plaintext"])
    
    cipher = Rijndael(key, block_size=block_size)
    
    ct = encrypt_ctr(pt, nonce, cipher)
    
    print(f"Key:        {test['key']}")
    print(f"Nonce:      {test['nonce']}")
    print(f"Plaintext:  {test['plaintext']}")
    print(f"Ciphertext: {ct.hex().upper()}")
    print()

# ECB mode:
#######################################################################################################################
# def hexbytes(h):                                                                                                    #
#     h2 = h.strip().replace(" ", "").replace("\n","")                                                                #
#     if any(c not in "0123456789abcdefABCDEF" for c in h2):                                                          #
#         raise ValueError(f"Non-hexadecimal character found in hex string: {h!r}")                                   #
#     return bytes.fromhex(h2)                                                                                        #
#                                                                                                                     #
# key_hex  = "FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210"                                       #
# key = hexbytes(key_hex)                                                                                             #
# block_size = 32                                                                                                     #
# plaintext_hex_list = [                                                                                              #
#     "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",                                             #
#     "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",                                             #
#     "00112233445566778899AABBCCDDEEFF000102030405060708090A0B0C0D0E0F",                                             #
#     "6BC1BEE22E409F96E93D7E117393172AAE2D8A571E03AC9C9EB76FAC45AF8E51"                                              #
# ]                                                                                                                   #
#                                                                                                                     #
# cipher = Rijndael(key, block_size=block_size)                                                                       #
#                                                                                                                     #
# print("Key =", key_hex)                                                                                             #
# for pt_hex in plaintext_hex_list:                                                                                   #
#     if len(pt_hex.replace(" ", "").replace("\n","")) != block_size*2:                                               #
#         raise ValueError(f"Plaintext hex length {len(pt_hex)} chars != expected {block_size*2}. Value: {pt_hex!r}") #
#     pt = hexbytes(pt_hex)                                                                                           #
#     ct = cipher.encrypt(pt)                                                                                         #
#     print("PT =", pt_hex)                                                                                           #
#     print("CT =", ct.hex().upper())                                                                                 #
#     print()                                                                                                         #
#######################################################################################################################
