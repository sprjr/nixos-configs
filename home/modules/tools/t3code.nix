{
  config,
  lib,
  pkgs,
  ...
}:

{
  # T3 Code harness, on-demand CLI only (no server unit)
  programs.t3code.enable = true;
}
