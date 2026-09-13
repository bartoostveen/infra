{
  groups = [
    {
      name = "up";
      rules = [
        {
          alert = "NotUp";
          expr = ''
            up == 0
          '';
          for = "1m";
          labels.severity = "warning";
          annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
        }
      ];
    }
  ];
}
