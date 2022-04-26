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

# File:	firstboot/src/firstboot_desktop.ycp
# Module:	Installation
# Summary:	Firstboot Desktop Selection
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
module Yast
  class FirstbootDesktopClient < Client
    def main
      Yast.import "UI"
      Yast.import "Pkg"
      textdomain "firstboot"
      Yast.import "Wizard"
      Yast.import "Firstboot"
      Yast.import "GetInstArgs"


      # Continue, we have only one desktop installed
      return :auto if !checkSelections

      @selection_description = {}
      Builtins.foreach(Firstboot.installed_desktops) do |selection|
        selection_data = {} # FIXME: Pkg::SelectionData() has been removed, returned $[] anyway
        if selection_data != nil
          Ops.set(
            @selection_description,
            selection,
            Ops.get_string(
              selection_data,
              "summary",
              Ops.add(Ops.add("'", selection), "'")
            )
          )
        end
      end

      # Construct a box with radiobuttons for each software base configuration
      @selection_box = RadioButtonGroup(
        Id(:selection_box),
        VBox(
          Left(
            RadioButton(
              Id("gnome"),
              Opt(:notify),
              Ops.get(@selection_description, "Gnome", "not defined"),
              Firstboot.default_wm == "gnome"
            )
          ),
          VSpacing(1),
          Left(
            RadioButton(
              Id("kde"),
              Opt(:notify),
              Ops.get(@selection_description, "Kde", "not defined"),
              Firstboot.default_wm == "kde"
            )
          )
        )
      )


      @ask_desktop_dialog = HBox(
        HStretch(),
        VBox(
          VWeight(30, VStretch()),
          # TRANSLATORS: dialog text
          Left(
            Label(
              _(
                "Select the desktop environment \nto use from the list below.\n"
              )
            )
          ),
          VSpacing(1),
          VWeight(10, VStretch()),
          HBox(HSpacing(10), @selection_box),
          VWeight(60, VStretch())
        ),
        HStretch()
      )


      # TRANSLATORS: help text for desktop dialog
      @desktop_help_text = _(
        "<p><h3>Desktop Selections</h3>\n" +
          "This system has more than one desktop environment installed. Select\n" +
          "the desktop to enable as the default desktop.</p>"
      )

      # TRANSLATORS: dialog title
      Wizard.SetContents(
        _("Select Your Default Desktop"),
        @ask_desktop_dialog,
        @desktop_help_text,
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )

      @ret = nil
      begin
        @ret = UI.UserInput
        # get the newly selected base configuration
        Firstboot.default_wm = Convert.to_string(
          UI.QueryWidget(Id(:selection_box), :CurrentButton)
        )
      end until @ret == :next || @ret == :back || @ret == :abort

      Convert.to_symbol(@ret) 
      #EOF
    end

    # Check if both selections are installed
    # @return false if not
    def checkSelections
      Pkg.TargetInit("/", false)
      installed_desktop_selections = [] # FIXME: Pkg::GetSelections() has been removed, returned [] anyway
      Builtins.y2milestone(
        "available_desktop_selections %1",
        installed_desktop_selections
      )

      if !Builtins.contains(installed_desktop_selections, "Gnome")
        Builtins.y2error("No desktop selections installed for Gnome")
        return false
      end
      if !Builtins.contains(installed_desktop_selections, "Kde")
        Builtins.y2error("No desktop selections installed Kde")
        return false
      end

      Firstboot.installed_desktops = deep_copy(installed_desktop_selections)
      true
    end
  end
end

Yast::FirstbootDesktopClient.new.main
