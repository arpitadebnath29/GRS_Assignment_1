/*
 * MT25018
 * Part B: Worker Functions Implementation
 * Implements CPU, Memory, and IO intensive worker functions
 */

#include "MT25018_Part_B_workers.h"

/*
 * CPU-intensive function
 * Performs extremely complex mathematical calculations in nested loops
 * Uses floating point operations, trigonometric functions, prime checking, and matrix operations
 * Designed to maximize CPU usage and run for 10-15 seconds
 */
void cpu_intensive_work(int id) {
    (void)id; // Suppress unused parameter warning
    double result = 0.0;
    unsigned long long factorial = 1;
    
    // EXTREMELY intensive CPU work - multiple nested loops with heavy math
    for (int i = 0; i < LOOP_COUNT; i++) {
        
        // Layer 1: Complex trigonometric and logarithmic operations (500 iterations)
        for (int j = 0; j < 500; j++) {
            double angle = (i * j) * 0.001;
            result += sin(angle) * cos(angle * 2.0);
            result += tan(angle * 0.5) / (1.0 + angle);
            result += atan2(sin(angle), cos(angle));
            result += sinh(angle * 0.1) + cosh(angle * 0.1);
            result += log(i + j + 2.0) * log10(i + j + 3.0);
            result += sqrt((i + 1.0) * (j + 1.0)) + cbrt((i + 2.0) * (j + 2.0));
            result += pow(fabs(sin(angle)), 1.5) + pow(fabs(cos(angle)), 2.5);
            result += exp(angle * 0.001) + expm1(angle * 0.0001);
        }
        
        // Layer 2: Prime number checking with larger search space
        for (int base = 0; base < 10; base++) {
            int num = i * 10 + base + 10000;
            int is_prime = 1;
            for (int j = 2; j * j <= num; j++) {
                if (num % j == 0) {
                    is_prime = 0;
                    break;
                }
            }
            if (is_prime) {
                result += num * 0.00001;
                // Additional work for prime numbers
                for (int k = 0; k < 50; k++) {
                    result += sqrt(num + k) * 0.0001;
                }
            }
        }
        
        // Layer 3: Factorial and combinatorial calculations
        if (i % 50 == 0) {
            factorial = 1;
            for (int k = 1; k <= 20; k++) {
                factorial *= k;
                result += log((double)factorial) * 0.000001;
            }
            
            // Compute combinations C(n,k)
            for (int n = 20; n <= 25; n++) {
                for (int k = 1; k < n; k++) {
                    double combination = 1.0;
                    for (int j = 0; j < k; j++) {
                        combination *= (n - j) / (double)(j + 1);
                    }
                    result += combination * 0.0000001;
                }
            }
        }
        
        // Layer 4: Matrix-like computations (simulate small matrix operations)
        double matrix_sum = 0.0;
        for (int row = 0; row < 20; row++) {
            for (int col = 0; col < 20; col++) {
                double val = sin(row * 0.1) * cos(col * 0.1);
                matrix_sum += val * val;
                matrix_sum += sqrt(fabs(val));
            }
        }
        result += matrix_sum * 0.00001;
        
        // Layer 5: Polynomial evaluation (high degree)
        double x = i * 0.01;
        double poly = 0.0;
        for (int deg = 0; deg < 50; deg++) {
            poly += pow(x, deg) / (deg + 1);
        }
        result += poly * 0.000001;
        
        // Layer 6: Iterative convergence calculation (approximating pi)
        double pi_approx = 0.0;
        for (int k = 0; k < 1000; k++) {
            pi_approx += (k % 2 == 0 ? 1.0 : -1.0) / (2.0 * k + 1.0);
        }
        result += pi_approx * 4.0 * 0.0001;
        
        // Layer 7: More power and exponential calculations
        result += pow(i * 0.001 + 1.0, 3.7);
        result += pow(i * 0.002 + 1.0, 2.3);
        result += exp(sin(i * 0.0001));
        result += log1p(i * 0.01);
    }
    
    // Prevent compiler optimization by using the result
    if (result > 0) {
        volatile double temp = result;
        (void)temp;
    }
}

/*
 * Memory-intensive function
 * Allocates large arrays and performs memory-intensive operations
 * Includes sorting, copying, and random access patterns
 */
