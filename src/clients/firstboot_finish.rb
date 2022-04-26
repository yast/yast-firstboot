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

# File:	firstboot/src/inst_firstboot_finish.ycp
# Module:	Installation
# Summary:	Finish Firstboot
# Authors:	Anas Nashif <nashif@suse.de>
#
# Display a nice congratulation message for the user.
#
# $Id$
module Yast
  class FirstbootFinishClient < Client
    def main
      Yast.import "UI"
      textdomain "firstboot"

      Yast.import "FileUtils"
      Yast.import "Misc"
      Yast.import "Mode"
      Yast.import "Wizard"
      Yast.import "Popup"
      Yast.import "Label"
      Yast.import "Firstboot"
      Yast.import "GetInstArgs"
      Yast.import "Package"
      Yast.import "ProductControl"

      @display = UI.GetDisplayInfo

      @space = Ops.get_boolean(@display, "TextMode", true) ? 1 : 3

      # TRANSLATORS: caption for dialog "Congratulation Dialog"
      @caption = _("Configuration Completed")

      congratulate = ProductControl.GetTranslatedText("congratulate")

      @text = congratulate unless congratulate.empty?

      # TRANSLATORS: congratulation text 1/4
      @text ||= _("<p><b>Congratulations!</b></p>") +
        # TRANSLATORS: congratulation text 2/4
        _(
          "<p>The installation of &product; on your machine is complete.\nAfter clicking <b>Finish</b>, you can log in to the system.</p>\n"
        ) +
        # TRANSLATORS: congratulation text 3/4
        # Translators: If there exists a SUSE web-page for your language
        # change the address accordingly. If in doubt leave the original.
        _("<p>Visit us at www.suse.com.</p>") +
        # TRANSLATORS: congratulation text 4/4
        _("<p>Have a lot of fun!<br>Your SUSE Development Team</p>")


      # If text exists, read it from file instead; it is expected to be richtext.
      @finish_text = ""
      @finish_text_file = Misc.SysconfigRead(
        path(".sysconfig.firstboot.FIRSTBOOT_FINISH_FILE"),
        ""
      )
      if @finish_text_file != "" && FileUtils.Exists(@finish_text_file)
        @finish_text = Convert.to_string(
          SCR.Read(path(".target.string"), @finish_text_file)
        )
      end
      @finish_text = @text if @finish_text == nil || @finish_text == ""

      @contents = VBox(
        VSpacing(@space),
        HBox(
          HSpacing(Ops.multiply(2, @space)),
          RichText(@finish_text),
          HSpacing(Ops.multiply(2, @space))
        ),
        VSpacing(2)
      )

      # TRANSLATORS: help 1/3 for dialog "Congratulation Dialog"
      @help = _("<p>Your system is ready for use.</p>") +
        # TRANSLATORS: help 2/3 for dialog "Congratulation Dialog"
        _(
          "<p><b>Finish</b> will close the YaST installation and continue\nto the login screen.</p>\n"
        ) +
        # TRANSLATORS: help 3/3 for dialog "Congratulation Dialog"
        _(
          "<p>If you choose the default graphical desktop KDE, you can\n" +
            "adjust some KDE settings to your hardware. Also notice\n" +
            "our SUSE Welcome Dialog.</p>\n"
        )

      Wizard.SetContents(
        @caption,
        @contents,
        @help,
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )

      Wizard.HideAbortButton
      Wizard.SetNextButton(:next, Label.FinishButton)
      Wizard.SetFocusToNextButton


      @ret = nil
      begin
        @ret = Wizard.UserInput

        if @ret == :abort
          break if Popup.ConfirmAbort(:incomplete)
        elsif @ret == :help
          Wizard.ShowHelp(@help)
        end
      end until @ret == :next || @ret == :back

      Wizard.RestoreNextButton

      deep_copy(@ret)
    end
  end
end

Yast::FirstbootFinishClient.new.main
