# UMML-UNIVERSAL-LOW-LEVEL-LANGUAGE
Talking directly to the CPU no Abstractions
_________________________________________



UMML (Universal Microarchitectural Modeling Language)
Most hardware security simulators abstract away the physics. They give you a boolean  cache_miss = true  or a simulated  bit_flip . They hide the actual microarchitectural behavior that makes zero-days possible in the first place.
If you want to find the next generation of hardware vulnerabilities, you can't rely on abstractions. You have to model the physics.
UMML is a zero-abstraction hardware description and assembly language built to model the physical reality of modern SoCs. It runs on a custom 16-bit ISA. No OS abstractions. No compiler optimizations hiding the truth.
If it happens in silicon, you can model it here.
The Core Principles
UMML is built on three rules of silicon:
1.
The Propagation Law: No state change is instantaneous. Every instruction has a physical latency defined by the module it targets.
2.
The State Decoupling Law: Architectural state (registers) and microarchitectural state (cache, branch predictors, NoC buffers) are strictly separated. A rollback only affects the former.
3.
The Contention Law: Resources are finite. Backpressure is real, and it leaks timing information.
Microarchitectural Domains
UMML isn't just a CPU simulator. It’s a multi-domain physics engine for hardware security research:
Cache Coherence: Model MOESI state transitions, Request For Ownership (RFO) latency, and directory protocol manipulation.
Network-on-Chip (NoC): Model virtual channel allocation, crossbar arbitration, and backpressure-induced timing leaks.
DRAM Analog Physics: Track actual capacitor charge levels (0-100%). Model temperature-dependent leakage, refresh bypass, and Aggressor/Victim electromagnetic disturbance.
Speculative Execution: Model Branch Target Buffers (BTB), forced mispredictions, and the exact state decoupling that makes transient execution leaks possible.
Power & Thermal: Track dynamic power draw and thermal throttling thresholds to model heat-based side-channels.
Multi-Domain Chaining: Chain NoC backpressure with speculative gadgets to actively widen execution windows and amplify timing deltas.
Quick Start
UMML is designed to be a seamless, one-command toolchain.
Prerequisites
You need Python 3 and Icarus Verilog installed on your system.
Ubuntu/Debian:  sudo apt-get install iverilog 
macOS:  brew install icarus-verilog 
Windows: Download the installer from bleyer.org/icarus
Running a Script
You don't need to manually compile or paste hex codes. Just point the runner at your  .cop  file:

python3 umml.py chained_hunt.cop
The script will automatically:
1.
Assemble the  .cop  file into 16-bit machine code.
2.
Compile the Verilog hardware model.
3.
Execute the simulation and print the microarchitectural state.
Example: The Chained Side-Channel
This script actively manipulates the NoC to make a standard cache timing leak more reliable by amplifying the timing delta.


ASSEMBLY
; chained_hunt.cop

; 1. Setup: R0 = 16 (Target address), R2 = 1 (Index)
MOV R0, R1
ADD R0, R0
ADD R0, R0
ADD R0, R0
ADD R0, R0
MOV R2, R1

; 2. PHASE 1: NoC Backpressure
; Block Virtual Channel 2 to induce pipeline stalls and widen timing windows.
VC_BLOCK 2          

; 3. PHASE 2: Speculative Execution Gadget
SAVE_REG            
FORCE_MISPRED       
LOAD R3, R0         ; Transient load poisons the cache line
ROLLBACK            ; Architectural state reverts; microarchitectural state remains

; 4. PHASE 3: Coherence Latency Measurement
; Measure the time to access the address. The NoC backpressure amplifies
; the standard RFO/cache miss penalty, making the side-channel signal clearer.
READ_CYCLES R4      
LOAD R5, R0         ; Triggers cache coherence traffic + NoC stall
READ_CYCLES R6      
SUB R6, R4          ; Calculate the amplified timing delta

HALT

The Result:
Instead of a noisy, fragile 15-cycle cache miss penalty, the NoC backpressure actively stalls the pipeline during the RFO, resulting in a clean, highly detectable 41-cycle latency delta. The software sees a clean rollback ( R3 = 0 ), but the silicon remembers.
Project Structure
 copper_asm.py : The custom 16-bit assembler. Parses  .cop  files and outputs Verilog-compatible hex.
 umml.py : The master runner script. Handles assembly, Verilog compilation, and simulation execution in one command.
 design.sv : The synthesizable Verilog core. Contains the physical models for registers, caches, NoC routers, and DRAM arrays.
 testbench.sv : The simulation harness. Loads the hex output and prints the microarchitectural state at the end of execution.
 .cop : Example research scripts demonstrating specific vulnerability classes.
Why This Matters
Patching Spectre doesn't fix NoC backpressure. Fixing NoC arbitration doesn't stop DRAM charge leakage. The next generation of hardware vulnerabilities won't live in a single domain; they will live in the intersections between them.
UMML gives researchers the sandbox to find those intersections.
Contributing
This is an active, evolving project. If you want to add support for new instructions, refine the DRAM leakage formulas, or model a different cache coherence protocol, open a PR.
Built for researchers, by researchers

Legal & Ethical Disclaimer
This project is developed and provided strictly for educational, defensive, and academic research purposes. The microarchitectural models and side-channel techniques demonstrated here are intended to help the security community understand, detect, and mitigate hardware vulnerabilities before they can be exploited in the wild.
The author(s) assume no liability for any misuse of this software or the concepts contained within. Any attempt to use UMML or its underlying principles to compromise systems, extract unauthorized data, or cause harm without explicit, documented authorization is strictly prohibited and may violate local and international computer fraud laws.
Always conduct hardware security research within the bounds of responsible disclosure and strictly authorized environments.
