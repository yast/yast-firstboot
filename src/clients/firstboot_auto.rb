# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# Autoinstallation client for firstboot configuration
# Author	: Jiri Suchomel <jsuchome@suse.cz>
module Yast
  class FirstbootAutoClient < Client
    def main
      Yast.import "UI"
      Yast.import "Firstboot"
      Yast.import "Label"
      Yast.import "Wizard"

      textdomain "firstboot"

      @ret = nil
      @func = ""
      @param = {}

      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.convert(
            WFM.Args(1),
            :from => "any",
            :to   => "map <string, any>"
          )
        end
      end

      Builtins.y2security("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Import"
        @ret = Firstboot.Import(@param)
      elsif @func == "Export"
        @ret = Firstboot.Export
      elsif @func == "Summary"
        @ret = Firstboot.Summary
      elsif @func == "Reset"
        Firstboot.Import({ "firstboot_enabled" => false })
        @ret = {}
      elsif @func == "Change"
        # TRANSLATORS: dialog caption
        @caption = _("Firstboot Configuration")
        @contents = HBox(
          VBox(
            Label(
              # TRANSLATORS: text label, describing the check box meaning
              # keep in 2 lines with roughly the same length
              _(
                "Check Enable Firstboot Sequence here to start YaST\nfirstboot utility on the first boot after configuration.\n"
              )
            ),
            VSpacing(),
            # TRANSLATORS: check box label
            CheckBox(
              Id(:enable),
              _("Enable Firstboot Sequence"),
              Firstboot.firstboot_enabled
            )
          )
        )
        Wizard.CreateDialog
        # TRANSLATORS: help text
        Wizard.SetContentsButtons(
          @caption,
          @contents,
          _(
            "<p>Check <b>Enable Firstboot Sequence</b> to start YaST firstboot utility on the first boot after configuration.</p>\n<p>Check the documentation of yast2-firstboot module for further information.</p>\n"
          ),
          Label.BackButton,
          Label.NextButton
        )

        @ret = UI.UserInput
        if @ret == :next
          Firstboot.firstboot_enabled = Convert.to_boolean(
            UI.QueryWidget(Id(:enable), :Value)
          )
        end
        UI.CloseDialog
      elsif @func == "Write"
        @ret = Firstboot.Write
      # Return if configuration  was changed
      # return boolean
      elsif @func == "GetModified"
        @ret = Firstboot.modified
      # Set all modified flags
      # return boolean
      elsif @func == "SetModified"
        Firstboot.modified = true
        @ret = true
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("firstboot auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)
    end
  end
end

Yast::FirstbootAutoClient.new.main
