# UMML: Universal Low-Level Language
**Talking Directly to the Machine. Minimizing Abstraction. Maximizing Certainty.**

![UMML Stage 5 CI](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/gate-map.yml/badge.svg)
![UMML ASIC Synthesis Check](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/yosys-synth.yml/badge.svg)
![UMML RTL CI](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/rtl_ci.yml/badge.svg)

📄 **[Read the Official UMML Technical Whitepaper](https://docs.google.com/document/d/1hXlei_voO40i-5OnjcGMmUQP1mBNZg8GKK7_POBxTQQ/edit?usp=drivesdk)**

<div style="background-color: #ffffff; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
    <p align="center">
        <img src="./swarm_gate_map.svg" alt="UMML Spatial Fabric Gate Map" width="100%">
    </p>
</div>

## 🚀 The Paradigm Shift: Death of the Software-vs-Hardware Trade-off

For decades, computing has been trapped in a zero-sum game: specialized hardware accelerators offer performance but lack software compatibility, while general-purpose CPUs (x86, ARM, RISC-V) are burdened by power-hungry, line-by-line instruction loops and rigid architecture lock-in.

**UMML destroys this barrier.** 

It is no longer just a microarchitectural simulator. It is a **zero-abstraction, self-proving, metamorphic hardware compiler**. By translating high-level intent (or legacy assembly) directly into asynchronous spatial dataflow graphs, UMML allows the silicon to physically morph to match the algorithm, all while running on a minimalist, zero-bloat POSIX toolchain.

---

## 🏆 The 4 Uncontestable Features

UMML introduces four foundational pillars that make direct comparison to traditional processors obsolete:

### 1. The Self-Proving Compiler
Traditional architectures require millions of hours of constrained-random simulation to find race conditions. UMML’s plain-English spatial compiler (`compiler.awk`) natively embeds **Formal Mathematical Proof Encodings (SystemVerilog Assertions)** into the routing bitstream. As the compiler maps spatial routes, it generates self-contained proofs guaranteeing that deadlock, timing hazards, and state conflicts are mathematically impossible.

### 2. Metamorphic Spatial Obfuscation
Existing secure hardware relies on static encryption, leaving them vulnerable to microscopic timing and side-channel attacks (e.g., Spectre, Meltdown). UMML introduces **metamorphic routing**: the hardware actively and dynamically scrambles its internal physical layout across the cell matrix mid-execution using XOR-based key rotation. Every time an algorithm runs, the data takes an entirely different spatial route, rendering physical layout tracing completely blind.

### 3. Fully Decoupled Native Cross-Architecture Compilation
High-level compilers like LLVM translate software into one narrow target language at a time. UMML’s Stage 3 Native Code Generation acts as a **Universal Architectural Bridge**. Lightweight POSIX mappers (`spatial_mapper.awk`, `spatial_mapper_x86.awk`) ingest standard compiled input binaries (RISC-V, x86-64), decode the underlying dataflow dependencies, and dynamically rebuild the logic into an optimized, conflict-free Spatial Dataflow Graph. Architecture lock-in is dead.

### 4. Deterministic Hardware Clock Flank Isolation ("The Spine")
Pure asynchronous systems are incredibly efficient, but initialization benefits from deterministic timing. UMML implements **The Spine**: a hardware isolator that uses a global clock *only* for the initial deterministic setup. The moment setup is complete, the clock is physically gated off, and the entire chip operates purely on asynchronous handshake pressure, consuming **zero global clock power**.

---

## 🏗️ Architecture & Core Principles

UMML combines a low-level programming language with microarchitectural primitives that model real physical behavior:

- **Propagation:** State changes take time. Operations have latency determined by the physical hardware resources involved.
- **State Decoupling:** Architectural state and microarchitectural state are separate. 
- **Contention:** Hardware resources are finite. Backpressure and timing effects emerge naturally from async handshakes (`req`/`ack`).
- **Spatial Dataflow:** Computation is described as a graph of processing elements and routing paths, not a linear instruction stream.

---

## 🥁 The Ultimate Proof: Asynchronous Music Sequencer

To prove these concepts, UMML includes a fully functional, clockless drum machine (`sequencer_no_assert.umml`). 

```text
# 1. Deterministic Initialization
spine the clock to step_kick for init

# 2. Memory Storage
make a memory named step_kick with size 16

# 3. Metamorphic Routing (Feature 2)
make a metamorphic router named secure_bus_kick
morph the spike from step_kick through secure_bus_kick to kick_drum with key 8'hF0

# 4. Async Tempo Trigger
make a neuron named tempo_master with threshold 1 and leak 0
flow the spike from tempo_master into the read of step_kick
```

When compiled and simulated, this design:
1. Uses **The Spine** for deterministic setup, then gates the clock off.
2. Routes the tempo spike through a **Metamorphic Router**, dynamically scrambling the physical path.
3. Triggers the drum neuron via pure **Asynchronous Handshake Pressure**.
4. Is accompanied by **Formal Assertions** proving the routing cannot deadlock.

*Zero global clock power consumed during playback. Pure physical dataflow.*

---

## 🛠️ Zero-Bloat Toolchain

UMML's toolchain requires **no Python, no C, and no massive EDA suites**. It runs entirely on native POSIX shell, `awk`, and Icarus Verilog.

```bash
# 1. Compile plain English (or mapped assembly) to Verilog
./umml_compile sequencer_no_assert.umml

# 2. Simulate the async dataflow
iverilog -g2012 -o sim_sequencer creidyll_brainstem/rtl/*.sv sequencer_no_assert.v tb_sequencer.sv
vvp sim_sequencer

# 3. Synthesize to physical FPGA silicon (Lattice iCE40)
./build_fpga.sh sequencer_no_assert.v
```

---

## 📂 Project Structure

- `compiler.awk` / `umml_compile_simple`: The core plain-English to Verilog spatial compilers.
- `spatial_mapper.awk` / `spatial_mapper_x86.awk`: Cross-architecture translators (RISC-V/x86 to UMML dataflow).
- `creidyll_brainstem/rtl/`: Synthesizable hardware primitives (`async_lif_neuron`, `async_metamorphic_router`, `async_clock_spine`, `async_memory_cell`).
- `build_fpga.sh`: Open-source FPGA synthesis pipeline (Yosys + nextpnr + IceStorm).
- `metamorphic_router_proof.sby`: SymbiYosys formal verification framework for mathematical deadlock proofs.
- `*.umml`: Plain-English hardware descriptions.

---

## ⚖️ Legal and Ethical Disclaimer

UMML is intended for educational, defensive, and academic research into hardware security, microarchitectural behavior, and novel computing paradigms. Use it only on hardware and systems you are authorized to study. Follow responsible disclosure practices when researching real hardware vulnerabilities.

---

## 📜 License

This project is licensed under the **Apache License 2.0**.  
This includes all hardware description files (`.sv`), scripts (`.sh`, `.awk`), and documentation. You are free to use, modify, and distribute this work, provided you retain the original copyright and license notices.

See the [LICENSE](LICENSE) file for full details.
