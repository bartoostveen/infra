{
  groups = [
    {
      name = "tlsa";
      rules = [
        {
          alert = "TLSARecordFetchFailed";
          annotations = {
            description = "TLSA record {{ $labels.record }} could not be retrieved or is invalid.";
            summary = "TLSA record fetch failed for {{ $labels.record }}";
          };
          expr = "mtce_tlsa_status == 0";
          for = "1m";
          labels.severity = "critical";
        }
        {
          alert = "SMTPServerDown";
          annotations = {
            description = "SMTP server {{ $labels.hostname }} is unreachable over {{ $labels.ip }}.";
            summary = "SMTP server down ({{ $labels.hostname }} over {{ $labels.ip }})";
          };
          expr = "mtce_smtp_status == 0";
          for = "1m";
          labels.severity = "critical";
        }
        {
          alert = "SMTPCertificateInvalid";
          annotations = {
            description = ''
              The SMTP certificate presented by {{ $labels.hostname }} over {{ $labels.ip }} does not match the expected TLSA record (digest mismatch).


              TLSA digest:               {{ $labels.tlsa_digest }}
              Actual certificate digest: {{ $labels.cert_digest }}
            '';
            summary = "Invalid SMTP certificate for {{ $labels.hostname }} ({{ $labels.ip }})";
          };
          expr = "mtce_smtp_cert_status == 0";
          for = "1m";
          labels.severity = "critical";
        }
      ];
    }
  ];
}
