# Rijndael256Verilog

Simple 32 bit block size Rjindael implementation in verilog.

Currently only encryption, ECB mode and 256 bit keys.

WORK IN PROGRESS

To verify simulation results, compare with py3rijndael library: 

# Rijndael 256-bit Block Test Vector Generator

## Purpose  
Simple Python script to generate test vectors for a 256-bit-block version of the Rijndael cipher (block-size = 256 bits, key size = 192/256 bits) for use in Verilog verification.

## Verification  
- `test_vectors.py` generates plaintext-ciphertext pairs using a fixed 256-bit key.

Use by using the same testvectors in verilog and in the test_vectors.py script.

## Setup (for Python environment)
```sh
python3 -m venv venv

source venv/bin/activate

pip install py3rijndael

python test_vectors.py
```

