{
  groups = [
    {
      name = "PostgresExporter";
      rules = [
        {
          alert = "PostgresqlDown";
          annotations = {
            description = "Postgresql instance is down\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql down (instance {{ $labels.instance }})";
          };
          expr = "pg_up == 0";
          for = "1m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "PostgresqlRestarted";
          annotations = {
            description = "Postgresql restarted\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql restarted (instance {{ $labels.instance }})";
          };
          expr = "time() - pg_postmaster_start_time_seconds < 60";
          for = "0m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "PostgresqlExporterError";
          annotations = {
            description = "Postgresql exporter is showing errors. A query may be buggy in query.yaml\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql exporter error (instance {{ $labels.instance }})";
          };
          expr = "pg_exporter_last_scrape_error > 0";
          for = "0m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "PostgresqlTableNotAutoVacuumed";
          annotations = {
            description = "Table {{ $labels.relname }} has not been auto vacuumed for 10 days\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql table not auto vacuumed (instance {{ $labels.instance }})";
          };
          expr = "((pg_stat_user_tables_n_tup_del + pg_stat_user_tables_n_tup_upd + pg_stat_user_tables_n_tup_hot_upd) > pg_settings_autovacuum_vacuum_threshold) and (time() - pg_stat_user_tables_last_autovacuum) > 60 * 60 * 24 * 10";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlTableNotAutoAnalyzed";
          annotations = {
            description = "Table {{ $labels.relname }} has not been auto analyzed for 10 days\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql table not auto analyzed (instance {{ $labels.instance }})";
          };
          expr = "((pg_stat_user_tables_n_tup_del + pg_stat_user_tables_n_tup_upd + pg_stat_user_tables_n_tup_hot_upd) > pg_settings_autovacuum_analyze_threshold) and (time() - pg_stat_user_tables_last_autoanalyze) > 24 * 60 * 60 * 10";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlTooManyConnections";
          annotations = {
            description = "PostgreSQL instance has too many connections (> 80%).\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql too many connections (instance {{ $labels.instance }})";
          };
          expr = "sum by (instance, job, server) (pg_stat_activity_count) > min by (instance, job, server) (pg_settings_max_connections * 0.8)";
          for = "2m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlNotEnoughConnections";
          annotations = {
            description = "PostgreSQL instance should have more connections (> 5)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql not enough connections (instance {{ $labels.instance }})";
          };
          expr = "sum by (datname) (pg_stat_activity_count{datname!~\"template.*|postgres\"}) < 5";
          for = "2m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "PostgresqlDeadLocks";
          annotations = {
            description = "PostgreSQL has dead-locks ({{ $value }} in the last minute)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql dead locks (instance {{ $labels.instance }})";
          };
          expr = "increase(pg_stat_database_deadlocks{datname!~\"template.*|postgres\",datid!=\"0\"}[1m]) > 5";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlHighRollbackRate";
          annotations = {
            description = "Ratio of transactions being aborted compared to committed is > 2 %\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql high rollback rate (instance {{ $labels.instance }})";
          };
          expr = "sum by (namespace,datname,instance) (rate(pg_stat_database_xact_rollback{datname!~\"template.*|postgres\",datid!=\"0\"}[3m])) / (sum by (namespace,datname,instance) (rate(pg_stat_database_xact_rollback{datname!~\"template.*|postgres\",datid!=\"0\"}[3m])) + sum by (namespace,datname,instance) (rate(pg_stat_database_xact_commit{datname!~\"template.*|postgres\",datid!=\"0\"}[3m]))) > 0.02 and (sum by (namespace,datname,instance) (rate(pg_stat_database_xact_rollback{datname!~\"template.*|postgres\",datid!=\"0\"}[3m])) + sum by (namespace,datname,instance) (rate(pg_stat_database_xact_commit{datname!~\"template.*|postgres\",datid!=\"0\"}[3m]))) > 0";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlCommitRateLow";
          annotations = {
            description = "Postgresql seems to be processing very few transactions\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql commit rate low (instance {{ $labels.instance }})";
          };
          expr = "increase(pg_stat_database_xact_commit{datname!~\"template.*|postgres\",datid!=\"0\"}[5m]) < 5";
          for = "2m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "PostgresqlLowXidConsumption";
          annotations = {
            description = "Postgresql seems to be consuming transaction IDs very slowly\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql low XID consumption (instance {{ $labels.instance }})";
          };
          expr = "rate(pg_txid_current[1m]) < 5";
          for = "2m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlUnusedReplicationSlot";
          annotations = {
            description = "Unused Replication Slots\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql unused replication slot (instance {{ $labels.instance }})";
          };
          expr = "(pg_replication_slots_active == 0) and (pg_replication_is_replica == 0)";
          for = "1m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlTooManyDeadTuples";
          annotations = {
            description = "PostgreSQL dead tuples is too large\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql too many dead tuples (instance {{ $labels.instance }})";
          };
          expr = "((pg_stat_user_tables_n_dead_tup > 10000) / (pg_stat_user_tables_n_live_tup + pg_stat_user_tables_n_dead_tup)) >= 0.1 and (pg_stat_user_tables_n_live_tup + pg_stat_user_tables_n_dead_tup) > 0";
          for = "2m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlConfigurationChanged";
          annotations = {
            description = "Postgres Database configuration change has occurred\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql configuration changed (instance {{ $labels.instance }})";
          };
          expr = "{__name__=~\"pg_settings_.*\",__name__!=\"pg_settings_transaction_read_only\"} != ON(__name__, instance) {__name__=~\"pg_settings_.*\",__name__!=\"pg_settings_transaction_read_only\"} OFFSET 5m";
          for = "0m";
          labels = {
            severity = "info";
          };
        }
        {
          alert = "PostgresqlSslCompressionActive";
          annotations = {
            description = "Database allows connections with SSL compression enabled. This may add significant jitter in replication delay. Replicas should turn off SSL compression via `sslcompression=0` in `recovery.conf`.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql SSL compression active (instance {{ $labels.instance }})";
          };
          expr = "sum by (instance) (pg_stat_ssl_compression) > 0";
          for = "0m";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlTooManyLocksAcquired";
          annotations = {
            description = "Too many locks acquired on the database. If this alert happens frequently, we may need to increase the postgres setting max_locks_per_transaction.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql too many locks acquired (instance {{ $labels.instance }})";
          };
          expr = "((sum by (instance) (pg_locks_count)) / (pg_settings_max_locks_per_transaction * pg_settings_max_connections)) > 0.20 and (pg_settings_max_locks_per_transaction * pg_settings_max_connections) > 0";
          for = "2m";
          labels = {
            severity = "critical";
          };
        }
        {
          alert = "PostgresqlBloatIndexHigh(>80%)";
          annotations = {
            description = "The index {{ $labels.idxname }} is bloated. You should execute `REINDEX INDEX CONCURRENTLY {{ $labels.idxname }};`\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql bloat index high (> 80%) (instance {{ $labels.instance }})";
          };
          expr = "pg_bloat_btree_bloat_pct > 80 and on (idxname) (pg_bloat_btree_real_size > 100000000)";
          for = "1h";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlBloatTableHigh(>80%)";
          annotations = {
            description = "The table {{ $labels.relname }} is bloated. You should execute `VACUUM {{ $labels.relname }};`\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql bloat table high (> 80%) (instance {{ $labels.instance }})";
          };
          expr = "pg_bloat_table_bloat_pct > 80 and on (relname) (pg_bloat_table_real_size > 200000000)";
          for = "1h";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlInvalidIndex";
          annotations = {
            description = "The table {{ $labels.relname }} has an invalid index: {{ $labels.indexrelname }}. You should execute `DROP INDEX {{ $labels.indexrelname }};`\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql invalid index (instance {{ $labels.instance }})";
          };
          expr = "pg_general_index_info_pg_relation_size{indexrelname=~\".*ccnew.*\"}";
          for = "6h";
          labels = {
            severity = "warning";
          };
        }
        {
          alert = "PostgresqlReplicationLag";
          annotations = {
            description = "The PostgreSQL replication lag is high (> 5s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
            summary = "Postgresql replication lag (instance {{ $labels.instance }})";
          };
          expr = "pg_replication_lag_seconds > 5";
          for = "30s";
          labels = {
            severity = "warning";
          };
        }
      ];
    }
  ];
}
