# MT25018 - Part C Analysis: Process vs Thread Comparison

## Overview
Comparison of fork-based (Program A) vs pthread-based (Program B) implementations with **2 workers** each, executing CPU, memory, and I/O intensive workloads on a single CPU core.

---

## Performance Results

### CPU-Intensive Workload
| Program | Type | CPU% | Memory (MB) | Execution Time (s) |
|---------|------|------|-------------|-------------------|
| A | Fork | 90.25 | 2.00 | 11.84 |
| B | Pthread | 90.48 | 2.23 | 11.87 |

**Analysis:**
- Nearly identical performance across all metrics
- Both fully utilize single CPU core (~90%)
- Threads have 11.5% more memory overhead (2.23 vs 2.00 MB)
- Execution time difference negligible (0.03s = 0.25%)
- **Conclusion**: For CPU-bound work with 2 workers, fork vs threads makes minimal difference

### Memory-Intensive Workload
| Program | Type | CPU% | Memory (MB) | Execution Time (s) |
|---------|------|------|-------------|-------------------|
| A | Fork | 90.58 | 4.50 | 8.78 |
| B | Pthread | 90.01 | 4.87 | 8.71 |

**Analysis:**
- Fork uses **8.2% less memory** (4.50 vs 4.87 MB) due to copy-on-write optimization
- Both show high CPU (~90%) due to array operations and sorting
- Execution time virtually identical (0.07s difference)
- Threads incur memory overhead from shared heap management
- **Conclusion**: Fork has slight memory advantage for memory-intensive tasks at small scale

### I/O-Intensive Workload
| Program | Type | CPU% | Memory (MB) | I/O (MB/s) | Execution Time (s) |
|---------|------|------|-------------|------------|-------------------|
| A | Fork | 5.65 | 5.75 | 7.59 | 2.43 |
| B | Pthread | 6.27 | 5.87 | 7.59 | 2.42 |

**Analysis:**
- Low CPU usage (5-6%) confirms **I/O-bound** nature - workers spend time waiting on disk
- Fork has **11% lower CPU** (5.65% vs 6.27%) - less context switching overhead
- Identical I/O throughput (7.59 MB/s) - disk speed is the bottleneck
- Similar memory footprint (~5.8 MB for I/O buffers)
- Execution time identical within measurement error
- **Conclusion**: Fork is more efficient for I/O workloads due to better process isolation

---

## Comparative Summary

### Fork (Program A) Advantages
| Metric | Value | Reason |
|--------|-------|--------|
| **I/O CPU Efficiency** | 11% lower (5.65% vs 6.27%) | Separate address spaces reduce context switch overhead |
| **Memory for Memory-bound** | 8% lower (4.50 vs 4.87 MB) | Copy-on-write sharing of read-only data |
| **Process Isolation** | Strong | Crash in one worker doesn't affect others |

### Pthread (Program B) Advantages
| Metric | Value | Reason |
|--------|-------|--------|
| **Shared Memory** | Native | Direct access without IPC mechanisms |
| **Creation Speed** | Faster | No need to duplicate process memory |
| **Communication** | Simpler | Shared variables instead of pipes/sockets |

### Performance Parity
- **CPU Utilization**: Both achieve ~90% on single core
- **Execution Time**: Difference < 1% across all workloads
- **I/O Throughput**: Identical 7.59 MB/s (disk-limited)

---

## Key Insights

### 1. Single-Core Environment Impact
With `taskset -c 0` pinning to one CPU core:
- Both approaches serialize worker execution
- CPU-bound tasks show no parallelism benefit
- I/O-bound tasks can overlap (wait time allows switching)

### 2. Workload Characteristics
| Workload | CPU% | Bottleneck | Winner |
|----------|------|------------|--------|
| CPU | ~90% | Computation | Tie |
| Memory | ~90% | Array operations | Fork (8% less memory) |
| I/O | 5-6% | Disk speed | Fork (11% less CPU) |

### 3. Memory Usage Pattern
- **CPU**: 2.0-2.2 MB (minimal - just stack and small variables)
- **Memory**: 4.5-4.9 MB (512KB arrays × 2 workers + overhead)
- **I/O**: 5.8-5.9 MB (1MB read + 1MB write buffers per worker)

### 4. Context Switching Overhead
- **Fork**: Lower overhead for I/O due to separate address spaces
- **Threads**: Higher overhead (11% more CPU) due to shared memory coherency

---

## Recommendations

### Use Fork When:
1. **Strong isolation required** - Worker crashes shouldn't affect others
2. **I/O-intensive workload** - Lower CPU overhead (11% savings)
3. **Memory access patterns known** - Can leverage copy-on-write
4. **Legacy code integration** - Each worker needs independent state

### Use Threads When:
1. **Frequent communication needed** - Shared memory is faster than IPC
2. **Dynamic data sharing** - Multiple workers modify same data structures
3. **Resource constrained** - Lower creation overhead
4. **Rapid worker creation/destruction** - Thread pools more efficient

### For This Assignment (2 workers, single core):
- **Performance**: No significant difference
- **Memory**: Fork slightly better (4-8% savings)
- **CPU Efficiency**: Fork better for I/O (11% savings)
- **Simplicity**: Threads easier to implement for shared state

---

## Technical Configuration

**System Setup:**
- Environment: WSL Ubuntu on Windows
- CPU Pinning: Core 0 (`taskset -c 0`)
- Roll Number: MT25018
- LOOP_COUNT: 80,000

**Worker Implementation:**
- CPU: 10-15s execution, 7 computational layers, 95%+ utilization
- Memory: 3-4s execution, 512KB arrays, sorting and memcpy operations
- I/O: 3-5s execution, 50MB per worker, 1MB buffers, fsync() calls

**Monitoring Tools:**
- CPU/Memory: `top -b -n 1` command (batch mode) with 0.5s sampling interval
- I/O Throughput: `iostat -d -x -m` with 1s interval (skip first 2 baseline samples)
- CPU Pinning: `taskset -c 0` for single-core execution
- Execution Time: `date +%s.%N` for nanosecond precision

---

## Conclusion

For **2 workers on a single CPU core**, fork and pthread implementations show **near-identical performance**:
- CPU-bound: Tie (both ~90% CPU, ~12s execution)
- Memory-bound: Fork wins by 8% memory (4.50 vs 4.87 MB)
- I/O-bound: Fork wins by 11% CPU (5.65% vs 6.27%)

The choice between fork and threads at this scale is driven by **design requirements** (isolation vs shared memory) rather than raw performance differences.
