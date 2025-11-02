#!/usr/bin/env python3
from py3rijndael import Rijndael
import os

def hexbytes(h):
    h2 = h.strip().replace(" ", "").replace("\n", "")
    if any(c not in "0123456789abcdefABCDEF" for c in h2):
        raise ValueError(f"Non-hexadecimal character found in hex string: {h!r}")
    return bytes.fromhex(h2)

block_size = 32  # 256-bit block size

test_cases = [
    {
        "name": "All zeros with 192-bit key",
        "key": "000000000000000000000000000000000000000000000000",
        "nonce": "0000000000000000000000000000000000000000000000000000000000000000",
        "plaintext": "0000000000000000000000000000000000000000000000000000000000000000"
    },
    {
        "name": "Pattern with 192-bit key",
        "key": "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",
        "nonce": "1000000000000000000000000000000000000000000000000000000000000000",
        "plaintext": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    }
]

def encrypt_ctr(pt: bytes, iv: bytes, cipher_obj: Rijndael) -> bytes:
    if len(iv) != cipher_obj.block_size:
        raise ValueError("IV length must equal block size")
    keystream = cipher_obj.encrypt(iv)
    return bytes(a ^ b for (a, b) in zip(pt, keystream))

print("Rijndael-256 ECB + CTR Mode Test Vector Generation")
print("=" * 70)
print()

for test in test_cases:
    print(test["name"])
    print("-" * 70)

    key = hexbytes(test["key"])
    nonce = hexbytes(test["nonce"])
    pt = hexbytes(test["plaintext"])
    
    cipher = Rijndael(key, block_size=block_size)

    # ECB encryption
    ct_ecb = cipher.encrypt(pt)

    # CTR encryption using the same key etc
    ct_ctr = encrypt_ctr(pt, nonce, cipher)

    print(f"Key:        {test['key']}")
    print(f"Nonce:      {test['nonce']}")
    print(f"Plaintext:  {test['plaintext']}")
    print(f"ECB CT:     {ct_ecb.hex().upper()}")
    print(f"CTR CT:     {ct_ctr.hex().upper()}")
    print()
