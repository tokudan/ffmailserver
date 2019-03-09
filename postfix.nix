{ config, pkgs, ... }:

let
  pfDomainSQL = pkgs.writeText "pfDomainSQL.cf" ''
    dbpath = ${config.variables.pfadminDataDir}/postfixadmin.db
    query = SELECT domain FROM domain WHERE domain='%s' AND active = '1'
  '';
in
{
  # Setup Postfix
  # networking.firewall.allowedTCPPorts = [ 80 ];
  services.postfix = {
    enable = true;
    enableSmtp = true;
    enableSubmission = true;
    config = {
      virtual_mailbox_domains = "proxy:sqlite:${pfDomainSQL}";
      virtual_alias_maps = "proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf";
      virtual_mailbox_maps = "proxy:mysql:/etc/postfix/sql/mysql_virtual_mailbox_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf";
    };
  };
}
