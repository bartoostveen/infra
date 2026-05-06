{
  config,
  pkgs,
  ...
}:

{
  services.postfix.settings.main.bounce_template_file = pkgs.writeText "bounce-template.cf" ''
    failure_template = <<EOF
    Charset: utf-8
    From: MAILER-DAEMON (Mail Delivery System)
    Subject: Niet-bezorgde mail teruggestuurd naar afzender
    Postmaster-Subject: Postmaster Copy: Undelivered Mail

    Dit is het mailsysteem van ${config.mailserver.systemDomain}.

    Uw bericht kon niet worden afgeleverd aan één of meer
    ontvangers. Het bericht is bijgevoegd in de bijlage.

    Voor verdere hulp kunt u een mail sturen naar postmaster <at>
    ${config.mailserver.systemDomain}. Vergeet niet deze mail bij te voegen of door te
    sturen wanneer u dat doet.

                  Het mailsysteem
                  The mail system
    EOF

    delay_template = <<EOF
    Charset: utf-8
    From: MAILER-DAEMON (Mail Delivery System)
    Subject: Vertraagde mail (wordt nog opnieuw verzonden)
    Postmaster-Subject: Postmaster Warning: Delayed Mail

    Dit is het mailsysteem van ${config.mailserver.systemDomain}.

    #############################################################################
    # Dit is enkel een waarschuwing, u hoeft uw mail niet opnieuw te verzenden. #
    #############################################################################

    Uw bericht kon niet worden afgeleverd voor langer dan $delay_warning_time_hours uur.
    Het wordt opnieuw geprobeerd totdat de mail $maximal_queue_lifetime_days dag(en) oud
    is.

    Bedankt voor uw begrip.

    Voor verdere hulp kunt u een mail sturen naar postmaster <at>
    $myhostname. Vergeet niet deze mail bij te voegen of door te
    sturen wanneer u dat doet.

                       Het mailsysteem
                       The mail system
    EOF
  '';
}
