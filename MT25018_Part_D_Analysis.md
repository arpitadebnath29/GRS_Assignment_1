# MT25018 - Part D Analysis: Scalability with Variable Workers

## Overview
Analysis of how fork-based (Program A) and pthread-based (Program B) implementations scale with increasing worker counts:
- **Program A (Fork)**: 2, 3, 4, 5 processes
- **Program B (Pthread)**: 2, 3, 4, 5, 6, 7, 8 threads

All tests run on single CPU core (`taskset -c 0`) to measure serialization effects.

---

## CPU-Intensive Workload Scalability

### Program A (Fork) - 2 to 5 Processes

| Workers | CPU% | Memory (MB) | Execution Time (s) | Memory/Worker | Time/Worker |
|---------|------|-------------|-------------------|---------------|-------------|
| 2 | 90.30 | 3.75 | 9.01 | 1.88 | 4.51 |
| 3 | 90.39 | 4.75 | 17.67 | 1.58 | 5.89 |
| 4 | 90.00 | 5.75 | 20.62 | 1.44 | 5.16 |
| 5 | 89.57 | 6.71 | 26.46 | 1.34 | 5.29 |

**Key Findings:**
- **Memory Growth**: Linear at ~0.95 MB/process (predictable scaling)
- **CPU Utilization**: Constant ~90% (single core fully utilized)
- **Execution Time**: Increases 2.9x from 2→5 workers (serialization penalty)
- **Memory Efficiency**: Decreases with scale (overhead per worker drops)

### Program B (Pthread) - 2 to 8 Threads

| Workers | CPU% | Memory (MB) | Execution Time (s) | Memory/Worker | Time/Worker |
|---------|------|-------------|-------------------|---------------|-------------|
| 2 | 90.29 | 2.12 | 11.78 | 1.06 | 5.89 |
| 3 | 90.47 | 2.12 | 14.85 | 0.71 | 4.95 |
| 4 | 90.59 | 2.12 | 20.58 | 0.53 | 5.15 |
| 5 | 90.66 | 2.12 | 30.32 | 0.42 | 6.06 |
| 6 | 92.05 | 2.12 | 28.87 | 0.35 | 4.81 |
| 7 | 90.55 | 2.23 | 38.01 | 0.32 | 5.43 |
| 8 | 90.66 | 2.12 | 40.93 | 0.27 | 5.12 |

**Key Findings:**
- **Memory Growth**: **CONSTANT at 2.12 MB** (threads share address space!)
- **CPU Utilization**: Constant ~90% (one thread runs, others wait)
- **Execution Time**: Scales linearly (~5s per thread)
- **Memory Efficiency**: **77% better than fork** at 8 workers (2.12 vs 9.24 MB*)

*Projected fork memory at 8 workers based on linear growth

### CPU Workload Comparison

| Metric | Fork (5 workers) | Threads (8 workers) | Winner |
|--------|------------------|---------------------|--------|
| Memory | 6.71 MB (1.34/worker) | 2.12 MB (0.27/worker) | **Threads (68% less)** |
| CPU% | 89.57% | 90.66% | Tie |
| Time/Worker | 5.29s | 5.12s | Threads (3% faster) |
| Scalability | Linear growth | Flat memory | **Threads** |

---

## Memory-Intensive Workload Scalability

### Program A (Fork) - 2 to 5 Processes

| Workers | CPU% | Memory (MB) | Execution Time (s) | Memory/Worker | Time/Worker |
|---------|------|-------------|-------------------|---------------|-------------|
| 2 | 90.32 | 6.25 | 8.57 | 3.13 | 4.29 |
| 3 | 88.27 | 8.35 | 17.43 | 2.78 | 5.81 |
| 4 | 90.10 | 10.75 | 20.22 | 2.69 | 5.06 |
| 5 | 90.11 | 13.00 | 25.97 | 2.60 | 5.19 |

**Key Findings:**
- **Memory Growth**: ~1.65 MB/process (higher than CPU due to 512KB arrays)
- **CPU Utilization**: High ~90% despite memory workload (array operations are CPU-intensive)
- **Execution Time**: 3x increase from 2→5 workers
- **Copy-on-Write**: Less effective here (arrays are modified, triggering copies)

### Program B (Pthread) - 2 to 8 Threads

