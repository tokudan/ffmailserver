{ config, lib, pkgs, ... }:

let
  dovecotSQL = pkgs.writeText "dovecot-sql.conf" ''
    driver = sqlite
    connect = ${config.variables.pfadminDataDir}/postfixadmin.db
    password_query = SELECT username AS user, password FROM mailbox WHERE username = '%Lu' AND active='1'
    user_query = SELECT username AS user FROM mailbox WHERE username = '%Lu' AND active='1'
  '';
  dovecotConf = pkgs.writeText "dovecot.conf" ''
    default_internal_user = dovecot2
    default_internal_group = dovecot2
    protocols = imap lmtp pop3

    ${lib.optionalString (config.variables.useSSL) ''
        ssl = yes
        ssl_cert = </var/lib/acme/dovecot2.${config.variables.myFQDN}/fullchain.pem
        ssl_key = </var/lib/acme/dovecot2.${config.variables.myFQDN}/key.pem
      ''
    }

    disable_plaintext_auth = no
    auth_mechanisms = plain login

    userdb {
        driver = sql
        args = ${dovecotSQL}
    }
    passdb {
        driver = sql
        args = ${dovecotSQL}
    }
    mail_home = ${config.variables.vmailBaseDir}/%Lu/
    mail_location = maildir:${config.variables.vmailBaseDir}/%Lu/Maildir
    mail_uid = ${toString config.variables.vmailUID}
    mail_gid = ${toString config.variables.vmailGID}

    service auth {
      unix_listener ${config.variables.dovecotAuthSocket} {
        user = ${config.services.postfix.user}
        group = ${config.services.postfix.group}
        mode = 0600
      }
    }

    service lmtp {
      unix_listener ${config.variables.dovecotLmtpSocket} {
        user = ${config.services.postfix.user}
        group = ${config.services.postfix.group}
        mode = 0600
      }
    }

    namespace inbox {
      inbox = yes
      location =
      mailbox Drafts {
        special_use = \Drafts
      }
      mailbox Junk {
        special_use = \Junk
      }
      mailbox Sent {
        special_use = \Sent
      }
      mailbox "Sent Messages" {
        special_use = \Sent
      }
      mailbox Trash {
        special_use = \Trash
      }
      mailbox Archive {
        special_use = \Archive
      }
      prefix =
    }
  '';
in
{
  # Configure certificates...
  security = lib.mkIf config.variables.useSSL {
    acme.certs."dovecot2.${config.variables.myFQDN}" = {
      domain = "${config.variables.myFQDN}";
      user = config.services.nginx.user;
      group = config.services.dovecot2.group;
      allowKeysForGroup = true;
      postRun = "systemctl restart dovecot2.service";
      # cheat by getting the webroot from another certificate configured through nginx.
      webroot = config.security.acme.certs."${config.variables.myFQDN}".webroot;
    };
  };
  # Make sure at least the self-signed certs are available before trying to start postfix
  systemd.services.dovecot2.after = lib.mkIf config.variables.useSSL [ "acme-selfsigned-certificates.target" ];
  # Setup dovecot
  networking.firewall.allowedTCPPorts = [ 110 143 993 995 ];
  services.dovecot2 = {
    enable = true;
    configFile = "${dovecotConf}";
  };
  systemd.services."vmail-setup" = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
      script = ''
        mkdir -p ${config.variables.vmailBaseDir}
        chown -c ${config.variables.vmailUser}:${config.variables.vmailGroup} ${config.variables.vmailBaseDir}
        chmod -c 0700 ${config.variables.vmailBaseDir}
      '';
  };
}
