# Syncthing ignore patterns for the claude-config folder (~/.claude).
# Whitelist only these entries; everything else is ignored.
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
