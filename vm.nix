{ config, ... }:

{
  imports = [ ./configuration.nix ];
  config.variables.useSSL = false;
  config.networking.hostName = "mailtest";
  config.networking.domain = "invalid";
  config.variables.mailAdmin = "postmaster@invalid";
}
