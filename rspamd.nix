{ config, lib, pkgs, ... }:

{
  #networking.firewall.allowedTCPPorts = [ 110 143 993 995 ];
  services.rspamd = {
    enable = true;
    extraConfig = ''
      reject = null;
      '';
    workers = {
      controller = {
        enable = true;
        extraConfig = ''
          secure_ip = [::1]
        '';
        bindSockets = [ "[::1]:11334" ];
      };
      rspamd_proxy = {
        enable = true;
        type = "rspamd_proxy";
        count = 5; # TODO: match with postfix limits
        extraConfig = ''
          upstream "local" {
            self_scan = yes; # Enable self-scan
          }
        '';
        bindSockets = [
          { socket = config.variables.rspamdMilterSocket; mode = "0600"; owner = config.services.postfix.user; group = config.services.rspamd.group; }
        ];
      };
    };
  };
}
