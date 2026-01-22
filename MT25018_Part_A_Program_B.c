/*
 * MT25018
 * Part A: Program B - Pthread-based Thread Creation
 * Creates threads using pthread to execute worker functions
 * 
 * Usage: ./program_b <function_type> <num_threads>
 * where function_type is one of: cpu, mem, io
 * and num_threads is the number of threads to create (1-100)
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <unistd.h>
#include "MT25018_Part_B_workers.h"

// Structure to pass arguments to thread function
typedef struct {
    int thread_id;
    char function_type[10];
} thread_args_t;

/*
 * Thread function
 * Executes the specified worker function
 */
void *thread_function(void *arg) {
    thread_args_t *args = (thread_args_t *)arg;
    
    printf("Thread %d started (TID: %lu)\n", args->thread_id, pthread_self());
    
    // Execute the appropriate worker function
    if (strcmp(args->function_type, "cpu") == 0) {
        cpu_intensive_work(args->thread_id);
    } 
    else if (strcmp(args->function_type, "mem") == 0) {
        mem_intensive_work(args->thread_id);
    } 
    else if (strcmp(args->function_type, "io") == 0) {
        io_intensive_work(args->thread_id);
    }
    
    printf("Thread %d completed (TID: %lu)\n", args->thread_id, pthread_self());
    
    pthread_exit(NULL);
}

/*
 * Main function
 * Creates specified number of threads to execute the specified worker function
 */
int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <function_type> <num_threads>\n", argv[0]);
        fprintf(stderr, "  function_type: cpu, mem, or io\n");
        fprintf(stderr, "  num_threads: number of threads to create\n");
        exit(EXIT_FAILURE);
    }
    
    int NUM_THREADS = atoi(argv[2]);
    
    if (NUM_THREADS <= 0 || NUM_THREADS > 100) {
        fprintf(stderr, "Error: num_threads must be between 1 and 100\n");
        exit(EXIT_FAILURE);
    }
    
    char *function_type = argv[1];
    
    // Validate function type
    if (strcmp(function_type, "cpu") != 0 && 
        strcmp(function_type, "mem") != 0 && 
        strcmp(function_type, "io") != 0) {
        fprintf(stderr, "Error: Invalid function type '%s'\n", function_type);
        fprintf(stderr, "Must be one of: cpu, mem, io\n");
        exit(EXIT_FAILURE);
    }
    
    printf("Program B: Creating %d threads for '%s' function\n", 
           NUM_THREADS, function_type);
    printf("Main thread PID: %d, TID: %lu\n", getpid(), pthread_self());
    
    // Arrays for thread management
    pthread_t threads[NUM_THREADS];
    thread_args_t thread_args[NUM_THREADS];
    
    // Create threads
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_args[i].thread_id = i + 1;
        strncpy(thread_args[i].function_type, function_type, 
                sizeof(thread_args[i].function_type) - 1);
        thread_args[i].function_type[sizeof(thread_args[i].function_type) - 1] = '\0';
        
        int rc = pthread_create(&threads[i], NULL, thread_function, 
                                (void *)&thread_args[i]);
        
        if (rc) {
            fprintf(stderr, "Error: pthread_create() failed with code %d\n", rc);
            exit(EXIT_FAILURE);
        }
        
        printf("Main thread created thread %d\n", i + 1);
    }
    
    // Wait for all threads to complete
    printf("Main thread waiting for threads to complete...\n");
    
    for (int i = 0; i < NUM_THREADS; i++) {
        int rc = pthread_join(threads[i], NULL);
        
        if (rc) {
            fprintf(stderr, "Error: pthread_join() failed with code %d\n", rc);
            exit(EXIT_FAILURE);
        }
        
        printf("Thread %d joined successfully\n", i + 1);
    }
    
    printf("Program B: All threads completed\n");
    return EXIT_SUCCESS;
}
