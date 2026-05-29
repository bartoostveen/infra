{ config, lib, ... }:

let
  port = 29328;

  inherit (lib) mkIf;

  cfg = config.infra.matrix;
in
{
  imports = [
    ../mautrix-signal-go.nix
  ];

  config = mkIf (cfg.enable && cfg.signal.enable) {
    services.mautrix-signal-go = {
      enable = true;
      environmentFile = config.sops.secrets.mautrix-signal-env.path;
      setupPostgres = true;
      settings = {
        appservice = {
          address = "http://localhost:${toString port}";
          async_transactions = false;
          bot = {
            avatar = "mxc://maunium.net/wPJgTQbZOtpBFmDNkiNEMDUp";
            displayname = "Signal bridge bot";
            username = "signalbot";
          };
          ephemeral_events = true;
          hostname = "127.0.0.1";
          id = "signal";
          inherit port;
          # public_address = "https://bridge.example.com";
          username_template = "signal_{{.}}";
        };
        backfill = {
          enabled = true;
          max_catchup_messages = 500;
          max_initial_messages = 50;
          queue = {
            batch_delay = 20;
            batch_size = 100;
            enabled = false;
            max_batches = -1;
            max_batches_override = { };
          };
          threads.max_initial_messages = 50;
          unread_hours_threshold = 720;
        };
        bridge = {
          async_events = false;
          bridge_matrix_leave = false;
          bridge_notices = false;
          bridge_status_notices = "errors";
          cleanup_on_logout.enabled = false;
          command_prefix = "!signal";
          cross_room_replies = false;
          deduplicate_matrix_messages = false;
          enable_send_state_requests = false;
          kick_matrix_users = true;
          mute_only_on_create = true;
          no_bridge_info_state_key = false;
          only_bridge_tags = [
            "m.favourite"
            "m.lowpriority"
          ];
          permissions = {
            "*" = "relay";
            "@bart:bartoostveen.nl" = "admin";
            "bartoostveen.nl" = "user";
          };
          personal_filtering_spaces = true;
          portal_create_filter = {
            always_deny_from_login = [ ];
            list = [ ];
            mode = "deny";
          };
          private_chat_portal_meta = true;
          relay.enabled = false;
          resend_bridge_info = false;
          revert_failed_state_changes = false;
          split_portals = false;
          tag_only_on_create = true;
          unknown_error_max_auto_reconnects = 10;
        };
        direct_media.enabled = false;
        encryption.allow = false;
        env_config_prefix = "MAUTRIX_SIGNAL_";
        homeserver = {
          address = "https://${config.infra.matrix.domain}:443";
          async_media = false;
          domain = config.infra.matrix.fqdn;
          ping_interval_seconds = 0;
          software = "standard";
          websocket = false;
        };
        logging = {
          min_level = "debug";
          writers = [
            {
              format = "pretty-colored";
              type = "stdout";
            }
          ];
        };
        matrix = {
          delivery_receipts = true;
          federate_rooms = false;
          ghost_extra_profile_info = false;
          message_error_notices = true;
          message_status_events = false;
          sync_direct_chat_list = true;
          upload_file_threshold = 5242880;
        };
        network = {
          device_name = "mautrix-signal";
          disappear_view_once = false;
          displayname_template = "{{or .ContactName .ProfileName .PhoneNumber \"Unknown user\"}}";
          extev_polls = false;
          location_format = "https://www.google.com/maps/place/%[1]s,%[2]s";
          note_to_self_avatar = "mxc://maunium.net/REBIVrqjZwmaWpssCZpBlmlL";
          number_in_topic = true;
          sync_contacts_on_startup = true;
          use_contact_avatars = true;
          use_outdated_profiles = false;
        };
        provisioning.shared_secret = "disable";
        public_media.enabled = false;
      };
    };

    systemd.services.mautrix-signal.wants = [ "continuwuity.service" ];
    systemd.services.mautrix-signal.after = [ "continuwuity.service" ];

    infra.backup.jobs.state.paths = [ config.services.mautrix-signal-go.dataDir ];

    sops.secrets.mautrix-signal-env = {
      format = "binary";
      owner = "mautrix-signal";
      group = "mautrix-signal";
      sopsFile = ../../../secrets/mautrix/mautrix-signal.env.bart-server.secret;
      mode = "0600";
      restartUnits = [ "mautrix-signal.service" ];
    };
  };
}
