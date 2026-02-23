{ config, ... }:

{
  sops.secrets.nm-env = {
    owner = "root";
    group = "root";
    mode = "0600";

    sopsFile = ../../secrets/non-infra/nm-env.secret;
    format = "binary";
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [
      config.sops.secrets.nm-env.path
    ];

    profiles = {
      "; DROP TABLE WIFI; --" = {
        connection = {
          id = "; DROP TABLE WIFI; --";
          interface-name = "wlp0s20f3";
          permissions = "user:bart:;";
          type = "wifi";
          uuid = "7bf4ea33-f403-4bfe-bca0-6b7cd8a71e6d";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          mtu = "1280";
          ssid = "\\\\; DROP TABLE WIFI\\\\; --";
        };
        wifi-security = {
          key-mgmt = "sae";
          leap-password-flags = "1";
          psk = "$HOME_WIFI_PSK";
          psk-flags = "1";
          wep-key-flags = "1";
        };
      };
      H369A8D363E = {
        connection = {
          id = "H369A8D363E";
          interface-name = "wlp0s20f3";
          type = "wifi";
          uuid = "617d2645-9f1b-4955-9144-7502db7bc203";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          ssid = "H369A8D363E";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-psk";
          psk = "$H369A8D363E";
        };
      };
      "Bart's Nothing Phone (2a)" = {
        connection = {
          id = "Bart's Nothing Phone (2a)";
          interface-name = "wlp0s20f3";
          permissions = "user:bart:;";
          type = "wifi";
          uuid = "5d0a5831-8014-4a1a-b622-af6ec194e9ff";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          mtu = "1280";
          ssid = "Bart's Nothing Phone (2a)";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "sae";
          leap-password-flags = "1";
          psk = "$PHONE_HOTSPOT_PSK";
          psk-flags = "1";
          wep-key-flags = "1";
        };
      };
      eduroam-9e3b23c0-83f6-437a-b599-c875d7caee5d = {
        "802-1x" = {
          anonymous-identity = "anonymous@utwente.nl";
          ca-cert = "/etc/ssl/certs/ca-bundle.crt";
          domain-suffix-match = "utwente.nl";
          eap = "ttls;";
          identity = "b.oostveen@student.utwente.nl";
          password = "$EDUROAM_UNIVERSITY_PASSWORD";
          phase2-autheap = "mschapv2";
        };
        connection = {
          id = "eduroam";
          interface-name = "wlp0s20f3";
          type = "wifi";
          uuid = "9e3b23c0-83f6-437a-b599-c875d7caee5d";
        };
        ipv4 = {
          method = "auto";
        };
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        proxy = { };
        wifi = {
          mode = "infrastructure";
          ssid = "eduroam";
        };
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-eap";
        };
      };
    };
  };
}
