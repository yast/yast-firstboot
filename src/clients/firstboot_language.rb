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

#
# Module:             firstboot_language.ycp
#
# Author:             Klaus Kaempf (kkaempf@suse.de)
#
# Submodules:
#
#
# Purpose:	configure language in running system
#
# Modify:
#
#
# $Id$
module Yast
  class FirstbootLanguageClient < Client
    def main
      Yast.import "UI"
      textdomain "firstboot"

      Yast.import "Console"
      Yast.import "Directory"
      Yast.import "Language"
      Yast.import "Wizard"
      Yast.import "Firstboot"

      Yast.import "Popup"
      Yast.import "Encoding"
      Yast.import "Mode"
      Yast.import "GetInstArgs"
      Yast.import "ProductControl"

      # Memozize the current language.
      #
      @language_on_entry = Language.language

      Builtins.y2milestone("language_on_entry: <%1>", @language_on_entry)
      @result = :again
      # create the wizard dialog
      while @result == :again
        Wizard.SetDesktopIcon("language")
        @args = GetInstArgs.argmap
        Ops.set(@args, "first_run", "yes")
        @result = WFM.CallFunction("inst_language", [@args])
        Wizard.RetranslateButtons
        ProductControl.RetranslateWizardSteps
      end

      Builtins.y2milestone("result '%1'", @result)

      if @result == :cancel || @result == :back
        # Back to original values...
        #
        Builtins.y2milestone(
          "`cancel or `back --> restoring: <%1>",
          @language_on_entry
        )

        Yast.import "Installation"

        @use_utf8 = true # utf8 is default

        @display_info = UI.GetDisplayInfo
        if Ops.get_boolean(@display_info, "HasFullUtf8Support", false) != true
          @use_utf8 = false # fallback to ascii
        end

        # Set it in the Language module.
        #
        Language.Set(@language_on_entry)

        # Set Console font
        #
        Console.SelectFont(@language_on_entry)

        Installation.encoding = @use_utf8 ? "UTF-8" : Encoding.console

        # Set it in YaST2
        Language.WfmSetLanguage
      else
        # User wants to keep his changes --> save to sysconfig.
        #
        if Language.language != @language_on_entry ||
            Language.ExpertSettingsChanged
          Firstboot.language_changed = true
          Language.Save
          Console.Save
          Builtins.y2milestone("Language changed --> saving")
          @firstboot_keyboard = false
          Builtins.foreach(
            ProductControl.getModules("firstboot", Mode.mode, :enabled)
          ) do |mod|
            if Ops.get_string(mod, "name", "") == "firstboot_keyboard" &&
                Ops.get_boolean(mod, "enabled", false)
              Builtins.y2milestone("keyboard will be configured -> no warning")
              @firstboot_keyboard = true
            end
          end
          if !@firstboot_keyboard
            # popup text
            Popup.Message(
              _(
                "Your language setting has been changed.\n" +
                  "\n" +
                  "If necessary, you may want to adapt your keyboard settings to the new\n" +
                  "language. Use keyboard layout configuration tool after the login."
              )
            )
          end

          # update bootloader menu
          Language.WfmSetLanguage
        else
          Builtins.y2milestone("Language not changed --> doing nothing")
        end
      end

      deep_copy(@result)
    end
  end
end

Yast::FirstbootLanguageClient.new.main
