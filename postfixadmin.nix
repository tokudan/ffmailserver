{ config, lib, pkgs, ... }:

let
  postfixadminpkg = (pkgs.callPackage ./pkg-postfixadmin.nix {
    config = (pkgs.writeText "postfixadmin-config.local.php" ''
      <?php
      $CONF['configured'] = true;
      $CONF['setup_password'] = 'b7cfa08c8546a0019a6251252144ca61:c90d645bc2de7302feb9702bb4da32d22412bae9';
      $CONF['database_type'] = 'sqlite';
      $CONF['database_name'] = '${dataDir}/postfixadmin.db';
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
        'abuse' => 'abuse@hamburg.freifunk.net',
        'hostmaster' => 'kontakt@hamburg.freifunk.net',
        'postmaster' => 'kontakt@hamburg.freifunk.net',
        'webmaster' => 'kontakt@hamburg.freifunk.net'
      );
      $CONF['footer_text'] = "";
      $CONF['footer_link'] = "";
      ?>
    '');
    cacheDir = "${cacheDir}";
  } );
  phppoolName = "postfixadmin_pool";
  cacheDir = "/var/cache/postfixadmin";
  dataDir = "/var/lib/postfixadmin";
  pfauser = "pfa";
  pfagroup = "pfa";
in
{
  # Setup the user and group
  users.groups."${pfagroup}" = { };
  users.users."${pfauser}" = {
    isSystemUser = true;
    group = "${pfagroup}";
    description = "PHP User for postfixadmin";
  };

  # Setup nginx
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx.enable = true;
  services.nginx.virtualHosts."mailtest" = {
    forceSSL = false;
    enableACME = false;
    default = true;
    root = "${postfixadminpkg}/public";
    extraConfig = ''
      access_log /tmp/nginx/log/$host combined;
      charset utf-8;

      etag off;
      add_header etag "\"${builtins.substring 11 32 postfixadminpkg}\"";

      index index.php;

      # block these file types
      #location ~* \.(tpl|md|tgz|log|out|tar|gz|db)$ {
        #deny all;
      #}

      # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
      # or a unix socket
      location ~* \.php$ {
        # Zero-day exploit defense.
        # http://forum.nginx.org/read.php?2,88845,page=3
        # Won't work properly (404 error) if the file is not stored on this
        # server, which is entirely possible with php-fpm/php-fcgi.
        # Comment the 'try_files' line out if you set up php-fpm/php-fcgi on
        # another machine.  And then cross your fingers that you won't get hacked.
        try_files $uri =404;
        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        # With php5-cgi alone:
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx;
        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
        fastcgi_param  HTTP_PROXY         "";
      }
    '';
  };
  systemd.services."postfixadmin-setup" = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    script = ''
      # Setup the data directory with the database and the cache directory
      mkdir -p ${dataDir}
      chmod -c 751 ${dataDir}
      chown -c ${pfauser}:${pfagroup} ${dataDir}

      mkdir -p ${cacheDir}/templates_c
      chown -Rc ${pfauser}:${pfagroup} ${cacheDir}/templates_c
      chmod -Rc 751 ${cacheDir}/templates_c
    '';
  };
  services.phpfpm.pools."${phppoolName}" = {
    listen = "127.0.0.1:9000"; 
    extraConfig = ''
      user = ${pfauser}
      pm = dynamic
      pm.max_children = 75
      pm.min_spare_servers = 5
      pm.max_spare_servers = 20
      pm.max_requests = 10
      catch_workers_output = 1
      php_admin_value[upload_max_filesize] = 42M
      php_admin_value[post_max_size] = 42M
      php_admin_value[memory_limit] = 128M
      php_admin_value[cgi.fix_pathinfo] = 1
    '';
  };
}
