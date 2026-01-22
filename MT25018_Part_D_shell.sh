#!/bin/bash

################################################################################
# MT25018
# Part D: Extended Measurement Script with Variable Processes/Threads
# Based on Part C script with added loops for different worker counts
# Usage: ./MT25018_Part_D_shell.sh
################################################################################

# Configuration
CSV_FILE="MT25018_Part_D_CSV.csv"
TEMP_DIR="/tmp/grs_pa01_part_d"
CPU_CORE=0

# Use existing programs from Part A
PROGRAM_A="./MT25018_Part_A_Program_A"
PROGRAM_B="./MT25018_Part_A_Program_B"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Helper Functions
################################################################################
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_section() {
    echo "" >&2
    echo -e "${YELLOW}========================================${NC}" >&2
    echo -e "${YELLOW}$1${NC}" >&2
    echo -e "${YELLOW}========================================${NC}" >&2
}

print_header() {
    echo "" >&2
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}" >&2
    echo -e "${BLUE}║  $1${NC}" >&2
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}" >&2
}

################################################################################
# Function: Monitor process with top (CPU% and Memory in MB)
################################################################################
monitor_with_top() {
    local pids=$1
    local output_file=$2
    local log_file="${output_file}.log"
    
    sleep 0.5  # Give process time to start
    
    # Check if process still exists
    if ! ps -p $pids > /dev/null 2>/dev/null; then
        echo "0.00,0.00,0.00,0.00" > "$output_file"
        return
    fi
    
    local count=0
    local total_cpu=0
    local total_mem=0
    local max_cpu=0
    local max_mem=0
    
    # Monitor for up to 60 seconds or until process ends
    while [ $count -lt 120 ]; do
        # Get all PIDs (main process + children)
        local all_pids=$(pgrep -P $pids 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        if [ -z "$all_pids" ]; then
            all_pids=$pids
        else
            all_pids="$pids,$all_pids"
        fi
        
        # Check if main process still exists
        if ! ps -p $pids > /dev/null 2>/dev/null; then
            break
        fi
        
        # Use top to get stats for all processes
        local stats=$(top -b -n 1 -p ${all_pids//,/,} 2>/dev/null | tail -n +8 | awk '{print $1, $9, $10, $6}')
        
        if [ -n "$stats" ]; then
            # Sum CPU percentages (field 2)
            local cpu_sum=$(echo "$stats" | awk '{sum+=$2} END {print sum}')
            
            # Sum memory from RES field (field 4), convert to MB
            local mem_kb_sum=$(echo "$stats" | awk '{gsub(/[^0-9]/,"",$4); sum+=$4} END {print sum}')
            local mem_mb=$(echo "scale=2; $mem_kb_sum / 1024" | bc)
            
            if [ -n "$cpu_sum" ] && [ -n "$mem_mb" ]; then
                total_cpu=$(echo "$total_cpu + $cpu_sum" | bc)
                total_mem=$(echo "$total_mem + $mem_mb" | bc)
                count=$((count + 1))
                
                # Track maximums
                if (( $(echo "$cpu_sum > $max_cpu" | bc -l 2>/dev/null || echo 0) )); then
                    max_cpu=$cpu_sum
                fi
                
                if (( $(echo "$mem_mb > $max_mem" | bc -l 2>/dev/null || echo 0) )); then
                    max_mem=$mem_mb
                fi
                
                # Show progress every 2 samples
                if [ $((count % 2)) -eq 0 ]; then
                    echo -e "${BLUE}[MONITOR]${NC} Sample $count: CPU=${cpu_sum}%, MEM=${mem_mb}MB" >&2
                fi
            fi
        fi
        
        sleep 0.5  # Sample every 0.5 seconds for better CPU capture
    done
    
    echo -e "${BLUE}[MONITOR]${NC} Monitoring complete. Total samples: $count" >&2
    
    # Calculate averages from collected data
    if [ $count -gt 0 ]; then
        local avg_cpu=$(echo "scale=2; $total_cpu / $count" | bc)
        local avg_mem=$(echo "scale=2; $total_mem / $count" | bc)
        
        # Handle empty values
        avg_cpu=${avg_cpu:-0.00}
        avg_mem=${avg_mem:-0.00}
        max_cpu=${max_cpu:-0.00}
        max_mem=${max_mem:-0.00}
        
        echo "$avg_cpu,$avg_mem,$max_cpu,$max_mem" > "$output_file"
        echo -e "${GREEN}         ✓${NC} Results: CPU=${avg_cpu}%, MEM=${avg_mem}MB" >&2
    else
        echo "0.00,0.00,0.00,0.00" > "$output_file"
        echo -e "${RED}         ✗${NC} WARNING: No samples collected! Process may have finished too quickly." >&2
    fi
    
    # Clean up log file
    rm -f "$log_file"
}

################################################################################
# Function: Measure single program execution
################################################################################
measure_program() {
    local program=$1
    local function=$2
    local num_workers=$3
    local variant_name=$4
    
    # ALL output redirected to stderr (&2) so only return value goes to stdout
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    print_info "Starting measurement: $variant_name (Workers: $num_workers)" >&2
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    local ps_file="$TEMP_DIR/ps_${variant_name}.txt"
    local iostat_during_file="$TEMP_DIR/iostat_during_${variant_name}.txt"
    
    # STEP 1: Start iostat monitoring in background
    echo -e "${YELLOW}[STEP 1/5]${NC} Starting continuous iostat monitoring..." >&2
    iostat -d -x -m 1 > "$iostat_during_file" 2>&1 &
    local iostat_pid=$!
    echo -e "${GREEN}         ✓${NC} iostat monitoring started (PID: $iostat_pid)" >&2
    
    # STEP 2: Run program with taskset and time
    echo -e "${YELLOW}[STEP 2/5]${NC} Launching program with taskset (CPU core $CPU_CORE)..." >&2
    echo -e "${GREEN}         ✓${NC} Command: taskset -c $CPU_CORE $program $function $num_workers" >&2
    
    # Record start time
    local start_time=$(date +%s.%N)
    
    # Start the program with taskset
    taskset -c $CPU_CORE $program $function $num_workers > /dev/null 2>&1 &
    local program_pid=$!
    
    echo -e "${GREEN}         ✓${NC} Program started with PID: $program_pid" >&2
    
    # STEP 3: Monitor with top
    echo -e "${YELLOW}[STEP 3/5]${NC} Monitoring CPU and Memory..." >&2
    monitor_with_top $program_pid "$ps_file" &
    local monitor_pid=$!
    
    # Wait for program to complete
    echo -e "${BLUE}[WAIT]${NC} Waiting for program to complete..." >&2
    wait $program_pid
    local exit_code=$?
    
    # Record end time
    local end_time=$(date +%s.%N)
    local exec_time=$(echo "$end_time - $start_time" | bc)
    
    echo -e "${GREEN}         ✓${NC} Program completed (exit code: $exit_code, time: ${exec_time}s)" >&2
    
    # Stop iostat monitoring
    kill $iostat_pid 2>/dev/null
    wait $monitor_pid 2>/dev/null
    
    # STEP 4: Parse all collected data
    echo -e "${YELLOW}[STEP 4/5]${NC} Parsing collected metrics..." >&2
    
    # Parse ps output (CPU% and Memory in MB)
    local ps_data=$(cat "$ps_file" 2>/dev/null || echo "0.00,0.00,0.00,0.00")
    local avg_cpu=$(echo "$ps_data" | cut -d',' -f1)
    local avg_mem_mb=$(echo "$ps_data" | cut -d',' -f2)
    local max_cpu=$(echo "$ps_data" | cut -d',' -f3)
    local max_mem_mb=$(echo "$ps_data" | cut -d',' -f4)
    
    # Parse iostat output - skip first 2 samples (baseline), then average the rest
    sleep 1  # Let iostat finish writing
    local io_stats=$(grep -E '^[s|h|v|n]' "$iostat_during_file" 2>/dev/null | tail -n +3 | awk '{read+=$6; write+=$7; count++} END {if(count>0) printf "%.2f,%.2f", read/count, write/count; else print "0.00,0.00"}')
    local io_read=$(echo "$io_stats" | cut -d',' -f1)
    local io_write=$(echo "$io_stats" | cut -d',' -f2)
    local io_total=$(echo "scale=2; $io_read + $io_write" | bc)
    
    # Handle empty values
    avg_cpu=${avg_cpu:-0.00}
    avg_mem_mb=${avg_mem_mb:-0.00}
    io_total=${io_total:-0.00}
    exec_time=$(printf "%.2f" $exec_time)
    
    # STEP 5: Display results
    echo -e "${YELLOW}[STEP 5/5]${NC} Results summary..." >&2
    echo "" >&2
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}" >&2
    echo -e "${GREEN}║              MEASUREMENT RESULTS                     ║${NC}" >&2
    echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${NC}" >&2
    echo -e "${GREEN}║${NC} Variant:         ${YELLOW}${variant_name}${NC}" >&2
    echo -e "${GREEN}║${NC} Workers:         ${YELLOW}${num_workers}${NC}" >&2
    echo -e "${GREEN}║${NC} CPU% (Avg):      ${YELLOW}${avg_cpu}%${NC}" >&2
    echo -e "${GREEN}║${NC} Memory (Avg):    ${YELLOW}${avg_mem_mb} MB${NC}" >&2
    echo -e "${GREEN}║${NC} I/O (Avg):       ${YELLOW}${io_total} MB/s${NC}" >&2
    echo -e "${GREEN}║${NC} Execution Time:  ${YELLOW}${exec_time} seconds${NC}" >&2
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}" >&2
    echo "" >&2
    
    # Clean up temp files
    rm -f "$ps_file" "$ps_file.log" "$iostat_during_file"
    
    # Return ONLY CSV format to stdout: num_workers,CPU%,Memory(MB),IO(MB/s),Time(s)
    echo "${num_workers},${avg_cpu},${avg_mem_mb},${io_total},${exec_time}"
}

################################################################################
# Function: Create dynamic programs for variable worker counts
################################################################################
# NOT NEEDED - Using existing programs that now accept worker count as argument

################################################################################
# Function: Run all measurements
################################################################################
run_measurements() {
    print_section "Starting Part D Measurements"
    
    # Initialize CSV file with header
    echo "Program,Function,Num_Workers,CPU%,Memory(MB),IO(MB/s),ExecutionTime(s)" > "$CSV_FILE"
    
    # Define worker counts
    declare -a process_counts=(2 3 4 5)
    declare -a thread_counts=(2 3 4 5 6 7 8)
    declare -a functions=("cpu" "mem" "io")
    
    # Program A: Variable process counts (2, 3, 4, 5)
    print_header "PROGRAM A (Fork-based): Testing with 2, 3, 4, 5 processes" >&2
    for function in "${functions[@]}"; do
        for count in "${process_counts[@]}"; do
            result=$(measure_program "$PROGRAM_A" "$function" "$count" "A_${function}_${count}")
            echo "A,$function,$result" >> "$CSV_FILE"
            sleep 2  # Delay between tests to ensure clean separation
        done
    done
    
    # Program B: Variable thread counts (2, 3, 4, 5, 6, 7, 8)
    print_header "PROGRAM B (Pthread-based): Testing with 2, 3, 4, 5, 6, 7, 8 threads" >&2
    for function in "${functions[@]}"; do
        for count in "${thread_counts[@]}"; do
            result=$(measure_program "$PROGRAM_B" "$function" "$count" "B_${function}_${count}")
            echo "B,$function,$result" >> "$CSV_FILE"
            sleep 2  # Delay between tests to ensure clean separation
        done
    done
    
    print_section "Measurements Complete"
}

################################################################################
# Main execution
################################################################################
main() {
    print_section "MT25018 - Part D: Variable Worker Count Analysis"
    print_info "Date: $(date)" >&2
    print_info "Output CSV: $CSV_FILE" >&2
    
    # Check if programs exist
    if [ ! -f "$PROGRAM_A" ] || [ ! -f "$PROGRAM_B" ]; then
        print_error "Programs not found. Please compile first:"
        print_error "  gcc -o MT25018_Part_A_Program_A MT25018_Part_A_Program_A.c MT25018_Part_B_workers.c -lm"
        print_error "  gcc -o MT25018_Part_A_Program_B MT25018_Part_A_Program_B.c MT25018_Part_B_workers.c -pthread -lm"
        exit 1
    fi
    
    # Run measurements
    run_measurements
    
    # Display summary
    print_section "Summary"
    echo "" >&2
    print_info "Total measurements: 33" >&2
    print_info "  Program A (Processes 2-5): 12 measurements" >&2
    print_info "  Program B (Threads 2-8): 21 measurements" >&2
    echo "" >&2
    print_info "Results saved to: $CSV_FILE" >&2
    echo "" >&2
    echo "Preview of CSV:" >&2
    column -t -s ',' "$CSV_FILE" | head -15 >&2
    echo "" >&2
    print_info "To generate plots, run: python3 MT25018_Part_D_plot.py" >&2
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    rm -f /tmp/io_test_*
    
    print_section "Part D Complete!"
}

# Run main function
main
