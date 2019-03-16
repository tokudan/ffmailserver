{ config, lib, pkgs, ... }:

{
  options = {
    variables = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };
  config.variables = {
    pfadminDataDir = "/var/lib/postfixadmin";
    pfaUser = "pfadmin";
    pfaGroup = "pfadmin";
    vmailUser = "vmail";
    vmailUID = 10000;
    vmailGroup = "vmail";
    vmailGID = 10000;
    vmailBaseDir = "/var/vmail";
    useSSL = false;
    roundcubePhpfpmHostPort = "127.0.0.1:9001";
    roundcubeUser = "roundcube";
    roundcubeDataDir = "/var/lib/roundcube";
    pfaPhpfpmHostPort = "127.0.0.1:9000";
    dovecotUser = "dovecot2";
    dovecotGroup = "dovecot2";
    postfixadminpkgCacheDir = "/var/cache/postfixadmin";
    postfixadminpkg = (pkgs.callPackage ./pkg-postfixadmin.nix {
      config = (pkgs.writeText "postfixadmin-config.local.php" ''
        <?php
        $CONF['configured'] = true;
        $CONF['setup_password'] = 'b7cfa08c8546a0019a6251252144ca61:c90d645bc2de7302feb9702bb4da32d22412bae9';
        $CONF['database_type'] = 'sqlite';
        $CONF['database_name'] = '${config.variables.pfadminDataDir}/postfixadmin.db';
        $CONF['password_expiration'] = 'NO';
        $CONF['encrypt'] = 'dovecot:BLF-CRYPT';
        $CONF['dovecotpw'] = "${pkgs.dovecot}/bin/doveadm pw";
        $CONF['generate_password'] = 'YES';
        $CONF['show_password'] = 'NO';
        $CONF['quota'] = 'NO';
        $CONF['fetchmail'] = 'NO';
        $CONF['recipient_delimiter'] = "+";
        $CONF['forgotten_user_password_reset'] = false;
        $CONF['forgotten_admin_password_reset'] = false;
        $CONF['aliases'] = '0';
        $CONF['mailboxes'] = '0';
        $CONF['default_aliases'] = array (
          'abuse' => 'postmaster@${config.variables.myDomain}',
          'hostmaster' => 'postmaster@${config.variables.myDomain}',
          'postmaster' => 'postmaster@${config.variables.myDomain}',
          'webmaster' => 'postmaster@${config.variables.myDomain}'
        );
        $CONF['footer_text'] = "";
        $CONF['footer_link'] = "";
        ?>
      '');
      cacheDir = config.variables.postfixadminpkgCacheDir;
    } );
  };
}
