# Syncthing ignore patterns for the claude-config folder (~/.claude).
# Whitelist: anything not explicitly included is ignored. Shared by the hub,
# NixOS clients, and darwin home-manager; render with pkgs.writeText.
''
  // Managed by nixos-configs (claude-stignore.nix). Local edits are overwritten.
  (?d).DS_Store
  (?d)__pycache__
  (?d)*.pyc
  /.credentials.json
  !/CLAUDE.md
  !/SOUL.md
  !/settings.json
  !/keybindings.json
  !/skills
  !/agents
  !/commands
  !/projects/*/memory
  *
''
