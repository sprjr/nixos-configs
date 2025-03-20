{ config, pkgs, home-manager, ... }:

let
  zellijConfigContent = ''
    show_startup_tips false

    theme "nord"
    themes {
        nord {
          text_unselected {
            base 229 233 240
            background 59 66 82
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          text_selected {
            base 229 233 240
            background 59 66 82
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          ribbon_selected {
            base 59 66 82
            background 163 190 140
            emphasis_0 191 97 106
            emphasis_1 208 135 112
            emphasis_2 180 142 173
            emphasis_3 129 161 193
          }
          ribbon_unselected {
            base 59 66 82
            background 216 222 233
            emphasis_0 191 97 106
            emphasis_1 229 233 240
            emphasis_2 129 161 193
            emphasis_3 180 142 173
          }
          table_title {
            base 163 190 140
            background 0
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          table_cell_selected {
            base 229 233 240
            background 46 52 64
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          table_cell_unselected {
            base 229 233 240
            background 59 66 82
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          list_selected {
            base 229 233 240
            background 46 52 64
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          list_unselected {
            base 229 233 240
            background 59 66 82
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 163 190 140
            emphasis_3 180 142 173
          }
          frame_selected {
            base 163 190 140
            background 0
            emphasis_0 208 135 112
            emphasis_1 136 192 208
            emphasis_2 180 142 173
            emphasis_3 0
          }
          frame_highlight {
            base 208 135 112
            background 0
            emphasis_0 208 135 112
            emphasis_1 208 135 112
            emphasis_2 208 135 112
            emphasis_3 208 135 112
          }
          exit_code_success {
            base 163 190 140
            background 0
            emphasis_0 136 192 208
            emphasis_1 59 66 82
            emphasis_2 180 142 173
            emphasis_3 129 161 193
          }
          exit_code_error {
            base 191 97 106
            background 0
            emphasis_0 235 203 139
            emphasis_1 0
            emphasis_2 0
            emphasis_3 0
          }
          multiplayer_user_colors {
            player_1 180 142 173
            player_2 129 161 193
            player_3 0
            player_4 235 203 139
            player_5 136 192 208
            player_6 0
            player_7 191 97 106
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
