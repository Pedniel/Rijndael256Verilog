# Rijndael256Verilog

Simple 32 bit block size Rjindael implementation in verilog.

Currently only encryption, hardcoded to CTR mode but can also do ECB mode and 192/256 bit keys, controlled by key_mode input (0 for 192, 1 for 256).

Will implement a cleaner CTR/ECB mode switch and block pipelining for CTR mode.

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

