{ config, pkgs, home-manager, ... }:

let
  zellijConfigContent = ''
    show_startup_tips false

    theme "catppuccin-mocha"
    themes {
        catppuccin-mocha {
          text_unselected {
            base 205 214 244
            background 49 50 68
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          text_selected {
            base 205 214 244
            background 49 50 68
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          ribbon_selected {
            base 30 30 46
            background 166 227 161
            emphasis_0 243 139 168
            emphasis_1 250 179 135
            emphasis_2 203 166 247
            emphasis_3 137 180 250
          }
          ribbon_unselected {
            base 30 30 46
            background 186 194 222
            emphasis_0 243 139 168
            emphasis_1 205 214 244
            emphasis_2 137 180 250
            emphasis_3 203 166 247
          }
          table_title {
            base 166 227 161
            background 0
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          table_cell_selected {
            base 205 214 244
            background 24 24 37
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          table_cell_unselected {
            base 205 214 244
            background 49 50 68
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          list_selected {
            base 205 214 244
            background 24 24 37
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          list_unselected {
            base 205 214 244
            background 49 50 68
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 166 227 161
            emphasis_3 203 166 247
          }
          frame_selected {
            base 166 227 161
            background 0
            emphasis_0 250 179 135
            emphasis_1 137 180 250
            emphasis_2 203 166 247
            emphasis_3 0
          }
          frame_highlight {
            base 250 179 135
            background 0
            emphasis_0 250 179 135
            emphasis_1 250 179 135
            emphasis_2 250 179 135
            emphasis_3 250 179 135
          }
          exit_code_success {
            base 166 227 161
            background 0
            emphasis_0 137 220 235
            emphasis_1 49 50 68
            emphasis_2 203 166 247
            emphasis_3 137 180 250
          }
          exit_code_error {
            base 243 139 168
            background 0
            emphasis_0 249 226 175
            emphasis_1 0
            emphasis_2 0
            emphasis_3 0
          }
          multiplayer_user_colors {
            player_1 203 166 247
            player_2 137 180 250
            player_3 0
            player_4 249 226 175
            player_5 137 220 235
            player_6 0
            player_7 243 139 168
            player_8 0
            player_9 0
            player_10 0
          }
        }
      }
  '';
in

{
  programs.zellij.enable = true;

  # Write config.kdl directly to ~/.config/zellij/config.kdl
  home.file.".config/zellij/config.kdl".text = zellijConfigContent;
}
