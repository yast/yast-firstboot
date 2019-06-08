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
# Module:             firstboot_timezone.ycp
#
# Author:             Klaus Kaempf (kkaempf@suse.de)
#
# Submodules:
#
#
# Purpose:	configure timezone in running system
#
# Modify:
#
#
# $Id$
module Yast
  class FirstbootTimezoneClient < Client
    def main
      textdomain "firstboot"

      Yast.import "Timezone"
      Yast.import "Wizard"
      Yast.import "Firstboot"

      Yast.import "Popup"
      Yast.import "Label"
      Yast.import "GetInstArgs"

      # Memorize the current timezone.
      #
      @timezone_on_entry = Timezone.timezone
      @hwclock_on_entry = Timezone.hwclock

      Wizard.SetDesktopIcon("org.opensuse.yast.Timezone")

      #------------------------------------------------------------

      @result = nil

      @result = WFM.CallFunction("inst_timezone", [GetInstArgs.argmap])

      if @result == :next
        # User accepted the setting.
        # Only if the user has chosen a different timezone change the configuration.
        #
        if @timezone_on_entry != Timezone.timezone ||
            @hwclock_on_entry != Timezone.hwclock
          Builtins.y2milestone(
            "User selected new timezone/clock setting: <%1> <%2>",
            Timezone.timezone,
            Timezone.hwclock
          )
          # Save changes...
          Timezone.Save
        else
          Builtins.y2milestone("Timezone not changed --> doing nothing")
        end #  `back
      else
        Builtins.y2milestone("User cancelled --> no change")
      end

      deep_copy(@result)
    end
  end
end

Yast::FirstbootTimezoneClient.new.main
