{ lib, wireguard, ... }:

let
  inherit (lib)
    mkOption
    types
    mkIf
    mkAfter
    mkEnableOption
    concatStringsSep
    ;

  inherit (types)
    attrsOf
    submodule
    bool
    int
    ;

  reqLimitZoneName = "reqlimit";
  connLimitZoneName = "connlimit";
in
{
  options.services.nginx.virtualHosts = mkOption {
    type = attrsOf (
      submodule (
        { config, ... }:
        {
          options = {
            enableRateLimit = mkOption {
              type = bool;
              default = true;
              description = "Enable global rate limiting for this vhost";
            };
            enableHSTS = mkEnableOption "HSTS";
            locations = mkOption {
              type = attrsOf (
                submodule (
                  let
                    global = config.enableRateLimit;
                  in
                  { config, ... }:
                  {
                    options.rateLimit = {
                      enable = mkOption {
                        type = bool;
                        default = true;
                        description = "Enable global rate limiting for this location";
                      };
                      burst = mkOption {
                        type = int;
                        default = 100;
                        description = "max burst size before dropping requests that arrive too quickly";
                      };
                    };

                    config = mkIf (global && config.rateLimit.enable) {
                      extraConfig = mkAfter ''
                        limit_req zone=${reqLimitZoneName} burst=${toString config.rateLimit.burst} nodelay;
                      '';
                    };
                  }
                )
              );
            };
          };
          config = mkIf config.enableHSTS {
            extraConfig = mkAfter ''
              add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            '';
          };
        }
      )
    );
  };
  config.services.nginx.commonHttpConfig = ''
    geo $whitelist {
      default 0;
      127.0.0.0/24 1;
      10.0.0.0/8 1;
      ${wireguard.connectivity.allRanges |> map (range: "${range} 1;") |> concatStringsSep "\n"}
    }

    map $whitelist $limit {
      0 $binary_remote_addr;
      1 "";
    }

    limit_conn_zone      $limit    zone=${connLimitZoneName}:10m;
    limit_conn           ${connLimitZoneName} 1000;
    limit_conn_log_level warn;
    limit_conn_status    429;

    limit_req_zone $limit zone=${reqLimitZoneName}:10m rate=20r/s;
    limit_req_log_level warn;
    limit_req_status     429;
  '';
}
