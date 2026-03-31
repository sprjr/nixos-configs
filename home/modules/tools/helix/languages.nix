{ config, pkgs, home-manager, ... }:

{
  home.packages = with pkgs; [
    bash-language-server
    nixfmt-rfc-style
    shellcheck
  ];

  home.file.".config/helix/languages.toml" = {
    text = ''
      [[language]]
      name       = "nix"
      formatter  = { command = "nixfmt" }
      auto-format = true

      [[language]]
      name = "bash"
      language-servers = ["bash-language-server"]

      [language-server.bash-language-server]
      command = "bash-language-server"
      args    = ["start"]
    '';
  };
}
