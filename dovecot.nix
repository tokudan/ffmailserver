{ config, lib, pkgs, ... }:

let
  pfadataDir = "/var/lib/postfixadmin";
  pfauser = "pfa";
  pfagroup = "pfa";
  dovecotSQL = pkgs.writeText "dovecot-sql.conf" ''
    driver = sqlite
    connect = ${pfadataDir}/postfixadmin.db
    password_query = SELECT username AS user, password FROM mailbox WHERE username = '%u' AND active='1'
    user_query = SELECT maildir, 1001 AS uid, 1001 AS gid FROM mailbox WHERE username = '%u' AND active='1'
  '';
  dovecotConf = pkgs.writeText "dovecot.conf" ''
    passdb {
      args = ${dovecotSQL}
      driver = sql
    }
  '';
in
{
  # Setup the user and group
  #users.groups."${pfagroup}" = { };
  #users.users."${pfauser}" = {
  #  isSystemUser = true;
  #  group = "${pfagroup}";
  #  description = "PHP User for postfixadmin";
  #};

  # Setup dovecot
  # networking.firewall.allowedTCPPorts = [ 80 ];
  services.dovecot2 = {
    enable = true;
    #configFile = dovecotConf;
  };
}
