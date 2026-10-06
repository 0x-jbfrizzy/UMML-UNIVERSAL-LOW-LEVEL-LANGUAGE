import sys
import os
import subprocess
import shutil

# Import the assembler logic we built earlier
# (Make sure copper_asm.py is in the same directory)
try:
    from copper_asm import assemble
except ImportError:
    print("Error: copper_asm.py not found in the current directory.")
    sys.exit(1)

def check_iverilog():
    """Check if Icarus Verilog is installed."""
    if shutil.which("iverilog") is None:
        print("ERROR: Icarus Verilog (iverilog) is not installed or not in PATH.")
        print("\nTo install it:")
        print("  Ubuntu/Debian: sudo apt-get install iverilog")
        print("  macOS:         brew install icarus-verilog")
        print("  Windows:       Download from http://bleyer.org/icarus/")
        sys.exit(1)

def run_pipeline(cop_file):
    if not os.path.exists(cop_file):
        print(f"Error: File '{cop_file}' not found.")
        sys.exit(1)

    print(f"[*] Assembling {cop_file}...")
    hex_file = "program.hex"
    
    # 1. Assemble
    try:
        assemble(cop_file, hex_file)
    except Exception as e:
        print(f"Assembly failed: {e}")
        sys.exit(1)

    print(f"[*] Compilation successful. Output: {hex_file}")
    print(f"[*] Checking for Icarus Verilog...")
    
    # 2. Check for Verilog compiler
    check_iverilog()

    design_file = "design.sv"
    tb_file = "testbench.sv"
    sim_output = "umml_sim"

    if not os.path.exists(design_file) or not os.path.exists(tb_file):
        print("Error: design.sv and testbench.sv must be in the current directory.")
        sys.exit(1)

    # 3. Compile Verilog
    print(f"[*] Compiling hardware model ({design_file} + {tb_file})...")
    compile_cmd = ["iverilog", "-g2012", "-o", sim_output, design_file, tb_file]
    
    try:
        subprocess.run(compile_cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print("Verilog compilation failed!")
        print(e.stderr.decode('utf-8'))
        sys.exit(1)

    # 4. Run Simulation
    print(f"[*] Running silicon simulation...\n")
    run_cmd = ["vvp", sim_output]
    
    try:
        subprocess.run(run_cmd, check=True)
    except subprocess.CalledProcessError as e:
        print("Simulation failed.")
        sys.exit(1)

    # 5. Cleanup
    if os.path.exists(sim_output):
        os.remove(sim_output)
    if os.path.exists(hex_file):
        os.remove(hex_file)
        
    print("\n[*] Simulation finished. Temporary files cleaned.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 umml.py <script.cop>")
        print("Example: python3 umml.py chained_hunt.cop")
    else:
        run_pipeline(sys.argv[1])