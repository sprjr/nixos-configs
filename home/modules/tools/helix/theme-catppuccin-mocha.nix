{ config, pkgs, home-manager, ... }:

{
  home.file.".config/helix/themes/catppuccin_mocha.toml" = {
    text = ''
      # syntax
      "attribute"                        = "mauve"
      "type"                             = "teal"
      "type.builtin"                     = { fg = "teal", modifiers = ["bold"] }
      "type.parameter"                   = "teal"
      "type.enum.variant"                = "teal"
      "constructor"                      = "sapphire"
      "constant"                         = "text"
      "constant.builtin"                 = { fg = "blue", modifiers = ["bold"] }
      "constant.builtin.boolean"         = { fg = "blue", modifiers = ["bold"] }
      "constant.character"               = "green"
      "constant.character.escape"        = "yellow"
      "constant.numeric"                 = "mauve"
      "constant.numeric.integer"         = "mauve"
      "constant.numeric.float"           = "mauve"
      "string"                           = "green"
      "string.regexp"                    = "yellow"
      "string.special"                   = "yellow"
      "string.special.path"              = "sapphire"
      "string.special.url"               = { fg = "sapphire", modifiers = ["underlined"] }
      "string.special.symbol"            = "teal"
      "comment"                          = { fg = "overlay0", modifiers = ["italic"] }
      "comment.line.documentation"       = { fg = "overlay0", modifiers = ["italic"] }
      "comment.block.documentation"      = { fg = "overlay0", modifiers = ["italic"] }
      "variable"                         = "text"
      "variable.builtin"                 = { fg = "blue", modifiers = ["italic"] }
      "variable.parameter"               = { fg = "text", modifiers = ["italic"] }
      "variable.other.member"            = "text"
      "label"                            = "sapphire"
      "punctuation"                      = "text"
      "punctuation.delimiter"            = "text"
      "punctuation.bracket"              = "text"
      "punctuation.special"              = "yellow"
      "keyword"                          = { fg = "blue", modifiers = ["bold"] }
      "keyword.control"                  = { fg = "blue", modifiers = ["bold"] }
      "keyword.control.conditional"      = { fg = "blue", modifiers = ["bold"] }
      "keyword.control.repeat"           = { fg = "blue", modifiers = ["bold"] }
      "keyword.control.import"           = { fg = "blue", modifiers = ["bold"] }
      "keyword.control.return"           = { fg = "blue", modifiers = ["bold"] }
      "keyword.control.exception"        = { fg = "red", modifiers = ["bold"] }
      "keyword.operator"                 = { fg = "blue", modifiers = ["bold"] }
      "keyword.directive"                = "blue"
      "keyword.function"                 = { fg = "blue", modifiers = ["bold"] }
      "keyword.storage"                  = { fg = "blue", modifiers = ["bold"] }
      "keyword.storage.type"             = { fg = "blue", modifiers = ["bold"] }
      "keyword.storage.modifier"         = { fg = "blue", modifiers = ["bold"] }
      "operator"                         = "blue"
      "function"                         = "sapphire"
      "function.builtin"                 = { fg = "sapphire", modifiers = ["bold"] }
      "function.method"                  = "sapphire"
      "function.macro"                   = "sapphire"
      "function.special"                 = "sapphire"
      "tag"                              = "blue"
      "tag.builtin"                      = { fg = "blue", modifiers = ["bold"] }
      "namespace"                        = { fg = "teal", modifiers = ["italic"] }
      "special"                          = "mauve"

      # markup
      "markup.heading"                   = { fg = "sapphire", modifiers = ["bold"] }
      "markup.heading.marker"            = { fg = "sapphire", modifiers = ["bold"] }
      "markup.heading.1"                 = { fg = "sapphire", modifiers = ["bold"] }
      "markup.heading.2"                 = { fg = "teal", modifiers = ["bold"] }
      "markup.heading.3"                 = { fg = "blue", modifiers = ["bold"] }
      "markup.heading.4"                 = "blue"
      "markup.heading.5"                 = "text"
      "markup.heading.6"                 = "overlay0"
      "markup.list"                      = "text"
      "markup.list.unnumbered"           = "text"
      "markup.list.numbered"             = "mauve"
      "markup.list.checked"              = "green"
      "markup.list.unchecked"            = "overlay0"
      "markup.bold"                      = { modifiers = ["bold"] }
      "markup.italic"                    = { modifiers = ["italic"] }
      "markup.strikethrough"             = { modifiers = ["crossed_out"] }
      "markup.link"                      = "sapphire"
      "markup.link.url"                  = { fg = "sapphire", modifiers = ["underlined"] }
      "markup.link.label"                = "teal"
      "markup.link.text"                 = "text"
      "markup.quote"                     = { fg = "overlay0", modifiers = ["italic"] }
      "markup.raw"                       = "yellow"
      "markup.raw.inline"                = "yellow"
      "markup.raw.block"                 = "yellow"
      "markup.normal.completion"         = "text"
      "markup.normal.hover"              = "text"
      "markup.heading.completion"        = { fg = "sapphire", modifiers = ["bold"] }
      "markup.heading.hover"             = { fg = "sapphire", modifiers = ["bold"] }
      "markup.raw.inline.completion"     = "yellow"
      "markup.raw.inline.hover"          = "yellow"

      # diff
      "diff.plus"                        = "green"
      "diff.plus.gutter"                 = "green"
      "diff.minus"                       = "red"
      "diff.minus.gutter"                = "red"
      "diff.delta"                       = "yellow"
      "diff.delta.moved"                 = "mauve"
      "diff.delta.conflict"              = { fg = "peach", modifiers = ["bold"] }
      "diff.delta.gutter"                = "yellow"

      # ui
      "ui.background"                    = { bg = "base" }
      "ui.background.separator"          = { fg = "surface2", bg = "base" }
      "ui.cursor"                        = { fg = "base", bg = "text" }
      "ui.cursor.normal"                 = { fg = "base", bg = "text" }
      "ui.cursor.insert"                 = { fg = "base", bg = "lavender" }
      "ui.cursor.select"                 = { fg = "base", bg = "sapphire" }
      "ui.cursor.match"                  = { fg = "base", bg = "yellow" }
      "ui.cursor.primary"                = { fg = "base", bg = "text" }
      "ui.cursor.primary.normal"         = { fg = "base", bg = "text" }
      "ui.cursor.primary.insert"         = { fg = "base", bg = "lavender" }
      "ui.cursor.primary.select"         = { fg = "base", bg = "sapphire" }
      "ui.debug.breakpoint"              = { fg = "red" }
      "ui.debug.active"                  = { fg = "yellow" }
      "ui.gutter"                        = { bg = "base" }
      "ui.gutter.selected"               = { bg = "surface0" }
      "ui.linenr"                        = { fg = "overlay0", bg = "base" }
      "ui.linenr.selected"               = { fg = "text", bg = "surface0", modifiers = ["bold"] }
      "ui.statusline"                    = { fg = "text", bg = "surface1" }
      "ui.statusline.inactive"           = { fg = "overlay0", bg = "surface0" }
      "ui.statusline.normal"             = { fg = "base", bg = "blue", modifiers = ["bold"] }
      "ui.statusline.insert"             = { fg = "base", bg = "green", modifiers = ["bold"] }
      "ui.statusline.select"             = { fg = "base", bg = "sapphire", modifiers = ["bold"] }
      "ui.statusline.separator"          = { fg = "overlay0", bg = "surface1" }
      "ui.bufferline"                    = { fg = "text", bg = "surface0" }
      "ui.bufferline.active"             = { fg = "sapphire", bg = "surface1", modifiers = ["bold"] }
      "ui.bufferline.background"         = { bg = "base" }
      "ui.popup"                         = { fg = "text", bg = "surface0" }
      "ui.popup.info"                    = { fg = "text", bg = "surface1" }
      "ui.picker.header"                 = { fg = "text", bg = "surface0" }
      "ui.picker.header.column"          = { fg = "teal", modifiers = ["bold"] }
      "ui.picker.header.column.active"   = { fg = "sapphire", modifiers = ["bold"] }
      "ui.window"                        = { fg = "surface2" }
      "ui.help"                          = { fg = "text", bg = "surface0" }
      "ui.text"                          = "text"
      "ui.text.focus"                    = { fg = "sapphire", bg = "surface1", modifiers = ["bold"] }
      "ui.text.inactive"                 = "overlay0"
      "ui.text.info"                     = { fg = "text", bg = "surface1" }
      "ui.text.directory"                = { fg = "sapphire", modifiers = ["bold"] }
      "ui.virtual.ruler"                 = { bg = "surface0" }
      "ui.virtual.whitespace"            = { fg = "surface2" }
      "ui.virtual.indent-guide"          = { fg = "surface2" }
      "ui.virtual.inlay-hint"            = { fg = "overlay0", modifiers = ["italic"] }
      "ui.virtual.inlay-hint.parameter"  = { fg = "overlay0", modifiers = ["italic"] }
      "ui.virtual.inlay-hint.type"       = { fg = "overlay0", modifiers = ["italic"] }
      "ui.virtual.wrap"                  = { fg = "surface2" }
      "ui.virtual.jump-label"            = { fg = "yellow", modifiers = ["bold"] }
      "ui.menu"                          = { fg = "text", bg = "surface0" }
      "ui.menu.selected"                 = { fg = "sapphire", bg = "surface1", modifiers = ["bold"] }
      "ui.menu.scroll"                   = { fg = "overlay0", bg = "surface0" }
      "ui.selection"                     = { bg = "surface1" }
      "ui.selection.primary"             = { bg = "surface2" }
      "ui.highlight"                     = { bg = "surface1" }
      "ui.highlight.frameline"           = { bg = "surface0" }
      "ui.cursorline.primary"            = { bg = "surface0" }
      "ui.cursorline.secondary"          = { bg = "surface0" }
      "ui.cursorcolumn.primary"          = { bg = "surface0" }
      "ui.cursorcolumn.secondary"        = { bg = "surface0" }

      # diagnostics
      "warning"                          = { fg = "yellow" }
      "error"                            = { fg = "red" }
      "info"                             = { fg = "sapphire" }
      "hint"                             = { fg = "teal" }
      "diagnostic"                       = { underline = { style = "curl" } }
      "diagnostic.hint"                  = { underline = { color = "teal", style = "curl" } }
      "diagnostic.info"                  = { underline = { color = "sapphire", style = "curl" } }
      "diagnostic.warning"               = { underline = { color = "yellow", style = "curl" } }
      "diagnostic.error"                 = { underline = { color = "red", style = "curl" } }
      "diagnostic.unnecessary"           = { modifiers = ["dim"] }
      "diagnostic.deprecated"            = { modifiers = ["crossed_out"] }

      "tabstop"                          = { fg = "yellow", modifiers = ["bold"] }

      [palette]
      base       = "#1E1E2E"
      mantle     = "#181825"
      crust      = "#11111B"
      surface0   = "#313244"
      surface1   = "#45475A"
      surface2   = "#585B70"
      overlay0   = "#6C7086"
      overlay1   = "#7F849C"
      overlay2   = "#9399B2"
      subtext0   = "#A6ADC8"
      subtext1   = "#BAC2DE"
      text       = "#CDD6F4"
      lavender   = "#B4BEFE"
      blue       = "#89B4FA"
      sapphire   = "#74C7EC"
      sky        = "#89DCEB"
      teal       = "#94E2D5"
      green      = "#A6E3A1"
      yellow     = "#F9E2AF"
      peach      = "#FAB387"
      maroon     = "#EBA0AC"
      red        = "#F38BA8"
      mauve      = "#CBA6F7"
      pink       = "#F5C2E7"
      flamingo   = "#F2CDCD"
      rosewater  = "#F5E0DC"
    '';
  };
}