| Workers | CPU% | Memory (MB) | Execution Time (s) | Memory/Worker | Time/Worker |
|---------|------|-------------|-------------------|---------------|-------------|
| 2 | 90.13 | 4.87 | 11.71 | 2.44 | 5.86 |
| 3 | 90.39 | 6.37 | 14.46 | 2.12 | 4.82 |
| 4 | 90.46 | 7.87 | 23.14 | 1.97 | 5.79 |
| 5 | 90.56 | 9.35 | 29.17 | 1.87 | 5.83 |
| 6 | 90.70 | 11.00 | 31.97 | 1.83 | 5.33 |
| 7 | 90.57 | 12.46 | 37.97 | 1.78 | 5.42 |
| 8 | 90.65 | 13.89 | 41.00 | 1.74 | 5.13 |

**Key Findings:**
- **Memory Growth**: ~1.50 MB/thread (10% more efficient than fork)
- **CPU Utilization**: Constant ~90% (memory operations are compute-heavy)
- **Execution Time**: Linear scaling (~5s per thread)
- **Shared Heap**: Threads avoid per-worker array duplication

### Memory Workload Comparison

| Metric | Fork (5 workers) | Threads (8 workers) | Winner |
|--------|------------------|---------------------|--------|
| Memory | 13.00 MB (2.60/worker) | 13.89 MB (1.74/worker) | **Tie** |
| Memory Efficiency | 2.60 MB/worker | 1.74 MB/worker | **Threads (33% better)** |
| CPU% | 90.11% | 90.65% | Tie |
| Time/Worker | 5.19s | 5.13s | Tie |

---

## I/O-Intensive Workload Scalability

### Program A (Fork) - 2 to 5 Processes

| Workers | CPU% | Memory (MB) | I/O (MB/s) | Execution Time (s) | CPU/Worker |
|---------|------|-------------|------------|-------------------|------------|
| 2 | 6.67 | 7.50 | 7.59 | 2.38 | 3.34% |
| 3 | 8.45 | 10.37 | 7.59 | -0.54* | 2.82% |
| 4 | 10.27 | 13.25 | 7.59 | 2.42 | 2.57% |
| 5 | 9.60 | 16.12 | 7.59 | 2.46 | 1.92% |

*Negative time is measurement artifact (program finished before monitoring started)

**Key Findings:**
- **CPU Growth**: Modest increase (6.67% → 9.60%) with workers
- **Memory Growth**: ~2.15 MB/process (1MB buffers + overhead)
- **I/O Throughput**: **Constant at 7.59 MB/s** (disk bottleneck)
- **Low CPU**: Confirms I/O-bound nature (workers wait on disk)

### Program B (Pthread) - 2 to 8 Threads

| Workers | CPU% | Memory (MB) | I/O (MB/s) | Execution Time (s) | CPU/Worker |
|---------|------|-------------|------------|-------------------|------------|
| 2 | 6.70 | 5.87 | 7.59 | 2.37 | 3.35% |
| 3 | 9.92 | 7.87 | 7.59 | 2.37 | 3.31% |
| 4 | 12.70 | 9.87 | 7.59 | 2.47 | 3.18% |
| 5 | 13.55 | 11.87 | 7.59 | 2.44 | 2.71% |
| 6 | 18.25 | 13.87 | 7.59 | 2.50 | 3.04% |
| 7 | 21.25 | 16.00 | 8.39 | 2.61 | 3.04% |
| 8 | 19.32 | 18.00 | 7.59 | 2.57 | 2.42% |

**Key Findings:**
- **CPU Growth**: Dramatic increase (6.70% → 21.25%) - **3.2x higher than fork!**
- **Memory Growth**: ~2.00 MB/thread (similar to fork)
- **I/O Throughput**: Constant 7.59 MB/s (disk saturated)
- **Context Switching**: High thread count causes CPU overhead

### I/O Workload Comparison

| Metric | Fork (5 workers) | Threads (8 workers) | Winner |
|--------|------------------|---------------------|--------|
| CPU% | 9.60% | 19.32% | **Fork (50% less)** |
| Memory | 16.12 MB (3.22/worker) | 18.00 MB (2.25/worker) | **Threads** |
| I/O Throughput | 7.59 MB/s | 7.59 MB/s | Tie |
| Execution Time | 2.46s | 2.57s | Fork (4% faster) |
| CPU Efficiency | **Winner** | Loser | **Fork** |

---

## Cross-Workload Scaling Patterns

### Memory Scaling Efficiency

| Workload | Fork Growth Rate | Thread Growth Rate | Thread Advantage |
|----------|------------------|-------------------|------------------|
| CPU | 0.95 MB/worker | 0 MB/worker (constant 2.12 MB) | **Infinite** |
| Memory | 1.65 MB/worker | 1.50 MB/worker | 9% |
| I/O | 2.15 MB/worker | 2.00 MB/worker | 7% |