void mem_intensive_work(int id) {
    (void)id; // Suppress unused parameter warning
    // Reduced memory allocation to speed up
    size_t array_size = 128 * 1024; // 128KB instead of 1MB
    int *array1 = (int *)malloc(array_size * sizeof(int));
    int *array2 = (int *)malloc(array_size * sizeof(int));
    int *array3 = (int *)malloc(array_size * sizeof(int));
    
    if (!array1 || !array2 || !array3) {
        fprintf(stderr, "Memory allocation failed\n");
        free(array1);
        free(array2);
        free(array3);
        return;
    }
    
    // Reduced loop count for faster execution
    int reduced_loops = LOOP_COUNT / 10;
    
    for (int i = 0; i < reduced_loops; i++) {
        // Initialize arrays with random-like data
        for (size_t j = 0; j < array_size; j++) {
            array1[j] = (i * j) % 10000;
        }
        
        // Memory copy operations (memory intensive)
        memcpy(array2, array1, array_size * sizeof(int));
        memcpy(array3, array2, array_size * sizeof(int));
        
        // Random access pattern (cache misses)
        long long sum = 0;
        for (size_t j = 0; j < array_size; j += 64) {
            size_t index = (j * 7919) % array_size;
            sum += array1[index];
            array2[index] = sum % 10000;
        }
        
        // Bubble sort on a portion - reduced size
        size_t sort_size = 500;
        for (size_t j = 0; j < sort_size - 1; j++) {
            for (size_t k = 0; k < sort_size - j - 1; k++) {
                if (array3[k] > array3[k + 1]) {
                    int temp = array3[k];
                    array3[k] = array3[k + 1];
                    array3[k + 1] = temp;
                }
            }
        }
        
        // Sequential memory access
        for (size_t j = 0; j < array_size; j++) {
            array1[j] = array2[j] + array3[j % sort_size];
        }
    }
    
    // Cleanup
    free(array1);
    free(array2);
    free(array3);
}

/*
 * I/O-intensive function
 * Performs intensive file read/write operations with large buffers
 * Creates temporary files, writes data, reads back, and deletes
 * Optimized for 10+ MB/s throughput with minimal CPU usage
 * Target: 3-5 seconds execution, 20 MB total data per worker
 */
void io_intensive_work(int id) {
    char filename[256];
    
    // Use 1MB buffer for good throughput and low memory footprint
    const size_t buffer_size = 1 * 1024 * 1024; // 1MB buffer
    char *buffer = (char *)malloc(buffer_size);
    char *read_buffer = (char *)malloc(buffer_size);
    
    if (!buffer || !read_buffer) {
        fprintf(stderr, "Failed to allocate I/O buffers\n");
        free(buffer);
        free(read_buffer);
        return;
    }
    
    // Prepare data to write - fill with simple pattern (minimal CPU)
    memset(buffer, 'A', buffer_size);
    
    // Target: Write/Read 50MB total over 3-5 seconds (for proper monitoring)
    // Each iteration: 5MB (5 blocks of 1MB) + 200ms delay
    // Total: 10 iterations × 5MB = 50MB per worker
    // Execution time: ~3-4 seconds with delays to keep CPU low
    int num_iterations = 10;
    int blocks_per_iteration = 5; // 5 blocks of 1MB = 5MB per iteration
    
    for (int i = 0; i < num_iterations; i++) {
        // Create unique filename for this iteration
        snprintf(filename, sizeof(filename), "/tmp/io_test_%d_%d.dat", id, i);
        
        // Write operation - write 5MB per file (5 × 1MB blocks)
        int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd < 0) {
            perror("Failed to open file for writing");
            continue;
        }
        
        // Write 5 blocks of 1MB each = 5MB per file
        for (int j = 0; j < blocks_per_iteration; j++) {
            ssize_t written = write(fd, buffer, buffer_size);
            if (written < 0) {
                perror("Write failed");
                break;
            }
        }
        
        // Sync to disk to ensure real I/O happens (adds delay for monitoring)
        fsync(fd);
        close(fd);
        
        // Read operation - read all data back (5MB)
        fd = open(filename, O_RDONLY);
        if (fd < 0) {
            perror("Failed to open file for reading");
            unlink(filename);
            continue;
        }
        
        // Read back all the data in 1MB chunks
        ssize_t bytes_read;
        while ((bytes_read = read(fd, read_buffer, buffer_size)) > 0) {
            // Minimal processing to prevent optimization
            volatile char temp = read_buffer[0];
            (void)temp;
        }
        
        close(fd);
        
        // Delete the file
        unlink(filename);
        
        // Add 200ms delay between iterations to:
        // 1. Keep CPU usage LOW (< 20%)
        // 2. Ensure monitoring has time to capture metrics
        // 3. Allow iostat to register the I/O activity properly
        usleep(200000); // 200ms delay
    }
    
    // Cleanup buffers
    free(buffer);
    free(read_buffer);
}
