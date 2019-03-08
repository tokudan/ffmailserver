{ config, pkgs, ... }:

{
  # Import some configuration as they are too long to be easily readable here
  imports = [ 
    ./dovecot.nix
    # ./postfix.nix
    ./postfixadmin.nix
  ];
}
