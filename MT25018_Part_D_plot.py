import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Read the CSV file
df = pd.read_csv('MT25018_Part_D_CSV.csv')

# Separate data by Program (A=Process, B=Thread)
process_data = df[df['Program'] == 'A']
thread_data = df[df['Program'] == 'B']

# Create figure with 3x3 subplots
fig, axes = plt.subplots(3, 3, figsize=(15, 12))
fig.suptitle('Process vs Thread Performance Comparison', fontsize=16, y=0.995)

# Plot 1: CPU Worker - Memory vs Count
ax = axes[0, 0]
cpu_proc = process_data[process_data['Function'] == 'cpu']
cpu_thread = thread_data[thread_data['Function'] == 'cpu']
ax.plot(cpu_proc['Num_Workers'], cpu_proc['Memory(MB)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(cpu_thread['Num_Workers'], cpu_thread['Memory(MB)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('Memory (KB)', fontsize=11)
ax.set_title('CPU Worker: Memory vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 2: CPU Worker - CPU vs Count
ax = axes[0, 1]
ax.plot(cpu_proc['Num_Workers'], cpu_proc['CPU%'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(cpu_thread['Num_Workers'], cpu_thread['CPU%'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('CPU Usage (%)', fontsize=11)
ax.set_title('CPU Worker: CPU vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 3: IO Worker - IO vs Count
ax = axes[0, 2]
io_proc = process_data[process_data['Function'] == 'io']
io_thread = thread_data[thread_data['Function'] == 'io']
ax.plot(io_proc['Num_Workers'], io_proc['IO(MB/s)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(io_thread['Num_Workers'], io_thread['IO(MB/s)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('Disk IO (MiB)', fontsize=11)
ax.set_title('IO Worker: IO vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 4: IO Worker - Memory vs Count
ax = axes[1, 0]
ax.plot(io_proc['Num_Workers'], io_proc['Memory(MB)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(io_thread['Num_Workers'], io_thread['Memory(MB)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('Memory (KB)', fontsize=11)
ax.set_title('IO Worker: Memory vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 5: IO Worker - CPU vs Count
ax = axes[1, 1]
ax.plot(io_proc['Num_Workers'], io_proc['CPU%'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(io_thread['Num_Workers'], io_thread['CPU%'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('CPU Usage (%)', fontsize=11)
ax.set_title('IO Worker: CPU vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 6: Memory Worker - IO vs Count
ax = axes[1, 2]
mem_proc = process_data[process_data['Function'] == 'mem']
mem_thread = thread_data[thread_data['Function'] == 'mem']
ax.plot(mem_proc['Num_Workers'], mem_proc['IO(MB/s)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(mem_thread['Num_Workers'], mem_thread['IO(MB/s)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('Disk IO (MiB)', fontsize=11)
ax.set_title('Memory Worker: IO vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 7: Memory Worker - Memory vs Count
ax = axes[2, 0]
ax.plot(mem_proc['Num_Workers'], mem_proc['Memory(MB)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(mem_thread['Num_Workers'], mem_thread['Memory(MB)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('Memory (KB)', fontsize=11)
ax.set_title('Memory Worker: Memory vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 8: Memory Worker - CPU vs Count
ax = axes[2, 1]
ax.plot(mem_proc['Num_Workers'], mem_proc['CPU%'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(mem_thread['Num_Workers'], mem_thread['CPU%'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('CPU Usage (%)', fontsize=11)
ax.set_title('Memory Worker: CPU vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Plot 9: CPU Worker - IO vs Count
ax = axes[2, 2]
ax.plot(cpu_proc['Num_Workers'], cpu_proc['IO(MB/s)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
ax.plot(cpu_thread['Num_Workers'], cpu_thread['IO(MB/s)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
ax.set_xlabel('Count', fontsize=11)
ax.set_ylabel('Disk IO (MiB)', fontsize=11)
ax.set_title('CPU Worker: IO vs Count', fontsize=12, fontweight='bold')
ax.legend()
ax.grid(True, alpha=0.3)

# Close the combined figure
plt.close(fig)

# Now create individual plots
print("Generating individual plots...")

# Plot 1: CPU Worker - Memory vs Count
plt.figure(figsize=(8, 6))
cpu_proc = process_data[process_data['Function'] == 'cpu']
cpu_thread = thread_data[thread_data['Function'] == 'cpu']
plt.plot(cpu_proc['Num_Workers'], cpu_proc['Memory(MB)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(cpu_thread['Num_Workers'], cpu_thread['Memory(MB)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('Memory (KB)', fontsize=12)
plt.title('CPU Worker: Memory vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot1_cpu_memory_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot1_cpu_memory_vs_count.png")

# Plot 2: CPU Worker - CPU vs Count
plt.figure(figsize=(8, 6))
plt.plot(cpu_proc['Num_Workers'], cpu_proc['CPU%'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(cpu_thread['Num_Workers'], cpu_thread['CPU%'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('CPU Usage (%)', fontsize=12)
plt.title('CPU Worker: CPU vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot2_cpu_cpu_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot2_cpu_cpu_vs_count.png")

# Plot 3: IO Worker - IO vs Count
plt.figure(figsize=(8, 6))
io_proc = process_data[process_data['Function'] == 'io']
io_thread = thread_data[thread_data['Function'] == 'io']
plt.plot(io_proc['Num_Workers'], io_proc['IO(MB/s)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(io_thread['Num_Workers'], io_thread['IO(MB/s)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('Disk IO (MiB)', fontsize=12)
plt.title('IO Worker: IO vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot3_io_io_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot3_io_io_vs_count.png")

# Plot 4: IO Worker - Memory vs Count
plt.figure(figsize=(8, 6))
plt.plot(io_proc['Num_Workers'], io_proc['Memory(MB)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(io_thread['Num_Workers'], io_thread['Memory(MB)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('Memory (KB)', fontsize=12)
plt.title('IO Worker: Memory vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot4_io_memory_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot4_io_memory_vs_count.png")

# Plot 5: IO Worker - CPU vs Count
plt.figure(figsize=(8, 6))
plt.plot(io_proc['Num_Workers'], io_proc['CPU%'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(io_thread['Num_Workers'], io_thread['CPU%'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('CPU Usage (%)', fontsize=12)
plt.title('IO Worker: CPU vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot5_io_cpu_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot5_io_cpu_vs_count.png")

# Plot 6: Memory Worker - IO vs Count
plt.figure(figsize=(8, 6))
mem_proc = process_data[process_data['Function'] == 'mem']
mem_thread = thread_data[thread_data['Function'] == 'mem']
plt.plot(mem_proc['Num_Workers'], mem_proc['IO(MB/s)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(mem_thread['Num_Workers'], mem_thread['IO(MB/s)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('Disk IO (MiB)', fontsize=12)
plt.title('Memory Worker: IO vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot6_memory_io_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot6_memory_io_vs_count.png")

# Plot 7: Memory Worker - Memory vs Count
plt.figure(figsize=(8, 6))
plt.plot(mem_proc['Num_Workers'], mem_proc['Memory(MB)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(mem_thread['Num_Workers'], mem_thread['Memory(MB)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('Memory (KB)', fontsize=12)
plt.title('Memory Worker: Memory vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot7_memory_memory_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot7_memory_memory_vs_count.png")

# Plot 8: Memory Worker - CPU vs Count
plt.figure(figsize=(8, 6))
plt.plot(mem_proc['Num_Workers'], mem_proc['CPU%'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(mem_thread['Num_Workers'], mem_thread['CPU%'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('CPU Usage (%)', fontsize=12)
plt.title('Memory Worker: CPU vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot8_memory_cpu_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot8_memory_cpu_vs_count.png")

# Plot 9: CPU Worker - IO vs Count
plt.figure(figsize=(8, 6))
plt.plot(cpu_proc['Num_Workers'], cpu_proc['IO(MB/s)'], 'o-', color='#8B5CF6', label='Process', linewidth=2, markersize=8)
plt.plot(cpu_thread['Num_Workers'], cpu_thread['IO(MB/s)'], 'o-', color='#14B8A6', label='Thread', linewidth=2, markersize=8)
plt.xlabel('Count', fontsize=12)
plt.ylabel('Disk IO (MiB)', fontsize=12)
plt.title('CPU Worker: IO vs Count', fontsize=14, fontweight='bold')
plt.legend(fontsize=11)
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('plot9_cpu_io_vs_count.png', dpi=300, bbox_inches='tight')
plt.close()
print("✓ Saved: plot9_cpu_io_vs_count.png")

print("\nAll 9 plots have been saved successfully!")