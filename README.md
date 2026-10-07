# UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE
Talking directly to the CPU no Abstractions
_________________________________________

Talking directly to the machine. Minimizing abstraction.

UMML is a hardware-near programming, assembly, and microarchitectural modeling language for studying how computer hardware actually behaves.

Most hardware security simulators hide the details that matter. They may simply report a cache miss or a bit flip without exposing the timing, state changes, contention, and interactions underneath.

UMML is designed to model those lower-level behaviors directly.

It combines a low-level programming language with microarchitectural primitives that can represent things such as cache coherence, NoC traffic, speculation, timing, and resource contention.

## Architecture

UMML currently has three main layers:

1. UMML Source — defines the experiment, access pattern, timing measurement, or spatial dataflow graph.
2. Copper ISA — a custom 16-bit instruction set used by the Copper processor.
3. Copper Microarchitecture — a synthesizable Verilog implementation that models registers, caches, NoC resources, latency, state, and contention.

Unlike conventional assembly, UMML can describe behavior below the ISA level.

## Core Principles

**Propagation**
State changes take time. Operations have latency determined by the hardware resources involved.

**State Decoupling**
Architectural state and microarchitectural state are separate. Rolling back architectural state does not necessarily remove changes that occurred inside the microarchitecture.

**Contention**
Hardware resources are finite. When multiple operations compete for the same resources, backpressure and timing effects appear.

## Microarchitectural Domains

UMML can model multiple hardware domains, including:

- Cache coherence and MOESI state transitions
- RFO traffic and coherence latency
- NoC routing, virtual channels, arbitration, and backpressure
- DRAM charge and leakage behavior
- Speculative execution and branch prediction
- Microarchitectural state that survives architectural rollback
- Interactions between multiple hardware domains

The goal is to study vulnerabilities that emerge from the interaction between these components rather than looking at each component in isolation.

## CPU Toolchain

UMML's initial toolchain does not require Python, C, or another host compiler.

It uses POSIX shell, awk, and Icarus Verilog.

```bash
./asm.sh chained_hunt.cop program.hex
./gen_tb.sh program.hex testbench.sv
iverilog -o umml_sim design.sv testbench.sv
vvp umml_sim
```

## Example

A UMML research program can combine NoC contention, speculative execution, and timing measurement:

```assembly
MOV R0, R1
ADD R0, R0
ADD R0, R0
ADD R0, R0
ADD R0, R0
MOV R2, R1

VC_BLOCK 2

SAVE_REG
FORCE_MISPRED
LOAD R3, R0
ROLLBACK

READ_CYCLES R4
LOAD R5, R0
READ_CYCLES R6
SUB R6, R4

HALT
```

In the simulated experiment, NoC backpressure increased the observed latency from the normal noisy cache behavior to an approximately 41-cycle delta.

The important part is not the number itself. It is that the model exposes the interaction between different microarchitectural resources.

## Stage 3: Native Code Generation

UMML also includes a native code-generation stage.

The Copper processor can read numerical representations of source instructions from its data memory, perform the required bitwise operations, construct machine-code words, write them into instruction memory, and execute them.

This demonstrates a basic bootstrap process where the target architecture participates in building its own executable code.

The system can also construct 32-bit instruction payloads, including valid RISC-V encodings, with future work targeting ARM64 and x86-64 payload generation.

## Stage 5: Native Spatial Compiler

Stage 5 introduces a different execution model.

Instead of translating a program into instructions for a conventional CPU, UMML can describe computation as a spatial dataflow graph.

The compiler converts the graph into a hardware configuration bitstream. The hardware fabric uses that configuration to establish the required processing elements and routing paths.

For example:

```text
NODE 2 2 ADD WEST NORTH EAST
```

can be compiled with:

```bash
./spatial_asm.sh graph.umml config.hex
./gen_spatial_tb.sh
iverilog -o umml_sim design.sv testbench.sv
vvp umml_sim
```

The resulting computation happens through spatial dataflow. Operands move through the configured fabric, meet at the appropriate ALU, and the result propagates through the fabric.

There is no requirement for the computation to pass through a conventional RISC-V, ARM, or x86 instruction stream.

## Project Structure

- `asm.sh` and `gen_tb.sh` form the original Copper toolchain.
- `spatial_asm.sh` and `gen_spatial_tb.sh` handle the spatial compiler.
- `design.sv` contains the synthesizable hardware implementation, including the Copper processor and spatial fabric.
- `bootstrap_tb.sv` and `assembler_engine.cop` demonstrate native code generation.
- `graph.umml` contains spatial programs.
- `*.cop` files contain microarchitectural research programs.

## Why UMML Exists

Hardware vulnerabilities often appear at the boundaries between different components.

A cache-coherence problem can interact with NoC contention. NoC behavior can affect timing. Speculation can leave microarchitectural state behind. Memory behavior can introduce another source of timing variation.

UMML is intended to give researchers a low-level environment for exploring those interactions directly.

## Contributing

UMML is an evolving open-source project.

Contributions can include new instructions, microarchitectural models, coherence protocols, memory models, spatial operations, and hardware-security experiments.

## Legal and Ethical Disclaimer

UMML is intended for educational, defensive, and academic research.

Use it only on hardware and systems you are authorized to study. Do not use it to access, extract data from, or compromise systems without permission.

Follow responsible disclosure practices when researching real hardware vulnerabilities.