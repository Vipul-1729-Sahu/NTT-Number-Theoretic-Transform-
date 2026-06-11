# FPGA-Based NTT/INTT Core for ML-KEM Using Verilog

## Project Overview

This project implements a **Number Theoretic Transform (NTT)** and **Inverse Number Theoretic Transform (INTT)** hardware core in **Verilog**.
The NTT is an important mathematical block used in **ML-KEM/Kyber**, which is a post-quantum cryptography algorithm.

In ML-KEM, polynomial multiplication is one of the most important operations. Direct polynomial multiplication is slow because it requires many coefficient-by-coefficient multiplications. NTT helps to perform this multiplication faster by converting polynomials into a special transform domain, where multiplication becomes much simpler.

This project focuses only on the **NTT/INTT hardware block** used inside ML-KEM polynomial arithmetic.
It is **not a complete ML-KEM/Kyber cryptographic processor**.

---

## What This Project Implements

This project includes:

* Forward NTT
* Inverse NTT
* FSM-based control logic
* Coefficient memory
* Zeta ROM / twiddle factor ROM
* Modular addition and subtraction
* Montgomery modular multiplication
* Load/read interface for input and output coefficients
* Vivado simulation testbench
* Round-trip verification using NTT followed by INTT

---

## What This Project Does Not Implement

This project does not implement the complete ML-KEM algorithm.

The following ML-KEM blocks are not included:

* Key generation
* Encapsulation
* Decapsulation
* Hashing
* Compression and decompression
* Encoding and decoding
* CBD sampler
* Complete Kyber/ML-KEM processor

The main focus of this project is the **hardware acceleration of NTT and INTT**, which is one of the core computational blocks used inside ML-KEM.

---

# Why NTT is Needed

In post-quantum cryptography algorithms like ML-KEM/Kyber, operations are performed on polynomials.

A polynomial looks like this:

```text
a(x) = a0 + a1*x + a2*x^2 + ... + a255*x^255
```

In ML-KEM, these polynomials usually have 256 coefficients.

If we multiply two polynomials directly, every coefficient of one polynomial has to interact with many coefficients of the other polynomial. This direct method is computationally expensive.

For a polynomial of size `n`, direct multiplication has approximately:

```text
O(n^2)
```

complexity.

For `n = 256`, this becomes a large number of operations.

NTT reduces the complexity to approximately:

```text
O(n log n)
```

This makes polynomial multiplication much faster and more hardware-friendly.

---

# What is NTT?

NTT stands for **Number Theoretic Transform**.

It is similar in idea to FFT, but instead of using floating-point or complex numbers, NTT works completely with integers under modular arithmetic.

FFT is commonly used for signal processing and uses complex roots of unity.
NTT is used in cryptography because it works with exact integer values modulo a prime number.

In this project, the modulus used is:

```text
q = 3329
```

This is the modulus used in ML-KEM/Kyber polynomial arithmetic.

All coefficient operations are performed modulo 3329.

That means after every arithmetic operation, the result remains in the range:

```text
0 to 3328
```

---

# NTT vs FFT

| Feature                         | FFT                      | NTT                        |
| ------------------------------- | ------------------------ | -------------------------- |
| Full form                       | Fast Fourier Transform   | Number Theoretic Transform |
| Number system                   | Complex / floating-point | Integer modular arithmetic |
| Accuracy                        | May have rounding errors | Exact arithmetic           |
| Used in                         | Signal processing        | Cryptography               |
| Root type                       | Complex root of unity    | Modular root of unity      |
| Hardware suitability for crypto | Less preferred           | More preferred             |

NTT is preferred in cryptographic hardware because it avoids floating-point operations and rounding errors.

---

# How NTT Helps in Polynomial Multiplication

Polynomial multiplication can be performed in three steps:

```text
1. Apply NTT to polynomial A
2. Apply NTT to polynomial B
3. Multiply corresponding coefficients
4. Apply inverse NTT to get the final polynomial
```

So instead of doing complex polynomial multiplication directly, NTT converts the problem into simpler point-wise multiplication.

In simple words:

```text
Coefficient domain  →  NTT domain  →  Point-wise multiplication  →  Coefficient domain
```

This is why NTT is very important in ML-KEM/Kyber.

---

# Forward NTT

Forward NTT converts a polynomial from the normal coefficient domain into the NTT domain.

The forward NTT in this project uses butterfly operations.

A butterfly operation takes two coefficients and combines them using a special constant called `zeta`.

For two coefficients `a` and `b`, the forward butterfly is:

```text
t      = zeta * b mod q
new_a  = a + t mod q
new_b  = a - t mod q
```

