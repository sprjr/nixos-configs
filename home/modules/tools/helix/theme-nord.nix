{ config, pkgs, home-manager, ... }:

{
  home.file.".config/helix/themes/nord.toml" = {
    text = ''
      # syntax
      "attribute"                        = "nord15"
      "type"                             = "nord7"
      "type.builtin"                     = { fg = "nord7", modifiers = ["bold"] }
      "type.parameter"                   = "nord7"
      "type.enum.variant"                = "nord7"
      "constructor"                      = "nord8"
      "constant"                         = "nord4"
      "constant.builtin"                 = { fg = "nord9", modifiers = ["bold"] }
      "constant.builtin.boolean"         = { fg = "nord9", modifiers = ["bold"] }
      "constant.character"               = "nord14"
      "constant.character.escape"        = "nord13"
      "constant.numeric"                 = "nord15"
      "constant.numeric.integer"         = "nord15"
      "constant.numeric.float"           = "nord15"
      "string"                           = "nord14"
      "string.regexp"                    = "nord13"
      "string.special"                   = "nord13"
      "string.special.path"              = "nord8"
      "string.special.url"               = { fg = "nord8", modifiers = ["underlined"] }
      "string.special.symbol"            = "nord7"
      "comment"                          = { fg = "nord3_bright", modifiers = ["italic"] }
      "comment.line.documentation"       = { fg = "nord3_bright", modifiers = ["italic"] }
      "comment.block.documentation"      = { fg = "nord3_bright", modifiers = ["italic"] }
      "variable"                         = "nord4"
      "variable.builtin"                 = { fg = "nord9", modifiers = ["italic"] }
      "variable.parameter"               = { fg = "nord4", modifiers = ["italic"] }
      "variable.other.member"            = "nord4"
      "label"                            = "nord8"
      "punctuation"                      = "nord4"
      "punctuation.delimiter"            = "nord4"
      "punctuation.bracket"              = "nord4"
      "punctuation.special"              = "nord13"
      "keyword"                          = { fg = "nord9", modifiers = ["bold"] }
      "keyword.control"                  = { fg = "nord9", modifiers = ["bold"] }
      "keyword.control.conditional"      = { fg = "nord9", modifiers = ["bold"] }
      "keyword.control.repeat"           = { fg = "nord9", modifiers = ["bold"] }
      "keyword.control.import"           = { fg = "nord9", modifiers = ["bold"] }
      "keyword.control.return"           = { fg = "nord9", modifiers = ["bold"] }
      "keyword.control.exception"        = { fg = "nord11", modifiers = ["bold"] }
      "keyword.operator"                 = { fg = "nord9", modifiers = ["bold"] }
      "keyword.directive"                = "nord9"
      "keyword.function"                 = { fg = "nord9", modifiers = ["bold"] }
      "keyword.storage"                  = { fg = "nord9", modifiers = ["bold"] }
      "keyword.storage.type"             = { fg = "nord9", modifiers = ["bold"] }
      "keyword.storage.modifier"         = { fg = "nord9", modifiers = ["bold"] }
      "operator"                         = "nord9"
      "function"                         = "nord8"
      "function.builtin"                 = { fg = "nord8", modifiers = ["bold"] }
      "function.method"                  = "nord8"
      "function.macro"                   = "nord8"
      "function.special"                 = "nord8"
      "tag"                              = "nord9"
      "tag.builtin"                      = { fg = "nord9", modifiers = ["bold"] }
      "namespace"                        = { fg = "nord7", modifiers = ["italic"] }
      "special"                          = "nord15"

      # markup
      "markup.heading"                   = { fg = "nord8", modifiers = ["bold"] }
      "markup.heading.marker"            = { fg = "nord8", modifiers = ["bold"] }
      "markup.heading.1"                 = { fg = "nord8", modifiers = ["bold"] }
      "markup.heading.2"                 = { fg = "nord7", modifiers = ["bold"] }
      "markup.heading.3"                 = { fg = "nord9", modifiers = ["bold"] }
      "markup.heading.4"                 = "nord9"
      "markup.heading.5"                 = "nord4"
      "markup.heading.6"                 = "nord3_bright"
      "markup.list"                      = "nord4"
      "markup.list.unnumbered"           = "nord4"
      "markup.list.numbered"             = "nord15"
      "markup.list.checked"              = "nord14"
      "markup.list.unchecked"            = "nord3_bright"
      "markup.bold"                      = { modifiers = ["bold"] }
      "markup.italic"                    = { modifiers = ["italic"] }
      "markup.strikethrough"             = { modifiers = ["crossed_out"] }
      "markup.link"                      = "nord8"
      "markup.link.url"                  = { fg = "nord8", modifiers = ["underlined"] }
      "markup.link.label"                = "nord7"
      "markup.link.text"                 = "nord4"
      "markup.quote"                     = { fg = "nord3_bright", modifiers = ["italic"] }
      "markup.raw"                       = "nord13"
      "markup.raw.inline"                = "nord13"
      "markup.raw.block"                 = "nord13"
      "markup.normal.completion"         = "nord4"
      "markup.normal.hover"              = "nord4"
      "markup.heading.completion"        = { fg = "nord8", modifiers = ["bold"] }
      "markup.heading.hover"             = { fg = "nord8", modifiers = ["bold"] }
      "markup.raw.inline.completion"     = "nord13"
      "markup.raw.inline.hover"          = "nord13"

      # diff
      "diff.plus"                        = "nord14"
      "diff.plus.gutter"                 = "nord14"
      "diff.minus"                       = "nord11"
      "diff.minus.gutter"                = "nord11"
      "diff.delta"                       = "nord13"
      "diff.delta.moved"                 = "nord15"
      "diff.delta.conflict"              = { fg = "nord12", modifiers = ["bold"] }
      "diff.delta.gutter"                = "nord13"

      # ui
      "ui.background"                    = { bg = "nord0" }
      "ui.background.separator"          = { fg = "nord3", bg = "nord0" }
      "ui.cursor"                        = { fg = "nord0", bg = "nord4" }
      "ui.cursor.normal"                 = { fg = "nord0", bg = "nord4" }
      "ui.cursor.insert"                 = { fg = "nord0", bg = "nord6" }
      "ui.cursor.select"                 = { fg = "nord0", bg = "nord8" }
      "ui.cursor.match"                  = { fg = "nord0", bg = "nord13" }
      "ui.cursor.primary"                = { fg = "nord0", bg = "nord4" }
      "ui.cursor.primary.normal"         = { fg = "nord0", bg = "nord4" }
      "ui.cursor.primary.insert"         = { fg = "nord0", bg = "nord6" }
      "ui.cursor.primary.select"         = { fg = "nord0", bg = "nord8" }
      "ui.debug.breakpoint"              = { fg = "nord11" }
      "ui.debug.active"                  = { fg = "nord13" }
      "ui.gutter"                        = { bg = "nord0" }
      "ui.gutter.selected"               = { bg = "nord1" }
      "ui.linenr"                        = { fg = "nord3_bright", bg = "nord0" }
      "ui.linenr.selected"               = { fg = "nord4", bg = "nord1", modifiers = ["bold"] }
      "ui.statusline"                    = { fg = "nord4", bg = "nord2" }
      "ui.statusline.inactive"           = { fg = "nord3_bright", bg = "nord1" }
      "ui.statusline.normal"             = { fg = "nord0", bg = "nord9", modifiers = ["bold"] }
      "ui.statusline.insert"             = { fg = "nord0", bg = "nord14", modifiers = ["bold"] }
      "ui.statusline.select"             = { fg = "nord0", bg = "nord8", modifiers = ["bold"] }
      "ui.statusline.separator"          = { fg = "nord3_bright", bg = "nord2" }
      "ui.bufferline"                    = { fg = "nord4", bg = "nord1" }
      "ui.bufferline.active"             = { fg = "nord8", bg = "nord2", modifiers = ["bold"] }
      "ui.bufferline.background"         = { bg = "nord0" }
      "ui.popup"                         = { fg = "nord4", bg = "nord1" }
      "ui.popup.info"                    = { fg = "nord4", bg = "nord2" }
      "ui.picker.header"                 = { fg = "nord4", bg = "nord1" }
      "ui.picker.header.column"          = { fg = "nord7", modifiers = ["bold"] }
      "ui.picker.header.column.active"   = { fg = "nord8", modifiers = ["bold"] }
      "ui.window"                        = { fg = "nord3" }
      "ui.help"                          = { fg = "nord4", bg = "nord1" }
      "ui.text"                          = "nord4"
      "ui.text.focus"                    = { fg = "nord8", bg = "nord2", modifiers = ["bold"] }
      "ui.text.inactive"                 = "nord3_bright"
      "ui.text.info"                     = { fg = "nord4", bg = "nord2" }
      "ui.text.directory"                = { fg = "nord8", modifiers = ["bold"] }
      "ui.virtual.ruler"                 = { bg = "nord1" }
      "ui.virtual.whitespace"            = { fg = "nord3" }
      "ui.virtual.indent-guide"          = { fg = "nord3" }
      "ui.virtual.inlay-hint"            = { fg = "nord3_bright", modifiers = ["italic"] }
      "ui.virtual.inlay-hint.parameter"  = { fg = "nord3_bright", modifiers = ["italic"] }
      "ui.virtual.inlay-hint.type"       = { fg = "nord3_bright", modifiers = ["italic"] }
      "ui.virtual.wrap"                  = { fg = "nord3" }
      "ui.virtual.jump-label"            = { fg = "nord13", modifiers = ["bold"] }
      "ui.menu"                          = { fg = "nord4", bg = "nord1" }
      "ui.menu.selected"                 = { fg = "nord8", bg = "nord2", modifiers = ["bold"] }
      "ui.menu.scroll"                   = { fg = "nord3_bright", bg = "nord1" }
      "ui.selection"                     = { bg = "nord2" }
      "ui.selection.primary"             = { bg = "nord3" }
      "ui.highlight"                     = { bg = "nord2" }
      "ui.highlight.frameline"           = { bg = "nord1" }
      "ui.cursorline.primary"            = { bg = "nord1" }
      "ui.cursorline.secondary"          = { bg = "nord1" }
      "ui.cursorcolumn.primary"          = { bg = "nord1" }
      "ui.cursorcolumn.secondary"        = { bg = "nord1" }

      # diagnostics
      "warning"                          = { fg = "nord13" }
      "error"                            = { fg = "nord11" }
      "info"                             = { fg = "nord8" }
      "hint"                             = { fg = "nord7" }
      "diagnostic"                       = { underline = { style = "curl" } }
      "diagnostic.hint"                  = { underline = { color = "nord7", style = "curl" } }
      "diagnostic.info"                  = { underline = { color = "nord8", style = "curl" } }
      "diagnostic.warning"               = { underline = { color = "nord13", style = "curl" } }
      "diagnostic.error"                 = { underline = { color = "nord11", style = "curl" } }
      "diagnostic.unnecessary"           = { modifiers = ["dim"] }
      "diagnostic.deprecated"            = { modifiers = ["crossed_out"] }

      "tabstop"                          = { fg = "nord13", modifiers = ["bold"] }

      [palette]
      nord0        = "#2E3440"
      nord1        = "#3B4252"
      nord2        = "#434C5E"
      nord3        = "#4C566A"
      nord3_bright = "#616E88"
      nord4        = "#D8DEE9"
      nord5        = "#E5E9F0"
      nord6        = "#ECEFF4"
      nord7        = "#8FBCBB"
      nord8        = "#88C0D0"
      nord9        = "#81A1C1"
      nord10       = "#5E81AC"
      nord11       = "#BF616A"
      nord12       = "#D08770"
      nord13       = "#EBCB8B"
      nord14       = "#A3BE8C"
      nord15       = "#B48EAD"
    '';
  };
}
