{ config, ... }:

{
  imports = [ ./configuration.nix ];
  config.variables.useSSL = false;
  config.variables.myFQDN = "mailtest";
}