Here:

```text
q = 3329
```

So all results are reduced modulo 3329.

---

# Inverse NTT

Inverse NTT converts the polynomial from the NTT domain back to the normal coefficient domain.

The inverse butterfly operation is different from the forward butterfly.

For two coefficients `a` and `b`, the inverse butterfly is:

```text
new_a = a + b mod q
new_b = zeta * (b - a) mod q
```

After all inverse NTT stages are completed, final scaling is required.
This scaling is needed because inverse transform produces a scaled version of the original polynomial.

In this project, the final scaling factor is applied using Montgomery multiplication.

---

# Butterfly Operation

The butterfly operation is the basic building block of NTT.

It is called a butterfly because the flow of data looks like butterfly wings.

A simple forward butterfly looks like this:

```text
                t = zeta * b

a ---------------- (+) ----> a + t

b ---- × zeta ---- (-) ----> a - t
```

Each butterfly takes two input coefficients and produces two output coefficients.

For a 256-point NTT, the design performs multiple stages of butterfly operations.

---

# Zeta / Twiddle Factor

`zeta` is a precomputed constant used in the butterfly operation.

It is similar to the twiddle factor used in FFT.

In FFT, twiddle factors are complex roots of unity.
In NTT, zeta values are modular roots of unity.

In this project, the zeta values are stored in a ROM called:

```text
zeta_ROM
```

During each butterfly operation, the controller selects the required zeta value from the ROM.

Using a ROM avoids recalculating zeta values again and again during runtime.

---

# Modular Arithmetic

Since this project works with modulus:

```text
q = 3329
```

all arithmetic operations are performed modulo 3329.

For addition:

```text
if a + b >= q
    subtract q
```

For subtraction:

```text
if a >= b
    result = a - b
else
    result = a + q - b
```

This ensures that every coefficient remains within the valid range:

```text
0 to 3328
```

---

# Montgomery Multiplication

NTT requires many modular multiplications.

A normal modular multiplication looks like this:

```text
result = (a * b) mod q
```

But direct modulo operation can be expensive in hardware because division is costly.

To avoid expensive division, this project uses **Montgomery multiplication**.

Montgomery multiplication is a method to perform modular multiplication efficiently using:

* multiplication
* bit extraction
* shifting
* addition
* comparison
* subtraction

The Montgomery parameters used are:

```text
q     = 3329
R     = 2^16
QINV  = 3327
```

Here, `R = 2^16` is chosen because it is a power of two and greater than `q`.

This makes hardware implementation easier because:

```text
mod 2^16  = lower 16 bits
divide by 2^16 = right shift by 16
```

So Montgomery multiplication avoids direct division by 3329.

---

# Why Montgomery Multiplication is Useful in Hardware

In hardware design, division and modulo operations are usually expensive.

For example:

```text
(a * b) % 3329
```

may create complex hardware if written directly.

Montgomery multiplication avoids this by converting the modulo operation into simple hardware-friendly operations.

This is useful for FPGA/ASIC implementation because it can improve timing and reduce complexity.

---

# High-Level Architecture

The design consists of the following main blocks:

```text
                 +-------------------+
                 |     NTT Core      |
                 +-------------------+
                          |
       -----------------------------------------
       |           |             |             |
+-------------+ +----------+ +-----------+ +----------------+
| FSM Control | | Zeta ROM | | Coeff Mem | | Montgomery Mult |
+-------------+ +----------+ +-----------+ +----------------+
       |
+----------------------------+
| Modular Add/Sub Operations |
+----------------------------+
```

---

# Main Design Blocks

## 1. FSM Controller

The FSM controls the complete NTT and INTT operation.

It decides:

* which coefficients to read
* which zeta value to use
* when to start Montgomery multiplication
* when to write results back
* when to move to the next butterfly
* when the full NTT/INTT operation is complete

The design is implemented as a sequential hardware controller instead of using large combinational loops.

This makes the design more suitable for FPGA implementation.

---

## 2. Coefficient Memory

The input polynomial coefficients are stored in internal coefficient memory.

Each coefficient is 12 bits wide because the modulus is 3329, and 12 bits are enough to represent values from 0 to 4095.

The memory stores 256 coefficients.

```text
Number of coefficients = 256
Coefficient width      = 12 bits
```

The current placement/interview version uses a simple memory access structure and does not use an advanced dual-port/banked memory architecture.

---

## 3. Zeta ROM

The zeta ROM stores precomputed zeta values used during NTT and INTT butterfly operations.

Instead of calculating zeta values during runtime, the values are stored in ROM.

This saves hardware and simplifies the controller.

