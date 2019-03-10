{ config, ... }:

{
  imports = [ ./configuration.nix ];
  config.variables.useSSL = false;
}
