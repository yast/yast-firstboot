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

# File:
#	firstboot_language_keyboard.ycp
#
# Module:
#	Firsboot
#
# Authors:
#	Jiri Suchomel <jsuchome@suse.cz>
#	Lukas Ocilka <locilka@suse.cz>
#
# Summary:
#	This client shows dialog for choosing the language and keyboard layout
#
# $Id$
#
module Yast
  class FirstbootLanguageKeyboardClient < Client
    def main
      Yast.import "Pkg"
      Yast.import "UI"
      textdomain "firstboot"

      Yast.import "Console"
      Yast.import "Directory"
      Yast.import "GetInstArgs"
      Yast.import "Keyboard"
      Yast.import "Label"
      Yast.import "Language"
      Yast.import "Popup"
      Yast.import "ProductControl"
      Yast.import "Report"
      Yast.import "Timezone"
      Yast.import "Wizard"
      Yast.import "Icon"

      # ------------------------------------- main part of the client -----------

      @argmap = GetInstArgs.argmap

      @language = Language.language

      # language preselected in /etc/install.inf
      @preselected = Language.preselected

      @text_mode = Language.GetTextMode

      # ----------------------------------------------------------------------
      # Build dialog
      # ----------------------------------------------------------------------
      # heading text
      @heading_text = _("Language and Keyboard Layout")

      @languagesel = ComboBox(
        Id(:language),
        Opt(:notify, :hstretch),
        # combo box label
        _("&Language"),
        Language.GetLanguageItems(:first_screen)
      )

      @keyboardsel = ComboBox(
        Id(:keyboard),
        Opt(:notify, :hstretch),
        # combo box label
        _("&Keyboard Layout"),
        Keyboard.GetKeyboardItems
      )

      # this type of contents will be shown only for initial installation dialog
      @contents = VBox(
        VWeight(3, VStretch()),
        HSquash(
          VBox(
            HBox(
              HSquash(Icon.Simple("yast-language")),
              HSpacing(2),
              Left(@languagesel)
            ),
            VSpacing(1),
            HBox(
              HSquash(Icon.Simple("yast-keyboard")),
              HSpacing(2),
              Left(@keyboardsel)
            )
          )
        ),
        VWeight(1, VStretch()),
        VWeight(3, VStretch())
      )

      # help text for firstboot language + keyboard screen
      @help_text = _(
        "<p>\n" +
          "Choose the <b>Language</b> and the <b>Keyboard Layout</b> to be used during\n" +
          "configuration and in the installed system.\n" +
          "</p>\n"
      ) +
        # help text, continued
        _(
          "<p>\n" +
            "Click <b>Next</b> to proceed to the next dialog.\n" +
            "</p>\n"
        ) +
        # help text, continued
        _(
          "<p>\n" +
            "Select <b>Abort</b> to abort the\n" +
            "installation process at any time.\n" +
            "</p>\n"
        )

      # Screen title for the first interactive dialog

      Wizard.SetContents(
        @heading_text,
        @contents,
        @help_text,
        Ops.get_boolean(@argmap, "enable_back", true),
        Ops.get_boolean(@argmap, "enable_next", true)
      )
      Wizard.EnableAbortButton

      UI.ChangeWidget(Id(:language), :Value, @language)

      if Keyboard.user_decision == true
        UI.ChangeWidget(Id(:keyboard), :Value, Keyboard.current_kbd)
      else
        @kbd = Keyboard.GetKeyboardForLanguage(@language, "english-us")
        UI.ChangeWidget(Id(:keyboard), :Value, @kbd)
      end

      Wizard.SetTitleIcon("yast-language")

      # Get the user input.
      #
      @ret = nil

      UI.SetFocus(Id(:language))

      @keyboard = ""

      while true
        @ret = UI.UserInput
        Builtins.y2milestone("UserInput() returned %1", @ret)

        if @ret == :back
          break
        elsif @ret == :abort && Popup.ConfirmAbort(:painless)
          Wizard.RestoreNextButton
          @ret = :abort
          break
        elsif @ret == :keyboard
          Keyboard.user_decision = true
        elsif @ret == :next || @ret == :language
          @language = Convert.to_string(UI.QueryWidget(Id(:language), :Value))
          @keyboard = Convert.to_string(UI.QueryWidget(Id(:keyboard), :Value))

          if @ret == :next && !Language.CheckIncompleteTranslation(@language)
            next
          end

          if SetLanguageIfChanged(@ret)
            @ret = :again
            break
          end

          break if @ret == :next
        end
      end

      Wizard.RetranslateButtons
      ProductControl.RetranslateWizardSteps

      Convert.to_symbol(@ret)
    end

    # Returns true if the dialog needs redrawing
    def SetLanguageIfChanged(ret)
      ret = deep_copy(ret)
      if @language != Language.language
        Builtins.y2milestone(
          "Language changed from %1 to %2",
          Language.language,
          @language
        )
        Timezone.ResetZonemap

        # Set it in the Language module.
        Language.Set(@language)
      end
      # Check and set CJK languages
      if ret == :language && Language.SwitchToEnglishIfNeeded(true)
        Builtins.y2debug("UI switched to en_US")
      elsif ret == :language
        Console.SelectFont(@language)
        # no yast translation for nn_NO, use nb_NO as a backup
        if @language == "nn_NO"
          Builtins.y2milestone("Nynorsk not translated, using Bokm\u00E5l")
          Language.WfmSetGivenLanguage("nb_NO")
        else
          Language.WfmSetLanguage
        end
      end

      if ret == :language
        # Display newly translated dialog.
        Wizard.SetFocusToNextButton
        return true
      end

      if ret == :next
        Keyboard.Set(@keyboard)

        # Language has been set already.
        # On first run store users decision as default.
        Builtins.y2milestone("Resetting to default language")
        Language.SetDefault

        # only one is installed in firstboot
        Language.languages = @language

        Timezone.SetTimezoneForLanguage(@language)

        # Bugzilla #354133
        Builtins.y2milestone(
          "Adjusting package and text locale to %1",
          @language
        )
        Pkg.SetPackageLocale(@language)
        Pkg.SetTextLocale(@language)

        Builtins.y2milestone(
          "Language: '%1', system encoding '%2'",
          @language,
          WFM.GetEncoding
        )

        # install language dependent packages now
        # Language::PackagesModified () does not work here as _on_entry variables are not set
        if @language != Language.ReadSysconfigLanguage
          if !Language.PackagesInit([@language])
            # error message
            Report.Error(
              _("There is not enough space to install all additional packages.")
            )
          else
            Language.PackagesCommit
          end
        end

        Language.Save
        Keyboard.Save
        Timezone.Save
        Console.Save
      end

      false
    end
  end
end

Yast::FirstbootLanguageKeyboardClient.new.main
