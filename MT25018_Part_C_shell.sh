#!/bin/bash

################################################################################
# MT25018
# Part C: Automated Measurement Script
# Executes 6 program+worker combinations and collects metrics
# Uses: top (CPU% and Memory), taskset (CPU pinning), iostat (I/O), time (execution time)
# Usage: ./MT25018_Part_C_shell.sh
################################################################################

# Output files
CSV_FILE="MT25018_Part_C_CSV.csv"
TEMP_DIR="/tmp/grs_pa01_measurements"

# Create temp directory
mkdir -p "$TEMP_DIR"

# CPU core to pin (core 0 as specified)
CPU_CORE="0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Function: Print colored output
################################################################################
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}========================================${NC}"
}

################################################################################
# Function: Monitor program with top - saves continuous output to file
################################################################################
monitor_with_top() {
    local pid=$1
    local output_file=$2
    local log_file="${output_file}.log"
    
    echo -e "${BLUE}[MONITOR]${NC} Waiting for process to start properly..." >&2
    sleep 0.5  # Give process time to actually start and use resources
    
    echo -e "${BLUE}[MONITOR]${NC} Starting continuous monitoring for PID $pid..." >&2
    
    # Clear log file
    > "$log_file"
    
    local count=0
    local total_cpu=0
    local total_mem=0
    local max_cpu=0
    local max_mem=0
    
    # Monitor while process is running
    while kill -0 $pid 2>/dev/null; do
        # Get all child processes (exclude parent which is just waiting)
        local children=$(pgrep -P $pid 2>/dev/null)
        
        # If we have children, monitor them; otherwise monitor parent
        local pids=""
        if [ ! -z "$children" ]; then
            # For fork-based: monitor only children (they do the work)
            for child in $children; do
                if [ -z "$pids" ]; then
                    pids="$child"
                else
                    pids="$pids,$child"
                fi
            done
        else
            # For thread-based: monitor the main process (contains all threads)
            pids="$pid"
        fi
        
        # Skip if no pids to monitor
        if [ -z "$pids" ]; then
            sleep 0.5
            continue
        fi
        
        # Use top to get stats for all processes
        local stats=$(top -b -n 1 -p ${pids//,/,} 2>/dev/null | tail -n +8 | awk '{print $1, $9, $10, $6}')
        
        if [ ! -z "$stats" ]; then
            # Sum CPU percentages (field 2)
            local cpu_sum=$(echo "$stats" | awk '{sum+=$2} END {printf "%.1f", sum}')
            
            # Sum memory from RES field (field 4), convert to MB
            local mem_kb_sum=$(echo "$stats" | awk '{gsub(/[^0-9]/,"",$4); sum+=$4} END {print sum}')
            local mem_mb=$(echo "scale=2; $mem_kb_sum / 1024" | bc)
            
            if [ ! -z "$cpu_sum" ] && [ "$cpu_sum" != "" ]; then
                echo "$cpu_sum $mem_pct_sum $mem_mb" >> "$log_file"
                total_cpu=$(echo "$total_cpu + $cpu_sum" | bc 2>/dev/null || echo "$total_cpu")
                total_mem=$(echo "$total_mem + $mem_mb" | bc 2>/dev/null || echo "$total_mem")
                count=$((count + 1))
                
                # Track max values
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
# Function: Get I/O statistics using iostat
################################################################################
get_io_stats() {
    # Use iostat to get disk I/O statistics
    # -d: disk stats, -x: extended stats, -m: MB/s, 1 2: 1 sec interval, 2 samples
    local io_output=$(iostat -d -x -m 1 2 | tail -n +4 | grep -E '^[s|h|v|n]' | head -1)
    
    if [ -z "$io_output" ]; then
        echo "0.00,0.00"
        return
    fi
    
    # Extract read MB/s (rMB/s) and write MB/s (wMB/s)
    # Columns: Device r/s w/s rMB/s wMB/s...
    local read_mbs=$(echo "$io_output" | awk '{print $6}')
    local write_mbs=$(echo "$io_output" | awk '{print $7}')
    
    # Handle empty values
    read_mbs=${read_mbs:-0.00}
    write_mbs=${write_mbs:-0.00}
    
    echo "${read_mbs},${write_mbs}"
}

################################################################################
# Function: Measure single program execution
################################################################################
measure_program() {
    local program=$1
    local function=$2
    local variant_name=$3
    
    # ALL output redirected to stderr (&2) so only return value goes to stdout
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    print_info "Starting measurement: $variant_name" >&2
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    local top_file="$TEMP_DIR/top_${variant_name}.txt"
    local iostat_during_file="$TEMP_DIR/iostat_during_${variant_name}.txt"
    local time_file="$TEMP_DIR/time_${variant_name}.txt"
    
    # STEP 1: Start iostat monitoring in background (with short interval for CPU tests)
    echo -e "${YELLOW}[STEP 1/5]${NC} Starting continuous iostat monitoring..." >&2
    
    # Use 1-second interval for better accuracy, skip first sample (baseline)
    iostat -d -x -m 1 > "$iostat_during_file" 2>&1 &
    local iostat_pid=$!
    echo -e "${GREEN}         ✓${NC} iostat monitoring started (PID: $iostat_pid)" >&2
    
    # STEP 2: Run program with taskset and time
    echo -e "${YELLOW}[STEP 2/5]${NC} Launching program with taskset (CPU core $CPU_CORE)..." >&2
    echo -e "${GREEN}         ✓${NC} Command: taskset -c $CPU_CORE ./$program $function 2" >&2
    
    # Record start time
    local start_time=$(date +%s.%N)
    
    # Start the program with taskset (using 2 workers for Part C)
    taskset -c $CPU_CORE ./"$program" "$function" 2 > /dev/null 2>&1 &
    local program_pid=$!
    
    echo -e "${GREEN}         ✓${NC} Program started with PID: $program_pid" >&2
    
    # STEP 3: Monitor with ps/top
    echo -e "${YELLOW}[STEP 3/5]${NC} Monitoring CPU and Memory..." >&2
    monitor_with_top $program_pid "$top_file" &
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
    
    # Parse top/ps output (CPU% and Memory in MB)
    local top_data=$(cat "$top_file" 2>/dev/null || echo "0.00,0.00,0.00,0.00")
    local avg_cpu=$(echo "$top_data" | cut -d',' -f1)
    local avg_mem_mb=$(echo "$top_data" | cut -d',' -f2)
    local max_cpu=$(echo "$top_data" | cut -d',' -f3)
    local max_mem_mb=$(echo "$top_data" | cut -d',' -f4)
    
    # Parse iostat output - skip first 2 samples (baseline), then average the rest
    sleep 1  # Let iostat finish writing
    # Skip first few lines (headers) and first 2 data samples, then calculate average
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
    echo -e "${GREEN}║${NC} CPU% (Avg):      ${YELLOW}${avg_cpu}%${NC}" >&2
    echo -e "${GREEN}║${NC} Memory (Avg):    ${YELLOW}${avg_mem_mb} MB${NC}" >&2
    echo -e "${GREEN}║${NC} I/O (Avg):       ${YELLOW}${io_total} MB/s${NC}" >&2
    echo -e "${GREEN}║${NC} Execution Time:  ${YELLOW}${exec_time} seconds${NC}" >&2
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}" >&2
    echo "" >&2
    
    # Clean up temp files
    rm -f "$top_file" "$top_file.log" "$iostat_during_file" "$time_file"
    
    # Return ONLY CSV format to stdout: CPU%,Memory(MB),IO(MB/s),Time(s)
    echo "${avg_cpu},${avg_mem_mb},${io_total},${exec_time}"
}

################################################################################
# Function: Run all measurements
################################################################################
run_measurements() {
    print_section "Starting Part C Measurements"
    
    # Check if programs exist
    if [ ! -f "./MT25018_Part_A_Program_A" ]; then
        print_error "Program A not found. Please run 'make' first."
        exit 1
    fi
    
    if [ ! -f "./MT25018_Part_A_Program_B" ]; then
        print_error "Program B not found. Please run 'make' first."
        exit 1
    fi
    
    # Initialize CSV file with header
    echo "Program+Function,CPU%,Memory(MB),IO(MB/s),ExecutionTime(s)" > "$CSV_FILE"
    
    # Array of combinations
    declare -a programs=("MT25018_Part_A_Program_A" "MT25018_Part_A_Program_B")
    declare -a program_names=("A" "B")
    declare -a functions=("cpu" "mem" "io")
    
    # Run all combinations
    for i in "${!programs[@]}"; do
        program="${programs[$i]}"
        program_name="${program_names[$i]}"
        
        for function in "${functions[@]}"; do
            variant_name="${program_name}+${function}"
            
            echo "" >&2
            print_section "TESTING: Program ${program_name} with ${function} function" >&2
            echo -e "${BLUE}Progress: Processing variant ${variant_name}${NC}" >&2
            echo "" >&2
            
            # Measure the program
            metrics=$(measure_program "$program" "$function" "$variant_name")
            
            # Add to CSV
            echo "${variant_name},${metrics}" >> "$CSV_FILE"
            print_info "✓ Results saved to CSV" >&2
            
            # Clean up any leftover temp files
            rm -f /tmp/io_test_* 2>/dev/null
            
            # Delay between runs
            echo -e "${BLUE}[INFO]${NC} Cooling down (3 seconds)..." >&2
            sleep 3
        done
    done
    
    print_section "Measurements Complete"
    print_info "Results saved to: $CSV_FILE"
    
    # Display results in table format
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              PART C - RESULTS SUMMARY                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    column -t -s ',' "$CSV_FILE"
    echo ""
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR"
}

################################################################################
# Function: Display analysis
################################################################################
display_analysis() {
    print_section "Analysis and Observations"
    
    echo ""
    echo "EXPECTED OBSERVATIONS:"
    echo "====================="
    echo ""
    echo "1. CPU-Intensive Workload (A+cpu, B+cpu):"
    echo "   - High CPU% utilization (close to 100% or higher with multiple processes)"
    echo "   - Low memory usage"
    echo "   - Very low I/O operations"
    echo "   - Threads may show better CPU utilization due to lower overhead"
    echo ""
    echo "2. Memory-Intensive Workload (A+mem, B+mem):"
    echo "   - Moderate to high CPU% (due to memory operations)"
    echo "   - Higher memory usage compared to other workloads"
    echo "   - Low I/O operations"
    echo "   - Threads may share memory more efficiently"
    echo ""
    echo "3. I/O-Intensive Workload (A+io, B+io):"
    echo "   - Low CPU% (CPU waits for I/O)"
    echo "   - Low to moderate memory usage"
    echo "   - High I/O operations (MB/s for read/write)"
    echo "   - Similar performance between processes and threads"
    echo ""
    echo "4. Process vs Thread Comparison:"
    echo "   - Processes (Program A): Better isolation, higher overhead"
    echo "   - Threads (Program B): Lower overhead, shared memory space"
    echo "   - CPU-bound: Threads may be slightly faster"
    echo "   - I/O-bound: Similar performance"
    echo ""
}

################################################################################
# Main execution
################################################################################
main() {
    print_section "MT25018 - Part C: Automated Performance Measurement"
    
    # Check for required commands
    print_info "Checking required tools..."
    
    command -v taskset >/dev/null 2>&1 || { print_error "taskset not found. Install: sudo apt install util-linux"; exit 1; }
    command -v iostat >/dev/null 2>&1 || { print_error "iostat not found. Install: sudo apt install sysstat"; exit 1; }
    command -v bc >/dev/null 2>&1 || { print_error "bc not found. Install: sudo apt install bc"; exit 1; }
    command -v top >/dev/null 2>&1 || { print_error "top not found. Please install procps package"; exit 1; }
    command -v time >/dev/null 2>&1 || { print_error "time command not found"; exit 1; }
    
    print_info "All required tools found!"
    print_info "CPU Core for pinning: $CPU_CORE"
    print_info "Monitoring tools: top, iostat, time, taskset"
    
    # Run measurements
    run_measurements
    
    # Display analysis
    display_analysis
    
    print_section "Script Completed Successfully"
    print_info "Results saved in: $CSV_FILE"
    print_info "Use 'cat $CSV_FILE' to view raw data"
}

# Execute main function
main
