{ config, ... }:

{
  imports = [ ./configuration.nix ];
  config.variables.useSSL = false;
  config.networking.hostName = "mailtest";
  config.networking.domain = "warnochwas.de";
  config.variables.mailAdmin = "postmaster@warnochwas.de";
}
