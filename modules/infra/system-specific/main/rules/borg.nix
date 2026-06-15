{
  groups = [
    {
      name = "borg";
      rules = [
        {
          alert = "BorgBackupRunningTooLong";
          annotations = {
            description = "{{ $labels.name }} has been running for {{ $value }} seconds";
            summary = "Borg job running too long";
          };
          expr = ''
            (
              time() - systemd_unit_active_enter_time_seconds{name=~\"borgbackup-.*\\\\.service\"}
            ) * on(name) group_left()
            (
              systemd_unit_state{
                name=~\"borgbackup-.*\\\\.service\",
                state=\"active\"
              } == 1
            ) > 7200
          '';
          for = "1m";
          labels = {
            severity = "warning";
          };
        }
      ];
    }
  ];
}
