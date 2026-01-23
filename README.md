# MT25018 - Processes vs Threads Performance Analysis

**GitHub**: https://github.com/arpitadebnath29/GRS_Assignment_1  
**Roll**: MT25018 | **Course**: CSE638 Graduate Systems | **Date**: Jan 2026

## Overview
Performance comparison of **fork-based processes** vs **pthread-based threads** across CPU, memory, and I/O workloads with scalability analysis (2-8 workers).

**Environment**: WSL Ubuntu, single-core (`taskset -c 0`), LOOP_COUNT = 80,000

---

## Quick Start

```bash
# Build & Run
make clean && make                # Clean previous build, then compile programs
./MT25018_Part_C_shell.sh         # Part C: 2 workers, 6 tests
./MT25018_Part_D_shell.sh         # Part D: Scalability (33 tests)
python3 MT25018_Part_D_plot.py    # Generate 9 individual plot visualizations

# Manual Execution
./MT25018_Part_A_Program_A cpu 2  # Fork: 2 processes, CPU workload
./MT25018_Part_A_Program_B mem 4  # Thread: 4 threads, memory workload
```

---

## Project Structure

```
├── MT25018_Part_A_Program_A.c        # Fork-based implementation
├── MT25018_Part_A_Program_B.c        # Pthread-based implementation
├── MT25018_Part_B_workers.{c,h}      # CPU/Memory/I/O worker functions
├── MT25018_Part_C_shell.sh           # Automated testing (6 tests)
├── MT25018_Part_D_shell.sh           # Scalability testing (33 tests)
├── MT25018_Part_D_plot.py            # Visualization script
├── MT25018_Part_{C,D}_CSV.csv        # Results data
├── MT25018_Part_{C,D}_Analysis.md    # Detailed reports
└── Makefile                          # Build automation
```

---

## Worker Functions

| Function | Duration | Behavior | CPU | Memory |
|----------|----------|----------|-----|---------|
| **CPU** | 10-15s | Math ops, primes, factorials | 95-100% | ~2MB |
| **Memory** | 3-4s | 512KB arrays, sorting, memcpy | ~90% | ~3MB |
| **I/O** | 3-5s | 1MB buffer writes, fsync | 5-20% | Low |

---

## Key Results

### Part C: 2 Workers Comparison
| Workload | Winner | Advantage |
|----------|--------|-----------|
| CPU | **Tie** | Both ~90% CPU, ~12s |
| Memory | **Fork** | 8% less memory (copy-on-write) |
| I/O | **Fork** | 11% lower CPU overhead |

### Part D: Scalability (2-8 Workers)
| Workload | Winner | Key Metric |
|----------|--------|------------|
| CPU | **Threads** | Constant 2.12MB memory |
| Memory | **Threads** | 33% less memory/worker |
| I/O | **Fork** | 50% lower CPU overhead |

**Conclusion**: Threads excel for CPU/memory workloads (68% memory savings @ 8 workers). Fork better for I/O (lower overhead).

---

## System Requirements

**Platform**: Linux/Unix required. **Windows users must use WSL (Windows Subsystem for Linux).**

```bash
# Install dependencies
sudo apt update
sudo apt install -y build-essential sysstat python3 python3-pip
pip3 install pandas matplotlib
```

**Tools**: GCC, pthread, `top`, `iostat`, `taskset`, Python 3

---

## Implementation

### Programs
- **Program A**: `fork()` creates child processes, `wait()` synchronization
- **Program B**: `pthread_create()` spawns threads, `pthread_join()` synchronization

### Worker Details
- **CPU**: Trigonometry, primes, factorials, matrix ops (7 layers), LOOP_COUNT=80,000
- **Memory**: Large array operations, random access, cache stress
- **I/O**: File creation, 1MB buffer writes with memset, fsync, cleanup in `/tmp/`

### Measurement Scripts
- **Part C**: Tests 6 combinations (A/B × cpu/mem/io) with 2 workers
- **Part D**: Variable workers (fork: 2-5, threads: 2-8), generates 9 individual plot files
- **Metrics**: CPU%, Memory (MB), I/O via `top -b -n 1` (0.5s sampling), `iostat`
- **Outputs**: MT25018_Part_D_CSV.csv, plot1-9_*.png visualization files


---

## Troubleshooting

```bash
# Missing tools
sudo apt install util-linux sysstat bc

# Script permissions
chmod +x MT25018_Part_C_shell.sh MT25018_Part_D_shell.sh

# Python dependencies
pip3 install matplotlib pandas

# Clean build
make clean && make
```
---

**Author**: Arpita Debnath | MT25018

**End of README**
