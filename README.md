

# UMML: Universal Low-Level Language Talking Directly to the Machine. Minimizing Abstraction.
![UMML Stage 5 CI](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/iverilog-ci.yml/badge.svg) ![UMML ASIC Synthesis Check](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/yosys-synth.yml/badge.svg)
### Silicon Gate Map: Swarm Node
![Swarm Node Gate-Level Schematic](./swarm_gate_map.svg)

📄[Read the Official UMML Technical Whitepaper](https://docs.google.com/document/d/1hXlei_voO40i-5OnjcGMmUQP1mBNZg8GKK7_POBxTQQ/preview)

UMML is a hardware-near programming, assembly, and microarchitectural modeling language for studying how computer hardware actually behaves.

Most hardware security simulators hide the details that matter. They may simply report a cache miss or a bit flip without exposing the timing, state changes, contention, and interactions underneath. UMML is designed to model those lower-level behaviors directly. It combines a low-level programming language with microarchitectural primitives that can represent things such as cache coherence, NoC traffic, speculation, timing, and resource contention.
 The Paradigm Shift: Beyond Von Neumann
Traditional computing is trapped by the "Von Neumann Bottleneck": a rigid cycle of fetching instructions from memory, decoding them through an ISA (Instruction Set Architecture), and executing them sequentially over a shared bus. This abstraction layer hides the physical reality of the silicon.

"UMML breaks this paradigm entirely." 

1. "The Code *Is* The Circuit:" In UMML, writing `CONNECT node_A TO node_B` is not a software command. It is a direct, physical configuration of a hardware crossbar multiplexer. The source code literally maps to physical copper paths.2. "Bypassing the ISA Abstraction:" For spatial workloads, UMML does not compile down to RISC-V, x86, or ARM instructions. There is no instruction fetch, no decode stage, and no program counter overhead. High-level spatial intent is compiled directly into a hardware configuration bitstream.3. **Bound by the Physical Clock:** This is not a high-level software simulation running on a host CPU's clock. UMML is a fully synthesizable Verilog architecture. Every operation, token transfer, and state change is strictly bound by real clock edges, propagation delays, and physical state machines. Time is a first-class, programmable citizen.
🏛️ Architecture & Core Principles
UMML operates across three main layers:1. **UMML Source** — Defines the experiment, access pattern, timing measurement, or spatial dataflow graph.2. "Copper ISA" — A custom 16-bit instruction set used by the Copper processor (for traditional sequential fallback).3. **Copper Microarchitecture** — A synthesizable Verilog implementation that models registers, caches, NoC resources, latency, state, and contention.
### Core Principles- **Propagation:** State changes take time. Operations have latency determined by the physical hardware resources involved.- **State Decoupling:** Architectural state and microarchitectural state are separate. Rolling back architectural state does not remove changes that occurred inside the microarchitecture.- **Contention:** Hardware resources are finite. When multiple operations compete for the same resources, backpressure and timing effects appear naturally.
### Microarchitectural DomainsUMML models multiple hardware domains to study vulnerabilities that emerge from their interactions:- Cache coherence and MOESI state transitions / RFO traffic- NoC routing, virtual channels, arbitration, and backpressure- DRAM charge and leakage behavior- Speculative execution and branch prediction- Microarchitectural state that survives architectural rollback
 The UMML Execution Matrix
UMML was constructed by mastering and then transcending every major paradigm in computer architecture.
### Stage 1: The 5-Stage In-Order PipelineThe foundation. A classic, deterministic fetch-decode-execute-memory-writeback pipeline, establishing the baseline for instruction propagation, hazard detection, and structural stall modeling.
### Stage 2: VLIW (Very Long Instruction Word)Static superscalar execution, proving the engine's ability to handle wide, compiler-bundled instruction streams and exposing how static scheduling relies on finding instruction-level parallelism without hardware intervention.
### Stage 3: Native Code Generation (The Bootstrap)UMML includes a native code-generation stage, demonstrating a bootstrap process where the target architecture participates in building its own executable code. The Copper processor can read numerical representations of source instructions from data memory, perform bitwise operations, construct machine-code words (including valid RISC-V encodings), write them into instruction memory, and execute them.
### Stage 4: Out-of-Order Execution & The Dataflow SwarmA major paradigm shift abandoning the rigid program counter in favor of dynamic, data-driven execution.- **Register Renaming & ROB:** Eliminates false dependencies (WAR/WAW hazards) while maintaining in-order retirement.- Tomasulo’s Algorithm: Decentralized scheduling via reservation stations.- **Speculative Execution:** Branch prediction with microarchitectural state rollback on misprediction.- **The Decentralized Dataflow Swarm:** A token-driven contract where nodes execute only when all input tokens are present, featuring configurable latency, broadcast-and-release, and anti-collision backpressure.
### Stage 5: Native Spatial Compiler & Pre-Silicon SecurityStage 5 introduces a fundamentally different execution model. Instead of translating a program into instructions for a conventional CPU, UMML describes computation as a **spatial dataflow graph**. The compiler converts the graph into a hardware configuration bitstream, and the hardware fabric uses that configuration to establish the required processing elements and routing paths.
- **5.1 The Hardware Compiler Pipeline (Text-to-Silicon):** UMML does not rely on external software (Python/C++) to bootstrap itself. The Stage 5 compiler is **physical hardware**. An ASCII stream passes through a Hardware Lexer (spatial shift-register pattern matching), a Hardware Parser (ASCII-to-binary token conversion), and Allocator/Config Nodes (dataflow joins that physically write silicon configuration registers).- **5.2 The Spatial Fabric (GRID & CONNECT):** UMML treats wires as programmable entities. When text is parsed, the hardware physically flips the multiplexers inside a Crossbar Switch, creating a zero-latency copper path between compute nodes.
- **5.3 Pre-Silicon Side-Channel Analysis (DPA):** UMML includes a `POWER_MONITOR_NODE` that taps physical data buses. It calculates the Hamming Weight (number of switching transistors) of every operation, simulating dynamic power draw ($I_{DD}$). We successfully simulated a hacker extracting a secret memory value purely by observing power fluctuations, without ever touching the memory bus.- **5.4 Cryptographic Shielding (WDDL & Constant-Time):** 
  - **Dual-Rail Logic (WDDL):** We built a Spatial Mini-AES Engine and wrapped it in a Dual-Rail Encoder. Every bit is represented by two physical wires (True and False). The Hamming Weight is mathematically locked. The power line becomes a flat line. The hacker is blinded.
  - **Constant-Time Execution:** We neutralized timing attacks by replacing vulnerable `if/else` branches with Speculative Execution Muxing. The hardware executes *both* code paths simultaneously and uses a physical multiplexer to select the correct result. Execution time is always identical.
- **5.5 Robust Edge-Triggered Handshaking:** To prevent "ghost latch" race conditions and infinite feedback loops in the continuous clock domain, all inter-node communication utilizes strict edge-triggered handshaking (`valid_pulse = valid && !prev_valid`). This ensures configuration tokens and data payloads are consumed exactly once per transaction, guaranteeing deterministic, glitch-free silicon behavior.
#### Spatial Intent Syntax```umml
NODE mac_unit {
    LATENCY 3; // Physically configures a 3-cycle down-counter in silicon
    res <= a * b;
}

GRID 2x2 {
    CONNECT mac_unit.res TO mac_unit.a; // Physically flips crossbar muxes
}
```
#### Pre-Silicon Side-Channel Analysis Trace```text
============================================
=== UMML SIDE-CHANNEL POWER ANALYSIS ===
============================================
[SYSTEM] Tapping physical data bus (mem_read_data)...

--- SCENARIO: Processing Secret Value 20 ---
[COMPILER] Store armed.
[NODE 0] Computed 20.
[MEMORY] Data 20 read from bus.
[POWER] Bus activity: 2 units ($I_{DD}$ spike).
[HACKER] Low power draw. Hamming Weight = 2. Secret is likely 20 (10100).

============================================
=== SECURITY AUDIT COMPLETE ===
============================================
SIDE-CHANNEL LEAK CONFIRMED. DATA EXTRACTED VIA POWER LINE.
```
---## 🛠️ CPU Toolchain
UMML's initial toolchain does not require Python, C, or another host compiler. It relies purely on POSIX shell, awk, and Icarus Verilog.
```bash
./asm.sh chained_hunt.cop program.hex
./gen_tb.sh program.hex testbench.sv
iverilog -o umml_sim design.sv testbench.sv
vvp umml_sim
```

For the Stage 5 Spatial Compiler:```bash
cd stage5_spatial
iverilog -g2012 -o umml_stage5_sim stage5_design.sv stage5_tb.sv
vvp umml_stage5_sim
```
### Example: Microarchitectural InteractionA UMML research program can combine NoC contention, speculative execution, and timing measurement:
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
In this simulated experiment, NoC backpressure increased the observed latency from normal noisy cache behavior to an approximately 41-cycle delta. The model exposes the exact interaction between different microarchitectural resources.
---## Project Structure
- `asm.sh` and `gen_tb.sh` form the original Copper toolchain.


* spatial_asm.sh and gen_spatial_tb.sh handle the spatial compiler.
* design.sv contains the synthesizable hardware implementation, including the Copper processor.
* bootstrap_tb.sv and assembler_engine.cop demonstrate native code generation.
* graph.umml contains spatial programs.
* *.cop files contain microarchitectural research programs.
* stage5_spatial/ contains the Stage 5 self-hosting spatial compiler, crossbar routing, memory fabric, and pre-silicon security modules (power_monitor_node, dual_rail_encoder, constant_time_node).

------------------------------
## Why UMML Exists
Hardware vulnerabilities often appear at the boundaries between different components. A cache-coherence problem can interact with NoC contention. NoC behavior can affect timing. Speculation can leave microarchitectural state behind. Memory behavior can introduce another source of timing variation.
UMML is intended to give researchers a low-level environment for exploring those interactions directly, bridging the gap between high-level architectural simulation and physical silicon reality. It proves that we can design, route, and secure complex spatial fabrics before the chip is ever manufactured.
------------------------------
## 🤝 Contributing
UMML is an evolving open-source project. Contributions can include new instructions, microarchitectural models, coherence protocols, memory models, spatial operations, and hardware-security experiments.
------------------------------
## ⚖️ Legal and Ethical Disclaimer
UMML is intended for educational, defensive, and academic research. Use it only on hardware and systems you are authorized to study. Do not use it to access, extract data from, or compromise systems without permission. Follow responsible disclosure practices when researching real hardware vulnerabilities.
------------------------------
##Opportunities & Contact
UMML is open-source and free to use. However, I am currently open to:
- **Full-time roles** in Hardware Security, Pre-Silicon Verification, or Silicon Architecture.
- **Consulting contracts** for RTL side-channel analysis, DPA modeling, or secure hardware design.

If your team is building secure silicon and needs expertise in constant-time execution, spatial dataflow, or microarchitectural modeling, let's talk.
Email: banjojesuloba@gmail.com
LinkedIn: https://www.linkedin.com/in/banjo-jesuloba-8a9916421?utm_source=share_via&utm_content=profile&utm_medium=member_android
____________________________________
Created and maintained by 0x-jbfrizzy (Jesuloba Banjo).