**Insight**: Threads dominate for CPU-bound (constant memory), maintain advantage for memory/I/O tasks.

### CPU Overhead by Workload

| Workload | Fork CPU at Max | Thread CPU at Max | Difference |
|----------|-----------------|-------------------|------------|
| CPU | 89.57% (5 workers) | 90.66% (8 workers) | +1% (negligible) |
| Memory | 90.11% (5 workers) | 90.65% (8 workers) | +0.5% (negligible) |
| I/O | 9.60% (5 workers) | 19.32% (8 workers) | **+101% (2x higher!)** |

**Insight**: Threads have severe CPU overhead for I/O workloads due to context switching.

### Execution Time Scalability

| Workload | Fork Time/Worker | Thread Time/Worker | Winner |
|----------|------------------|-------------------|--------|
| CPU | 5.29s | 5.12s | Threads (3% faster) |
| Memory | 5.19s | 5.13s | Threads (1% faster) |
| I/O | 0.49s | 0.32s | **Threads (35% faster)** |

**Insight**: I/O tasks complete faster per-worker with threads despite higher CPU overhead.

---

## Single-Core Serialization Analysis

### Why Execution Time Grows Linearly

With one CPU core, workers **cannot run in parallel**:
1. Worker 1 runs for ~5 seconds
2. Worker 2 runs for ~5 seconds
3. Worker N runs for ~5 seconds
4. **Total time** = N × 5 seconds

**Evidence from data:**
- CPU-bound: 2 workers = 11.78s, 8 workers = 40.93s (~5s per worker)
- Memory-bound: 2 workers = 11.71s, 8 workers = 41.00s (~5s per worker)

### I/O Exception

I/O tasks can overlap because workers spend time **waiting**:
- Execution time stays ~2.4s regardless of worker count
- While one worker waits on disk, another can use CPU
- This is why I/O time doesn't scale linearly

---

## Key Recommendations

### Use Fork When:
1. **I/O-intensive workload** → 50% lower CPU overhead
2. **Isolation critical** → Separate address spaces prevent crash propagation
3. **Worker count ≤ 5** → Memory overhead acceptable
4. **Legacy integration** → Each worker needs independent state

### Use Threads When:
1. **CPU-intensive workload** → Constant memory (68% savings at 8 workers)
2. **Memory-intensive workload** → 33% less memory per worker
3. **High worker count** → Memory scaling is superior
4. **Shared data structures** → Native shared memory access

### Production Deployment:
- **CPU-bound**: Threads with thread pool (memory-efficient)
- **Memory-bound**: Threads for better sharing (avoid duplication)
- **I/O-bound**: Processes with async I/O (lower CPU, better isolation)
- **Mixed workload**: Hybrid (process pool with thread pool per process)

---

## Critical Insights

### 1. Memory Scalability Winner: **Threads**
- CPU workload: **Constant 2.12 MB** vs fork's linear growth
- At 8 workers: Threads use **77% less memory** than fork
- Shared address space eliminates per-worker overhead

### 2. CPU Efficiency Winner (I/O): **Fork**
- Fork: 9.60% CPU at 5 workers
- Threads: 19.32% CPU at 8 workers
- Context switching penalty severe for I/O workloads

### 3. Single-Core Bottleneck
- No true parallelism achieved
- Workers serialize, causing linear time growth
- I/O workloads less affected (can overlap during waits)

### 4. Optimal Worker Count
- **CPU/Memory**: Limited by single core (2-4 optimal)
- **I/O**: Can support more (5-8) due to wait time overlap
- **Multi-core**: Would show true parallel benefits

---

## Conclusion

**For scalability on a single CPU core:**

| Scenario | Winner | Reason |
|----------|--------|--------|
| **CPU-intensive, many workers** | **Threads** | Constant memory (68% savings) |
| **Memory-intensive, many workers** | **Threads** | 33% less memory per worker |
| **I/O-intensive, any count** | **Fork** | 50% lower CPU overhead |
| **Small scale (2-3 workers)** | **Tie** | Differences minimal |

The choice depends on:
1. **Workload type** (compute vs I/O)
2. **Worker count** (threads scale better)
3. **System requirements** (isolation vs shared memory)

For multi-core systems, threads would show even greater advantages due to lower creation/switching costs and true parallelism.

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
- CPU/Memory: `top -b -n 1` command (batch mode, single iteration) with 0.5s sampling interval
- I/O Throughput: `iostat -d -x -m` with 1s interval
- Execution Time: `date +%s.%N` for nanosecond precision
