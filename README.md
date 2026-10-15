# Creidyll

**Deterministic, Self-Proving Hardware for the Next Generation of Edge AI and Wearable Robotics.**

Talking directly to the machine. Minimizing abstraction. Maximizing certainty.

![UMML Stage 5 CI](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/gate-map.yml/badge.svg)
![UMML ASIC Synthesis Check](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/yosys-synth.yml/badge.svg)
![UMML RTL CI](https://github.com/0x-jbfrizzy/UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE/actions/workflows/rtl_ci.yml/badge.svg)

📄 **[Read the Official UMML Technical Whitepaper](https://docs.google.com/document/d/1hXlei_voO40i-5OnjcGMmUQP1mBNZg8GKK7_POBxTQQ/edit?usp=drivesdk)**

<p align="center">
    <img src="./swarm_gate_map.svg" alt="UMML Spatial Fabric Gate Map" width="100%">
</p>

Creidyll is an independent, deep-tech hardware and architecture initiative. We are building the foundational compute layer to solve the fundamental power, latency, and security bottlenecks in safety-critical physical computing. 

Our mission is to democratize advanced mobility and Edge AI—proving that high-performance, mathematically secure hardware does not require massive budgets, bloated toolchains, or venture capital pressure.

---

## The Core: UMML (Universal Low-Level Language)

For decades, computing has been trapped between two approaches: general-purpose processors (x86, ARM, RISC-V) that execute linear instructions with inherent latency, and specialized hardware accelerators that lack software compatibility.

UMML is a text-to-silicon spatial dataflow language that compiles plain-English logic (or legacy assembly) directly into asynchronous, self-proving, metamorphic hardware. The goal is to get closer to the machine, remove unnecessary layers of abstraction, and have absolute control over how the hardware behaves.

### The 4 Pillars of UMML:

1. **The Self-Proving Compiler:** Traditional hardware development relies on extensive simulation to find race conditions and deadlocks. UMML’s `compiler.awk` natively embeds Formal Mathematical Proof Encodings (SystemVerilog Assertions) into the routing bitstream. We do not just generate hardware and hope it works; the compiler mathematically proves the absence of deadlocks, timing hazards, and state conflicts at compile time.

2. **Metamorphic Spatial Obfuscation:** When discussing hardware security, we usually focus on internal processor behavior. UMML introduces metamorphic routing: the hardware dynamically XOR-scrambles its internal physical routing across the cell matrix mid-execution. An attacker trying to trace a fixed data path sees a different physical route every single cycle, rendering micro-probing and fixed-pattern EMI noise ineffective.

3. **Native Cross-Architecture Compilation:** Software compiled for one architecture does not automatically run on another. UMML’s Stage 3 Native Code Generation acts as a Universal Architectural Bridge. Lightweight POSIX mappers (`spatial_mapper.awk`, `spatial_mapper_x86.awk`) ingest standard RISC-V or x86-64 binaries, decode their underlying dataflow dependencies, and rebuild the logic into an optimized, conflict-free Spatial Dataflow Graph. Architecture lock-in is dead.

4. **The Spine (Zero-Clock Runtime):** Pure asynchronous systems are highly efficient, but initialization benefits from deterministic timing. UMML implements "The Spine": a hardware isolator that uses a global clock *only* for the initial deterministic setup. Once booted, the clock is physically gated off. The system runs purely on asynchronous handshake pressure, consuming zero global clock power during operation.

---

## Flagship Application: Creidyll Mobility

To validate the UMML architecture in a real-time, safety-critical physical environment, we are building the **Creidyll Tethered Hover Shoe**. 

Traditional personal flight projects fail due to battery weight and control latency. Creidyll solves both:
* **The Power Problem:** Solved via a high-tensile, high-voltage tether that offloads heavy batteries to the ground.
* **The Latency Problem:** Solved by the UMML Brainstem. Sensor spikes travel through the silicon fabric at the speed of electricity, bypassing OS interrupts and polling loops.

**The Endgame:** The tethered shoe is our foundational proof-of-concept for a much larger vision. By leveraging ultra-low-power asynchronous silicon and off-board power delivery, our target Bill of Materials (BOM) for the core wearable unit is under $60 at scale. We are building the future of affordable prosthetics, industrial exoskeletons, and next-generation consumer IoT.

---

## The Ultimate Proof: An Asynchronous Music Sequencer

Before we build flight controllers, we prove the concepts work. UMML includes a fully functional, clockless drum machine (`sequencer_no_assert.umml`) that brings these features together:

```text
# 1. Deterministic Initialization
spine the clock to step_kick for init

# 2. Memory Storage
make a memory named step_kick with size 16

# 3. Metamorphic Routing
make a metamorphic router named secure_bus_kick
morph the spike from step_kick through secure_bus_kick to kick_drum with key 8'hF0

# 4. Async Tempo Trigger
make a neuron named tempo_master with threshold 1 and leak 0
flow the spike from tempo_master into the read of step_kick
```

During playback, this design consumes zero global clock power. The computation proceeds through physical dataflow and asynchronous handshake pressure, backed by formal assertions proving the routing cannot deadlock. These are not separate ideas on paper; they are compiled, simulated, and synthesized into real silicon today.

---

## Zero-Bloat Toolchain

Creidyll rejects million-dollar EDA suites and bloated dependencies. Our toolchain is built for speed, transparency, and open-source purity, using native POSIX shell, AWK, and Icarus Verilog.

```bash
# 1. Compile plain English to Verilog
./umml_compile sequencer_no_assert.umml

# 2. Simulate the asynchronous dataflow
iverilog -g2012 -o sim creidyll_brainstem/rtl/*.sv sequencer_no_assert.v tb_sequencer.sv
vvp sim

# 3. Synthesize to physical FPGA silicon (Lattice iCE40)
./build_fpga.sh sequencer_no_assert.v
```

---

## 📂 Project Structure

- `compiler.awk` / `umml_compile_simple`: The core plain-English-to-Verilog spatial compilers.
- `spatial_mapper.awk` / `spatial_mapper_x86.awk`: Cross-architecture translators (RISC-V/x86 to UMML dataflow).
- `creidyll_brainstem/rtl/`: Synthesizable hardware primitives (`async_lif_neuron`, `async_metamorphic_router`, `async_clock_spine`, `async_memory_cell`).
- `build_fpga.sh`: Open-source FPGA synthesis pipeline (Yosys + nextpnr + IceStorm).
- `metamorphic_router_proof.sby`: SymbiYosys formal verification framework for mathematical deadlock proofs.
- `*.umml`: Plain-English hardware descriptions.

---

## Company Philosophy

Creidyll is fiercely independent. 

We believe that category-defining hardware is built by obsessed engineers focused on physics and user impact, not by committees pressured by quarterly returns. We fund our R&D through strategic non-dilutive grants, bug bounties, and customer contracts. We own our IP, we control our roadmap, and we build for the masses.

---

## ⚖️ Legal and Ethical Use

UMML is intended for educational, defensive, and academic research into hardware security, microarchitectural behaviour, and new approaches to computing. Only use it on hardware and systems you are authorized to study. If you discover a real hardware vulnerability, follow responsible disclosure practices.

---

## 📬 Contact & Inquiries

For technical discussions, grant partnerships, or serious engineering inquiries:

📧 **creidyll.innovations@gmail.com**

*Building the deterministic future of physical computing.*

---

## 📜 License

This project is licensed under the **Apache License 2.0**. This covers the hardware description files (`.sv`), scripts (`.sh`, `.awk`), and documentation. You are free to use, modify, and distribute the project under the terms of the license, provided you retain the original copyright and license notices.

See the [LICENSE](LICENSE) file for the full details.
