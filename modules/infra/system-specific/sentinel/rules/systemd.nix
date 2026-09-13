{
  groups = [
    {
      name = "SystemdExporter";
      rules = [
        {
          alert = "MountNotActive";
          annotations = {
            description = ''
              Systemd mount unit {{ $labels.name }} is not active
              Expected state 'active', actual state: {{ $labels.state }}
            '';
            summary = "Mount {{ $labels.name }} not active ({{ $labels.state }})";
          };
          expr = ''systemd_unit_state{type = "mount", name != "run-initramfs.mount", state != "active"} == 1'';
          for = "1m";
          labels.severity = "warning";
        }
      ];
    }
  ];
}
