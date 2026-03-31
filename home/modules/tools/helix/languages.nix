{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bash-language-server
    nixfmt
    shellcheck
    nil # nix
    pyright # python type checking
    ruff # python linting + formatting
    taplo # toml
    yaml-language-server # yaml + cloudformation
    vscode-langservers-extracted # json, html, css
    marksman # markdown
    # PowerShell Editor Services has no clean nixpkgs derivation.
    # Run `pwsh -Command "Install-Module PowerShellEditorServices"` manually
    # if PowerShell LSP is needed, then add the server config below.
  ];

  home.file.".config/helix/languages.toml" = {
    text = ''
      # NIX
      [language-server.nil]
      command = "nil"

      [[language]]
      name             = "nix"
      language-servers = ["nil"]
      formatter        = { command = "nixfmt" }
      auto-format      = true

      # PYTHON
      [language-server.pyright]
      command = "pyright-langserver"
      args    = ["--stdio"]

      [language-server.pyright.config]
      python.analysis.typeCheckingMode = "basic"
      python.analysis.autoSearchPaths  = true
      python.analysis.diagnosticMode   = "workspace"

      [language-server.ruff]
      command = "ruff"
      args    = ["server"]

      [[language]]
      name             = "python"
      language-servers = ["pyright", "ruff"]
      formatter        = { command = "ruff", args = ["format", "-"] }
      auto-format      = true

      # BASH + ZSH (bash-language-server handles both)
      [language-server.bash-language-server]
      command = "bash-language-server"
      args    = ["start"]

      [[language]]
      name             = "bash"
      language-servers = ["bash-language-server"]
      file-types       = [
        "sh", "bash", "zsh", "ash", "ebuild", "eclass",
        "env", "install", "profile", "PKGBUILD",
        { glob = ".bash_login" }, { glob = ".bash_logout" },
        { glob = ".bash_profile" }, { glob = ".bashrc" },
        { glob = ".bash_aliases" }, { glob = ".profile" },
        { glob = ".zshrc" }, { glob = ".zshenv" },
        { glob = ".zprofile" }, { glob = ".zlogin" },
        { glob = ".zlogout" }, { glob = "/etc/profile" },
        { glob = "/etc/bash.bashrc" }, { glob = "/etc/zshrc" },
      ]

      # TOML
      [language-server.taplo]
      command = "taplo"
      args    = ["lsp", "stdio"]

      [[language]]
      name             = "toml"
      language-servers = ["taplo"]
      formatter        = { command = "taplo", args = ["fmt", "-"] }
      auto-format      = true

      # JSON
      [language-server.vscode-json-language-server]
      command = "vscode-json-language-server"
      args    = ["--stdio"]

      [language-server.vscode-json-language-server.config]
      provideFormatter = true
      json.validate.enable = true

      [[language]]
      name             = "json"
      language-servers = ["vscode-json-language-server"]
      auto-format      = true

      [[language]]
      name             = "jsonc"
      language-servers = ["vscode-json-language-server"]
      auto-format      = true

      # YAML + AWS CloudFormation schema validation
      [language-server.yaml-language-server]
      command = "yaml-language-server"
      args    = ["--stdio"]

      [language-server.yaml-language-server.config.yaml]
      format.enable   = true
      validation      = true
      completion      = true
      hover           = true

      [language-server.yaml-language-server.config.yaml.schemas]
      "https://raw.githubusercontent.com/awslabs/goformation/master/schema/cloudformation.schema.json" = [
        "/*stack*.yaml", "/*stack*.yml",
        "/cloudformation/**/*.yaml", "/cloudformation/**/*.yml",
        "/*template*.yaml", "/*template*.yml",
      ]
      "https://json.schemastore.org/github-workflow.json"    = ".github/workflows/*.{yml,yaml}"
      "https://json.schemastore.org/github-action.json"      = ".github/actions/**/*.{yml,yaml}"
      "https://json.schemastore.org/docker-compose.json"     = "docker-compose*.{yml,yaml}"
      "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "compose*.{yml,yaml}"

      [[language]]
      name             = "yaml"
      language-servers = ["yaml-language-server"]
      auto-format      = true

      # MARKDOWN
      [language-server.marksman]
      command = "marksman"
      args    = ["server"]

      [[language]]
      name             = "markdown"
      language-servers = ["marksman"]
    '';
  };
}
