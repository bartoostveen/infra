{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault;
in
{
  services.postfix.settings.main.bounce_template_file = mkDefault (
    pkgs.writeText "bounce-template.cf" ''
      failure_template = <<EOF
      Charset: us-ascii
      From: MAILER-DAEMON (Mail Delivery System)
      Subject: Undelivered Mail Returned to Sender
      Postmaster-Subject: Postmaster Copy: Undelivered Mail

      This is the mail system at host ${config.mailserver.systemDomain}.

      I'm sorry to have to inform you that your message could not
      be delivered to one or more recipients. It's attached below.

      For further assistance, please send a message to postmaster
      <at> ${config.mailserver.systemDomain}

      If you do so, please include this problem report.

                    The mail system
      EOF

      delay_template = <<EOF
      Charset: us-ascii
      From: MAILER-DAEMON (Mail Delivery System)
      Subject: Delayed Mail (still being retried)
      Postmaster-Subject: Postmaster Warning: Delayed Mail

      This is the mail system at host ${config.mailserver.systemDomain}.

      ####################################################################
      # THIS IS A WARNING ONLY.  YOU DO NOT NEED TO RESEND YOUR MESSAGE. #
      ####################################################################

      Your message could not be delivered for more than $delay_warning_time_hours hour(s).
      It will be retried until it is $maximal_queue_lifetime_days day(s) old.

                         The mail system
      EOF
    ''
  );
}
