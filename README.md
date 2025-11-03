# Rijndael256Verilog

Simple 32 bit block size Rjindael implementation in verilog.

Decryption and encryption for both ECB and CTRL mode.

For CTR mode, use rijndael256_ctr.v as top-level file.
For ECB mode, use rijndael256_top.v.
192/256 bit key mode, controlled by key_mode input (0 for 192, 1 for 256).
32 Byte Block size.

Will implement a cleaner CTR/ECB mode switch.

Includes testbench with different modules for testing encryption/decryption/ecb and ctr mode.


WORK IN PROGRESS

To verify simulation results, compare with py3rijndael library: 

# Rijndael 256-bit Block Test Vector Generator

## Purpose  
Simple Python script to generate test vectors for a 256-bit-block version of the Rijndael cipher (block-size = 256 bits, key size = 192/256 bits) for use in Verilog verification.

## Verification  
- `test_vectors.py` generates plaintext-ciphertext pairs using a fixed 192/256-bit key.

Use by using the same testvectors in verilog and in the test_vectors.py script.

## Setup (for Python environment)
```sh
python3 -m venv venv

source venv/bin/activate

pip install py3rijndael

python test_vectors.py
```