---

## 4. Montgomery Multiplier

The Montgomery multiplier performs modular multiplication efficiently.

It is used in:

* forward butterfly multiplication
* inverse butterfly multiplication
* final inverse scaling

---

## 5. Load/Read Interface

The design includes a load/read interface to provide input coefficients and read output coefficients.

This avoids using a very large input/output bus.

Instead of giving all 256 coefficients at once, coefficients can be loaded one by one using address and data signals.

Similarly, output coefficients can be read one by one.

This makes the design cleaner and more practical.

---

# Design Flow

The working flow of the project is:

```text
1. Load 256 input coefficients into coefficient memory
2. Start Forward NTT
3. Perform butterfly operations stage by stage
4. Store Forward NTT result
5. Run Inverse NTT on the result
6. Apply final inverse scaling
7. Read output coefficients
8. Compare output with original input
```

If the final output matches the original input, the NTT and INTT operations are working correctly.

---

# Verification Methodology

The design was verified using a Vivado simulation testbench.

The testbench performs the following steps:

```text
1. Generate input polynomial coefficients
2. Load coefficients into the NTT core
3. Start Forward NTT
4. Wait for completion
5. Read Forward NTT result
6. Reload Forward NTT result
7. Start Inverse NTT
8. Wait for completion
9. Read final output
10. Compare final output with original input
```

The main verification check is:

```text
INTT(NTT(input)) = input
```

This is called round-trip verification.

If the input polynomial is recovered after forward NTT followed by inverse NTT, the design is considered functionally correct for the tested input.

---

# Example Verification Result

For example, if the input polynomial is:

```text
a[i] = i
```

then after applying Forward NTT followed by Inverse NTT, the output should again be:

```text
a[i] = i
```

The testbench checks all 256 coefficients.

If there are no mismatches, the simulation prints a pass message.

---

# Important Parameters

| Parameter         |   Value | Meaning                                    |
| ----------------- | ------: | ------------------------------------------ |
| n                 |     256 | Number of polynomial coefficients          |
| q                 |    3329 | Modulus used in ML-KEM/Kyber               |
| R                 |    2^16 | Montgomery radix                           |
| QINV              |    3327 | Montgomery constant                        |
| Coefficient width | 12 bits | Width required to store values modulo 3329 |

---

# Project Scope 

This GitHub repository is intended to show a hardware implementation of the NTT/INTT core.

The project demonstrates understanding of:

* RTL design using Verilog
* FSM-based hardware control
* Modular arithmetic
* Polynomial arithmetic acceleration
* Montgomery multiplication
* ROM-based constant storage
* FPGA-oriented design flow
* Simulation-based verification

This project is suitable as a digital design / VLSI / FPGA project.

---

# Limitations

The current version has some limitations:

* It implements only the NTT/INTT core, not the full ML-KEM algorithm.
* It processes butterfly operations sequentially.
* It does not use a fully parallel multi-butterfly architecture.
* It does not use advanced dual-port or banked memory optimization.
* It is not a fully pipelined high-throughput NTT accelerator.
* Verification is mainly based on round-trip testing.

These limitations are intentional for the placement version because the goal is to build a correct, understandable, and interview-defendable NTT hardware core.

---

# Possible Future Improvements

This project can be extended in several ways:

* Add dual-port BRAM-based coefficient memory
* Add memory banking for parallel butterfly units
* Add fully pipelined butterfly scheduling
* Add multiple butterfly units for higher throughput
* Compare output with an official ML-KEM reference model
* Add cycle count measurement
* Add resource utilization and timing comparison
* Integrate this NTT core into a larger ML-KEM hardware accelerator

---

# Why This Project is Useful

This project is useful because NTT is one of the most important computation blocks in lattice-based post-quantum cryptography.

By implementing NTT in Verilog, this project connects:

```text
Digital design
Cryptographic arithmetic
FSM-based control
FPGA implementation
Hardware acceleration
```

It also gives practical experience with designing arithmetic hardware and verifying it using simulation.

---

# Final Summary

This project implements a Verilog-based Forward NTT and Inverse NTT core for ML-KEM/Kyber polynomial arithmetic.

It uses:

* FSM control
* coefficient memory
* zeta ROM
* modular addition/subtraction
* Montgomery multiplication
* simulation-based verification

The design was verified using round-trip testing:

```text
INTT(NTT(input)) = input
```

This confirms that the Forward NTT and Inverse NTT operations are working correctly for the tested polynomial inputs.

The project is not a complete ML-KEM implementation, but it implements one of the most important hardware acceleration blocks used inside ML-KEM.

