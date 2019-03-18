{ config, lib, pkgs, ... }:

{
  #networking.firewall.allowedTCPPorts = [ 110 143 993 995 ];
  services.rspamd = {
    enable = true;
    workers.rspamd_proxy = {
      enable = true;
      type = "rspamd_proxy";
      count = 5; # TODO: match with postfix limits
      bindSockets = [
        { socket = config.variables.rspamdMilterSocket; mode = "0600"; owner = config.services.postfix.user; group = config.services.rspamd.group; }
      ];
    };
  };
}
