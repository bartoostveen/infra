{ pkgs, config, ... }:

# https://matrix.to/#/!bidWoOxEFhbEFuYgkl:lossy.network/$ZDfRMXzsMT4FRXsGsB0_SPluVaZaIws65bpIuwxPYGU?via=nixos.org&via=matrix.org&via=pub.solar
{
  services.postfix.settings.main.smtp_tls_CAfile =
    let
      cacert = pkgs.cacert.overrideAttrs (old: {
        patches = old.patches or [ ] ++ [
          # Partial revert of https://phabricator.services.mozilla.com/D288391 and just enough to work around Microsoft Outlook CA fuckup:
          # https://techcommunity.microsoft.com/blog/exchange/trust-digicert-global-root-g2-certificate-authority-to-avoid-exchange-online-ema/4488311
          (pkgs.writeText "Microsoft-Outlook-DigiCert-Global-Root-CA-2006.patch" ''
            diff --git a/certdata.txt b/certdata.txt
            index 97b118f68..13c4ad771 100644
            --- a/certdata.txt
            +++ b/certdata.txt
            @@ -1740,7 +1740,7 @@ CKA_SERIAL_NUMBER MULTILINE_OCTAL
             \002\020\010\073\340\126\220\102\106\261\241\165\152\311\131\221
             \307\112
             END
            -CKA_TRUST_SERVER_AUTH CK_TRUST CKT_NSS_MUST_VERIFY_TRUST
            +CKA_TRUST_SERVER_AUTH CK_TRUST CKT_NSS_TRUSTED_DELEGATOR
             CKA_TRUST_EMAIL_PROTECTION CK_TRUST CKT_NSS_TRUSTED_DELEGATOR
             CKA_TRUST_CODE_SIGNING CK_TRUST CKT_NSS_MUST_VERIFY_TRUST
             CKA_TRUST_STEP_UP_APPROVED CK_BBOOL CK_FALSE
          '')
        ];
      });
      cacertPackage = cacert.override {
        blacklist = config.security.pki.caCertificateBlacklist;
        extraCertificateFiles = config.security.pki.certificateFiles;
        extraCertificateStrings = config.security.pki.certificates;
      };
    in
    "${cacertPackage}/etc/ssl/certs/ca-bundle.crt";
}
