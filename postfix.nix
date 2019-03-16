{ config, pkgs, ... }:

let
  pfvirtual_mailbox_domains = pkgs.writeText "virtual_mailbox_domains.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT domain FROM domain WHERE domain='%s' AND active = '1'
  '';
  pfvirtual_alias_maps = pkgs.writeText "virtual_alias_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias WHERE address='%s' AND active = '1'
  '';
  pfvirtual_alias_domain_maps = pkgs.writeText "virtual_alias_domain_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = ('%u' || '@' || alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
  '';
  pfvirtual_alias_domain_catchall_maps = pkgs.writeText "virtual_alias_domain_catchall_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = ('@' || alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
  '';
  pfvirtual_mailbox_maps = pkgs.writeText "virtual_mailbox_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT maildir FROM mailbox WHERE username='%s' AND active = '1'
  '';
  pfvirtual_alias_domain_mailbox_maps = pkgs.writeText "virtual_alias_domain_mailbox_maps.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '%d' and mailbox.username = ('%u' || '@' || alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
  '';
in
{
  # Configure Postfix to support SQLite
  nixpkgs.config.packageOverrides = pkgs: { postfix = pkgs.postfix.override { withSQLite = true; }; };
  # Configure the certificates...
  security.acme.certs."postfix.${config.variables.myFQDN}" = {
    domain = "${config.variables.myFQDN}";
    user = config.services.nginx.user;
    group = config.services.postfix.group;
    allowKeysForGroup = true;
    postRun = "systemctl restart postfix.service";
    # cheat by getting the webroot from another certificate configured through nginx.
    webroot = config.security.acme.certs."${config.variables.myFQDN}".webroot;
  };
  # Make sure at least the self-signed certs are available before trying to start postfix
  systemd.services.postfix.after = [ "acme-selfsigned-certificates.target" ];
  # Setup Postfix
  networking.firewall.allowedTCPPorts = [ 25 587 ];
  services.postfix = {
    enable = true;
    enableSmtp = true;
    enableSubmission = true;
    config = {
      mynetworks_style = "host";
      relay_domains = "";
      smtpd_sasl_type = "dovecot";
      smtpd_tls_chain_files = "/var/lib/acme/postfix.${config.variables.myFQDN}/full.pem";
      virtual_mailbox_domains = "proxy:sqlite:${pfvirtual_mailbox_domains}";
      virtual_alias_maps = "proxy:sqlite:${pfvirtual_alias_maps}, proxy:sqlite:${pfvirtual_alias_domain_maps}, proxy:sqlite:${pfvirtual_alias_domain_catchall_maps}";
      virtual_mailbox_maps = "proxy:sqlite:${pfvirtual_mailbox_maps}, proxy:sqlite:${pfvirtual_alias_domain_mailbox_maps}";
      virtual_transport = "lmtp:unix:/run/dovecot2/dovecot-lmtp";
    };
    extraAliases = ''
      root: ${config.variables.mailAdmin}
      '';
  };
}
