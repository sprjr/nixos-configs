{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.random-mtg-card;

  random-mtg-card = pkgs.writeShellScriptBin "random-mtg-card" ''
    response=$(${pkgs.curl}/bin/curl -s "https://api.scryfall.com/cards/random")

    if [ $? -ne 0 ] || [ -z "$response" ]; then
      echo "Failed to fetch card from Scryfall"
      exit 1
    fi

    name=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.name')
    mana_cost=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.mana_cost // "N/A"')
    type_line=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.type_line')
    oracle_text=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.oracle_text // "No text"')
    set_name=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.set_name')
    rarity=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.rarity')

    echo "╔════════════════════════════════════════╗"
    echo "║     Random MTG Card of the Day        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "🃏 $name $mana_cost"
    echo "📋 $type_line"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$oracle_text" | fold -s -w 40
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 $set_name | ✨ $rarity"
    echo ""
  '';
in
{
  options.programs.random-mtg-card = {
    enable = mkEnableOption "random MTG card on shell login";

    showOnLogin = mkOption {
      type = types.bool;
      default = true;
      description = "Show card automatically on shell login";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ random-mtg-card ];

    programs.bash.initExtra = mkIf cfg.showOnLogin ''
      random-mtg-card
    '';

    programs.zsh.initExtra = mkIf cfg.showOnLogin ''
      random-mtg-card
    '';
  };
}
