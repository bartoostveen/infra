{ lib, wireguard, ... }:

let
  inherit (lib)
    mkOption
    types
    mkEnableOption
    mkDefault
    concatStringsSep
    optionalString
    ;

  inherit (types)
    attrsOf
    submodule
    bool
    int
    nullOr
    ;

  reqLimitZoneName = "reqlimit";
  connLimitZoneName = "connlimit";

  rateLimitModule = global: {
    enable = mkOption {
      type = if global then bool else nullOr bool;
      default = if global then true else null;
      description = "Enable${optionalString global " global"} rate limiting for this ${
        if global then "vhost" else "location"
      }";
    };
    burst = mkOption {
      type = if global then int else nullOr int;
      default = if global then 100 else null;
      description = "max burst size before dropping requests that arrive too quickly";
    };
  };

  connectionLimitModule = global: {
    enable = mkOption {
      type = if global then bool else nullOr bool;
      default = if global then true else null;
      description = "Enable${optionalString global " global"} connection limiting for this ${
        if global then "vhost" else "location"
      }";
    };
    connections = mkOption {
      type = if global then int else nullOr int;
      default = if global then 200 else null;
      description = "max allowed connections before dropping connections that are initiated too quickly";
    };
  };

  either = a: b: if a == null then b else a;
in
{
  options.services.nginx.virtualHosts = mkOption {
    type = attrsOf (
      submodule (
        { config, ... }:

        {
          options = {
            rateLimit = rateLimitModule true;
            connectionLimit = connectionLimitModule true;
            enableHSTS = mkEnableOption "HSTS";
            locations = mkOption {
              type = attrsOf (
                submodule (
                  let
                    globalConfig = config;
                  in
                  { config, ... }:

                  {
                    options = {
                      rateLimit = rateLimitModule false;
                      connectionLimit = connectionLimitModule false;
                    };

                    config.extraConfig =
                      optionalString (either config.rateLimit.enable globalConfig.rateLimit.enable) ''
                        limit_req zone=${reqLimitZoneName} burst=${toString (either config.rateLimit.burst globalConfig.rateLimit.burst)} nodelay;
                      ''
                      + optionalString (either config.connectionLimit.enable globalConfig.connectionLimit.enable) ''
                        limit_conn ${connLimitZoneName} ${toString (either config.connectionLimit.connections globalConfig.connectionLimit.connections)};
                      '';
                  }
                )
              );
            };
          };
          config = {
            extraConfig = optionalString config.enableHSTS ''
              add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            '';
            kTLS = mkDefault false;
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
    limit_conn_log_level warn;
    limit_conn_status    429;

    limit_req_zone $limit zone=${reqLimitZoneName}:10m rate=20r/s;
    limit_req_log_level warn;
    limit_req_status     429;
  '';
}
