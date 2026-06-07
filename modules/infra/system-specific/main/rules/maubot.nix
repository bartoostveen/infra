{
  groups = [
    {
      name = "maubot";
      rules = [
        {
          alert = "BotNotEnabled";
          annotations = {
            description = "Bot {{ $labels.bot_id }} is not enabled";
            summary = "Bot is not enabled";
          };
          expr = "maubot_client_enabled{bot_id!~\".*\"} == 0";
          for = "5m";
          labels.severity = "warning";
        }
        {
          alert = "BotNotStarted";
          annotations = {
            description = "Bot {{ $labels.bot_id }} is not started";
            summary = "Bot is not started";
          };
          expr = "maubot_client_started{bot_id!~\".*\"} == 0";
          for = "5m";
          labels.severity = "warning";
        }
        {
          alert = "BotNotOnline";
          annotations = {
            description = "Bot {{ $labels.bot_id }} is not online";
            summary = "Bot is not online";
          };
          expr = "maubot_client_online{bot_id!~\".*\"} == 0";
          for = "5m";
          labels.severity = "warning";
        }
        {
          alert = "BotHasDisabledInstances";
          annotations = {
            description = "There are {{ $value }} disabled instance(s) for {{ $labels.bot_id }}";
            summary = "Bot has disabled instances";
          };
          expr = "(maubot_client_total_instances - maubot_client_enabled_instances) > 0";
          for = "5m";
          labels.severity = "warning";
        }
      ];
    }
  ];
}
