/*
 * MT25018
 * Part B: Worker Functions Header
 * This file contains declarations for CPU, Memory, and IO intensive worker functions
 */

#ifndef WORKERS_H
#define WORKERS_H

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <math.h>

#define LOOP_COUNT 80000  // Increased from 8000 to run for ~5 seconds

/*
 * CPU-intensive function
 * Performs complex mathematical calculations
 * Calculates approximation of pi, prime numbers, and factorials
 */
void cpu_intensive_work(int id);

/*
 * Memory-intensive function
 * Allocates large arrays and performs memory operations
 * Sorts and processes large amounts of data in memory
 */
void mem_intensive_work(int id);

/*
 * I/O-intensive function
 * Performs file read/write operations
 * Creates, writes, reads, and deletes temporary files
 */
void io_intensive_work(int id);

#endif // WORKERS_H
