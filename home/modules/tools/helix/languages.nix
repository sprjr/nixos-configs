{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bash-language-server
    fish-lsp
    gopls
    harper
    nixd
    nixfmt
    shellcheck
    pyright # python type checking
    ruff # python linting + formatting
    taplo # toml
    yaml-language-server # yaml + cloudformation
    vscode-langservers-extracted # json, html, css
    marksman # markdown
    terraform-ls # hcl / terraform / opentofu
    shfmt # bash/shell formatter
    prettier # markdown formatter
  ];

  programs.helix.languages = {
    language-server = {
      nixd = { command = "nixd"; };

      pyright = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
        config.python.analysis = {
          typeCheckingMode = "basic";
          autoSearchPaths = true;
          diagnosticMode = "workspace";
        };
      };

      ruff = {
        command = "ruff";
        args = [ "server" ];
      };

      bash-language-server = {
        command = "bash-language-server";
        args = [ "start" ];
      };

      fish-lsp = {
        command = "fish-lsp";
        args = [ "start" ];
      };

      gopls = { command = "gopls"; };

      taplo = {
        command = "taplo";
        args = [ "lsp" "stdio" ];
      };

      vscode-json-language-server = {
        command = "vscode-json-language-server";
        args = [ "--stdio" ];
        config = {
          provideFormatter = true;
          json.validate.enable = true;
        };
      };

      yaml-language-server = {
        command = "yaml-language-server";
        args = [ "--stdio" ];
        config.yaml = {
          format.enable = true;
          validation = true;
          completion = true;
          hover = true;
          schemas = {
            "https://raw.githubusercontent.com/awslabs/goformation/master/schema/cloudformation.schema.json" = [
              "/*stack*.yaml"
              "/*stack*.yml"
              "/cloudformation/**/*.yaml"
              "/cloudformation/**/*.yml"
              "/*template*.yaml"
              "/*template*.yml"
            ];
            "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}";
            "https://json.schemastore.org/github-action.json" = ".github/actions/**/*.{yml,yaml}";
            "https://json.schemastore.org/docker-compose.json" = "docker-compose*.{yml,yaml}";
            "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "compose*.{yml,yaml}";
          };
        };
      };

      marksman = {
        command = "marksman";
        args = [ "server" ];
      };

      terraform-ls = {
        command = "terraform-ls";
        args = [ "serve" ];
      };

      harper = {
        command = "harper-ls";
        args = [ "--stdio" ];
        config.harper-ls = {
          diagnosticSeverity = "hint";
          dialect = "American";
          linters = { long_sentences = false; };
        };
      };
    };

    language = [
      {
        name = "nix";
        language-servers = [ "nixd" ];
        formatter = { command = "nixfmt"; };
        auto-format = true;
      }
      {
        name = "python";
        language-servers = [ "pyright" "ruff" ];
        formatter = {
          command = "ruff";
          args = [ "format" "-" ];
        };
        auto-format = true;
      }
      {
        name = "bash";
        language-servers = [ "bash-language-server" ];
        formatter = {
          command = "shfmt";
          args = [ "-i" "2" "-" ];
        };
        auto-format = true;
        file-types = [
          "sh"
          "bash"
          "zsh"
          "ash"
          "ebuild"
          "eclass"
          "env"
          "install"
          "profile"
          "PKGBUILD"
          { glob = ".bash_login"; }
          { glob = ".bash_logout"; }
          { glob = ".bash_profile"; }
          { glob = ".bashrc"; }
          { glob = ".bash_aliases"; }
          { glob = ".profile"; }
          { glob = ".zshrc"; }
          { glob = ".zshenv"; }
          { glob = ".zprofile"; }
          { glob = ".zlogin"; }
          { glob = ".zlogout"; }
          { glob = "/etc/profile"; }
          { glob = "/etc/bash.bashrc"; }
          { glob = "/etc/zshrc"; }
        ];
      }
      {
        name = "fish";
        language-servers = [ "fish-lsp" ];
      }
      {
        name = "go";
        language-servers = [ "gopls" ];
        auto-format = true;
      }
      {
        name = "toml";
        language-servers = [ "taplo" ];
        formatter = {
          command = "taplo";
          args = [ "fmt" "-" ];
        };
        auto-format = true;
      }
      {
        name = "json";
        language-servers = [ "vscode-json-language-server" ];
        auto-format = true;
      }
      {
        name = "jsonc";
        language-servers = [ "vscode-json-language-server" ];
        auto-format = true;
      }
      {
        name = "yaml";
        language-servers = [ "yaml-language-server" ];
        auto-format = true;
      }
      {
        name = "markdown";
        language-servers = [ "marksman" "harper" ];
        formatter = {
          command = "prettier";
          args = [ "--parser" "markdown" ];
        };
        auto-format = true;
      }
      {
        name = "hcl";
        language-servers = [ "terraform-ls" ];
        formatter = {
          command = "tofu";
          args = [ "fmt" "-" ];
        };
        auto-format = true;
      }
    ];
  };
}
