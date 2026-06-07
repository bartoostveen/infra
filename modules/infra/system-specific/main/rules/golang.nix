{
  groups = [
    {
      name = "GolangExporter";
      rules = [
        {
          alert = "GoGoroutineCountHigh";
          annotations = {
            description = "Go application has too many goroutines (> 1000), potential goroutine leak\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go goroutine count high (instance {{ $labels.instance }})";
          };
          expr = "go_goroutines > 1000";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoGcDurationHigh";
          annotations = {
            description = "Go GC pause duration is too high (max > 1s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go GC duration high (instance {{ $labels.instance }})";
          };
          expr = "go_gc_duration_seconds{quantile=\"1\"} > 1";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoMemoryUsageHigh";
          annotations = {
            description = "Go heap allocation is using most of the runtime's reserved memory (> 90%), indicating the process may need more memory or has a leak\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go memory usage high (instance {{ $labels.instance }})";
          };
          expr = "(go_memstats_heap_alloc_bytes / go_memstats_sys_bytes) * 100 > 90";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoThreadCountHigh";
          annotations = {
            description = "Go OS thread count is high (> 500), potential blocking syscall or CGo leak\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go thread count high (instance {{ $labels.instance }})";
          };
          expr = "go_threads > 500";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoHeapObjectsCountHigh";
          annotations = {
            description = "Go heap has too many live objects (> 10M), high GC pressure\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go heap objects count high (instance {{ $labels.instance }})";
          };
          expr = "go_memstats_heap_objects > 10000000";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoGcCpuFractionHigh";
          annotations = {
            description = "Go GC is consuming too much CPU (> 5%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go GC CPU fraction high (instance {{ $labels.instance }})";
          };
          expr = "rate(go_gc_duration_seconds_sum[5m]) > 0.05";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoGoroutineSpike";
          annotations = {
            description = "Go goroutine count is growing rapidly ({{ $value | printf \"%.0f\" }} goroutines/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go goroutine spike (instance {{ $labels.instance }})";
          };
          expr = "deriv(go_goroutines[5m]) > 10";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoHeapIn-useGrowing";
          annotations = {
            description = "Go heap in-use memory is growing steadily, potential memory leak or under-sized heap\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go heap in-use growing (instance {{ $labels.instance }})";
          };
          expr = "deriv(go_memstats_heap_inuse_bytes[10m]) > 1e7";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoMemoryLeak";
          annotations = {
            description = "Go application has sustained high allocation rate (> 1GB/s), potential memory leak\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go memory leak (instance {{ $labels.instance }})";
          };
          expr = "rate(go_memstats_alloc_bytes_total[5m]) > 1e9";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "GoStackMemoryHigh";
          annotations = {
            description = "Go stack memory usage is high (> 1GB), likely excessive goroutines or deep recursion\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Go stack memory high (instance {{ $labels.instance }})";
          };
          expr = "go_memstats_stack_inuse_bytes > 1e9";
          for = "5m";
          labels = {
            severity = "warning";
          };
        }
      ];
    }
  ];
}
