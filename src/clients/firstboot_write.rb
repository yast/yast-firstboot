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

# File:	firstboot/src/firstboot_write.ycp
# Module:	Installation
# Summary:	Finish Firstboot
# Authors:	Anas Nashif <nashif@suse.de>
#
# $Id$
module Yast
  class FirstbootWriteClient < Client
    def main
      textdomain "firstboot"
      Yast.import "Directory"
      Yast.import "FileUtils"
      Yast.import "Firstboot"
      Yast.import "GetInstArgs"
      Yast.import "Keyboard"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "Progress"
      Yast.import "ProductFeatures"
      Yast.import "Wizard"

      return :back if GetInstArgs.going_back

      @progress_stages = [
        # progress stages
        _("Update configuration"),
        # progress stages
        _("Prepare system for first login")
      ]

      @progress_descriptions = [
        # progress stages
        _("Updating configuration..."),
        # progress stages
        _("Preparing system for first login...")
      ]


      # Help text for last dialog of base installation
      @help_text = _(
        "<p>\n" +
          "Please wait while the system is being configured.\n" +
          "</p>"
      )


      Progress.on

      Progress.New(
        # Headline for last dialog of first boot workflow
        _("Completing the System Configuration"),
        "", # Initial progress bar label - not empty (reserve space!)
        2, # progress bar length
        @progress_stages,
        @progress_descriptions,
        @help_text
      )


      Wizard.EnableNextButton
      Wizard.EnableBackButton
      Progress.NextStage


      # Desktop settings
      @default_dm = "kdm"
      gnome_window_managers = ["gnome", "sle-classic", "gnome-classic"]
      @default_dm = "gdm" if gnome_window_managers.include?(Firstboot.default_wm)
      if @default_dm == "kdm" && Package.Installed("kdm") ||
          @default_dm == "gdm" && Package.Installed("gdm")
        SCR.Write(path(".sysconfig.displaymanager.DISPLAYMANAGER"), @default_dm)
      end
      SCR.Write(
        path(".sysconfig.windowmanager.DEFAULT_WM"),
        Firstboot.default_wm
      )

      # save product features if they do not exist
      if !FileUtils.Exists("/etc/YaST2/ProductFeatures")
        Builtins.y2milestone("Saving ProductFeatures...")
        SCR.Execute(path(".target.bash"), "/bin/mkdir -p '/etc/YaST2'")
        SCR.Execute(path(".target.bash"), "/usr/bin/touch '/etc/YaST2/ProductFeatures'")
        ProductFeatures.Save
      end

      Builtins.sleep(100)
      Progress.NextStage

      Firstboot.ExecuteScripts
      Builtins.sleep(100)
      Progress.Finish

      :next 

      #EOF
    end
  end
end

Yast::FirstbootWriteClient.new.main
