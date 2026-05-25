{
  config,
  pkgs,
  lib,
  ...
}:

let
  port = 29317;

  inherit (lib) mkIf;

  cfg = config.infra.matrix;
in
{
  imports = [
    ../mautrix-telegram-go.nix
  ];

  config = mkIf (cfg.enable && cfg.telegram.enable) {
    services.mautrix-telegram-go = {
      enable = true;
      package = pkgs.local.mautrix-telegram-go;
      environmentFile = config.sops.secrets.mautrix-telegram-env.path;
      setupPostgres = true;
      settings = {
        appservice = {
          address = "http://localhost:${toString port}";
          async_transactions = false;
          bot = {
            avatar = "mxc://maunium.net/tJCRmUyJDsgRNgqhOgoiHWbX";
            displayname = "Telegram bridge bot";
            username = "telegrambot";
          };
          ephemeral_events = true;
          hostname = "127.0.0.1";
          id = "telegram";
          inherit port;
          # public_address = "https://bridge.example.com";
          username_template = "telegram_{{.}}";
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
          command_prefix = "!tg";
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
        env_config_prefix = "MAUTRIX_TELEGRAM_";
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
          always_custom_emoji_reaction = false;
          always_tombstone_on_supergroup_migration = true;
          animated_sticker = {
            args = {
              fps = 25;
              height = 256;
              width = 256;
            };
            convert_from_webm = false;
            target = "gif";
          };
          contact_avatars = true;
          contact_names = true;
          device_info = {
            app_version = "auto";
            device_model = "mautrix-telegram";
            lang_code = "en";
            system_lang_code = "en";
          };
          disable_view_once = false;
          image_as_file_pixels = 16777216;
          max_member_count = -1;
          member_list = {
            max_initial_sync = 100;
            skip_deleted = true;
            sync_broadcast_channels = false;
          };
          ping = {
            interval_seconds = 30;
            timeout_seconds = 10;
          };
          saved_message_avatar = "mxc://maunium.net/XhhfHoPejeneOngMyBbtyWDk";
          sync = {
            create_limit = 15;
            direct_chats = true;
            login_sync_limit = 15;
            update_limit = 100;
          };
          takeout = {
            backward_backfill = false;
            dialog_sync = false;
            forward_backfill = false;
          };
        };
        provisioning.shared_secret = "disable";
        public_media.enabled = false;
      };
    };

    systemd.services.mautrix-telegram.wants = [ "continuwuity.service" ];
    systemd.services.mautrix-telegram.after = [ "continuwuity.service" ];

    infra.backup.jobs.state.paths = [ config.services.mautrix-telegram-go.dataDir ];

    sops.secrets.mautrix-telegram-env = {
      format = "binary";
      owner = "mautrix-telegram";
      group = "mautrix-telegram";
      sopsFile = ../../../secrets/mautrix/mautrix-telegram.env.secret;
      mode = "0600";
      restartUnits = [ "mautrix-telegram.service" ];
    };
  };
}
