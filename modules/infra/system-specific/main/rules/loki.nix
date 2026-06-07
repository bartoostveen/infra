{
  groups = [
    {
      name = "EmbeddedExporter";
      rules = [
        {
          alert = "LokiProcessTooManyRestarts";
          annotations = {
            description = "A loki process had too many restarts (target {{ $labels.instance }})\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Loki process too many restarts (instance {{ $labels.instance }})";
          };
          expr = "changes(process_start_time_seconds{job=~\".*loki.*\"}[15m]) > 2";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "LokiRequestErrors";
          annotations = {
            description = "The {{ $labels.job }} and {{ $labels.route }} are experiencing {{ printf \"%.2f\" $value }}% errors.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Loki request errors (instance {{ $labels.instance }})";
          };
          expr = "100 * sum(rate(loki_request_duration_seconds_count{status_code=~\"5..\"}[1m])) by (namespace, job, route) / sum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route) > 10 and sum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route) > 0";
          for = "15m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "LokiRequestPanic";
          annotations = {
            description = "{{ $labels.job }} is experiencing {{ $value | humanize }} panic(s) in the last 5 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Loki request panic (instance {{ $labels.instance }})";
          };
          expr = "sum(increase(loki_panic_total[5m])) by (namespace, job) > 0";
          for = "0m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "LokiRequestLatency";
          annotations = {
            description = "The {{ $labels.job }} {{ $labels.route }} is experiencing {{ printf \"%.2f\" $value }}s 99th percentile latency.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Loki request latency (instance {{ $labels.instance }})";
          };
          expr = "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket{route!~\"(?i).*tail.*\"}[5m])) by (namespace, job, route, le)) > 1";
          for = "5m";
          labels = {
            severity = "critical";
          };
        }
      ];
    }
  ];
}
