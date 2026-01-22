/*
 * MT25018
 * Part A: Program A - Fork-based Process Creation
 * Creates child processes using fork() to execute worker functions
 * 
 * Usage: ./program_a <function_type> <num_processes>
 * where function_type is one of: cpu, mem, io
 * and num_processes is the number of child processes to create (1-100)
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include "MT25018_Part_B_workers.h"

/*
 * Main function
 * Creates specified number of child processes to execute the specified worker function
 */
int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <function_type> <num_processes>\n", argv[0]);
        fprintf(stderr, "  function_type: cpu, mem, or io\n");
        fprintf(stderr, "  num_processes: number of processes to create\n");
        exit(EXIT_FAILURE);
    }
    
    char *function_type = argv[1];
    int NUM_PROCESSES = atoi(argv[2]);
    
    if (NUM_PROCESSES <= 0 || NUM_PROCESSES > 100) {
        fprintf(stderr, "Error: num_processes must be between 1 and 100\n");
        exit(EXIT_FAILURE);
    }
    
    // Validate function type
    if (strcmp(function_type, "cpu") != 0 && 
        strcmp(function_type, "mem") != 0 && 
        strcmp(function_type, "io") != 0) {
        fprintf(stderr, "Error: Invalid function type '%s'\n", function_type);
        fprintf(stderr, "Must be one of: cpu, mem, io\n");
        exit(EXIT_FAILURE);
    }
    
    printf("Program A: Creating %d child processes for '%s' function\n", 
           NUM_PROCESSES, function_type);
    printf("Process PID: %d\n", getpid());
    
    // Create child processes
    for (int i = 0; i < NUM_PROCESSES; i++) {
        pid_t pid = fork();
        
        if (pid < 0) {
            // Fork failed
            perror("Fork failed");
            exit(EXIT_FAILURE);
        } 
        else if (pid == 0) {
            // Child process
            printf("Child process %d started (PID: %d)\n", i + 1, getpid());
            
            // Execute the appropriate worker function
            if (strcmp(function_type, "cpu") == 0) {
                cpu_intensive_work(i + 1);
            } 
            else if (strcmp(function_type, "mem") == 0) {
                mem_intensive_work(i + 1);
            } 
            else if (strcmp(function_type, "io") == 0) {
                io_intensive_work(i + 1);
            }
            
            printf("Child process %d completed (PID: %d)\n", i + 1, getpid());
            exit(EXIT_SUCCESS);
        } 
        else {
            // Parent process
            printf("Parent created child %d with PID: %d\n", i + 1, pid);
        }
    }
    
    // Parent process waits for all children to complete
    printf("Parent process (PID: %d) waiting for children to complete...\n", getpid());
    
    for (int i = 0; i < NUM_PROCESSES; i++) {
        int status;
        pid_t finished_pid = wait(&status);
        
        if (finished_pid > 0) {
            if (WIFEXITED(status)) {
                printf("Child process (PID: %d) exited with status %d\n", 
                       finished_pid, WEXITSTATUS(status));
            } else {
                printf("Child process (PID: %d) terminated abnormally\n", finished_pid);
            }
        }
    }
    
    printf("Program A: All child processes completed\n");
    return EXIT_SUCCESS;
}
