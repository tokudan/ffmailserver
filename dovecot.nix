{ config, pkgs, ... }:

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

    ssl = no
    #ssl_cert = </etc/dovecot/private/dovecot.pem
    #ssl_key = </etc/dovecot/private/dovecot.pem

    disable_plaintext_auth = no

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

    service lmtp {
      unix_listener /run/dovecot2/dovecot-lmtp {
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
  # Setup dovecot
  # networking.firewall.allowedTCPPorts = [ 80 ];
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
