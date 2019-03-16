{ config, ... }:

{
  imports = [ ./configuration.nix ];
  config.variables.useSSL = true;
  config.variables.myFQDN = "mail.warnochwas.de";
  config.variables.myDomain = "warnochwas.de";
  config.variables.mailAdmin = "test@warnochwas.de";
}
